variable "projects_enabled" {
  type        = bool                                                                                                                                                                             # Whether project resources (repos, CI vars, etc.) are created
  default     = true                                                                                                                                                                             # When false, only groups run; project submodule is a no-op
  description = "When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab_groups[].create is true." # registry / docs
}

variable "gitlab_groups" {
  type = list(object({
    key               = string                      # Stable id for wiring group_key on projects
    create            = optional(bool, false)       # Create group via API for this entry
    name              = optional(string)            # Display name (required if create is true)
    path              = optional(string)            # URL path (required if create is true)
    description       = optional(string, "")        # Group description
    visibility_level  = optional(string, "private") # private | internal | public
    parent_id         = optional(number)            # Parent namespace id for subgroups
    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true
  }))
  default     = []
  description = <<-EOT
    GitLab groups for this module (each entry needs a unique "key"). Each entry must be one of two supported modes:
    - managed group: set create = true and provide name + path
    - existing group reference: set create = false and provide existing_group_id

    Projects may resolve their namespace through group_key, or by the implicit single-group fallback when exactly one
    gitlab_groups entry exists. If this list is empty, every gitlab_projects item must set namespace_id directly.
  EOT

  validation {
    condition     = length(var.gitlab_groups) == 0 || length(distinct([for g in var.gitlab_groups : g.key])) == length(var.gitlab_groups) # Unique keys
    error_message = "gitlab_groups: each entry must have a unique \"key\"."                                                               # Shown when keys collide
  }

  validation {
    condition = alltrue([
      for g in var.gitlab_groups :
      !g.create || (try(g.name, null) != null && try(g.path, null) != null)
    ])
    error_message = "When gitlab_groups[].create is true, name and path are required."
  }

  validation {
    condition = alltrue([
      for g in var.gitlab_groups :
      g.create || try(g.existing_group_id, null) != null
    ])
    error_message = "When gitlab_groups[].create is false, existing_group_id is required."
  }
}

# -----------------------------------------------------------------------------
# Global settings applied to all projects (e.g. shared CI tokens)
# -----------------------------------------------------------------------------

variable "global_env_variables" {
  type = list(object({
    key       = string                # CI/CD variable name
    value     = string                # Variable value (use masked for secrets)
    masked    = optional(bool, false) # Hide value in job logs / UI where supported
    protected = optional(bool, false) # Available only on protected branches/tags
  }))
  default     = []
  description = "Environment variables applied to every GitLab project. Use for shared NPM_TOKEN, GITLAB_TOKEN, etc."
}

variable "gitlab_projects" {
  type = list(object({
    name                                             = string                         # Project name / slug key used by child resources
    description                                      = optional(string)               # Project description
    visibility_level                                 = optional(string, "private")    # private | internal | public
    default_branch                                   = optional(string, "develop")    # Initial default branch name
    initialize_with_readme                           = optional(bool, true)           # Create repository with README
    request_access_enabled                           = optional(bool, true)           # Allow users to request access
    prevent_destroy                                  = optional(bool, true)           # Contract hint only; not mapped to Terraform lifecycle
    namespace_id                                     = optional(number)               # Explicit GitLab namespace id for the project
    group_key                                        = optional(string)               # Resolve namespace through gitlab_groups[].key
    lfs_enabled                                      = optional(bool, true)           # Enable Git LFS for the project
    packages_enabled                                 = optional(bool, true)           # Enable GitLab package registry
    squash_option                                    = optional(string, "default_on") # never | default_off | default_on | always
    merge_method                                     = optional(string, "merge")      # merge | rebase_merge | ff
    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)           # Require successful pipeline before merge
    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)           # Require resolved discussions before merge
    remove_source_branch_after_merge                 = optional(bool, true)           # Auto-delete source branch after merge
    ci_pipeline_variables_minimum_override_role      = optional(string, "developer")  # no_one_allowed | developer | maintainer | owner
    pages_access_level                               = optional(string, "private")    # GitLab Pages visibility level
    suggestion_commit_message                        = optional(string)               # Suggested squash commit message template
    merge_commit_template                            = optional(string)               # Merge commit message template
    squash_commit_template                           = optional(string)               # Squash commit message template
    approvals_before_merge                           = optional(number)               # Deprecated provider field retained for importing existing projects without drift
    resolve_outdated_diff_discussions                = optional(bool)                 # Automatically resolve outdated diff discussions
    branch_protections_enabled                       = optional(bool, true)           # Create branch protection resources for this project
    branch_protections = optional(list(object({
      branch                       = string                         # Protected branch name
      merge_access_level           = optional(string, "maintainer") # Merge access role
      push_access_level            = optional(string, "maintainer") # Push access role
      allow_force_push             = optional(bool, false)          # Allow force-push on the branch
      code_owner_approval_required = optional(bool, false)          # Require code-owner approval
      unprotect_access_level       = optional(string, "maintainer") # Unprotect access role
    })), [])
    approval_rule = optional(list(object({
      name                              = optional(string, "Approval rule") # Approval rule display name
      approvals_required                = optional(number, 1)               # Number of approvals required
      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches
      user_ids                          = optional(list(number))            # Explicit approver user ids
      group_ids                         = optional(list(number))            # Explicit approver group ids
    })), [])
    push_rules = optional(list(any), []) # Provider-shaped push rules consumed by gitlab_project.push_rules
    env_variables = optional(list(object({
      key       = string                # CI/CD variable name
      value     = string                # CI/CD variable value
      masked    = optional(bool, false) # Hide value in logs / UI where supported
      protected = optional(bool, false) # Restrict variable to protected refs
    })), [])
  }))
  description = <<-EOT
    List of GitLab project configurations.

    Supported namespace selection paths:
    - set namespace_id directly
    - set group_key to select an entry from var.gitlab_groups
    - omit both namespace_id and group_key only when exactly one gitlab_groups entry exists; that single group is used implicitly

    Do not set namespace_id and group_key together on the same project.
    When gitlab_groups is empty, set namespace_id on every project.

    Merge behavior (per project; GitLab UI under Settings → Merge requests):

    squash_option — Squash commits when merging:
      - never        → Do not allow (squash disabled; checkbox hidden)
      - default_off  → Allow (checkbox visible, off by default)
      - default_on   → Encourage (checkbox visible, on by default)
      - always       → Require (always squash; user cannot disable)

    merge_method — Merge method:
      - merge        → Create a merge commit
      - rebase_merge → Merge commit with semi-linear history
      - ff           → Fast-forward merge

    branch_protections — Optional list per project: Settings → Repository → Protected branches.
    When omitted or set to [], this module creates one default protection for branch "main".
    Access is only via merge_access_level / push_access_level (maintainer, developer, admin, no one).
    Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab_branch_protection.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    When omitted or set to [], no project approval rule resources are created.
    Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    ci_pipeline_variables_minimum_override_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).
    Valid values: no_one_allowed, developer, maintainer, owner. Default in type: maintainer.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    If present and non-empty, the module creates one GitLab approval rule resource
    per list entry. Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project replaces the full global variable definition for that project.
  EOT
  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      contains(["no_one_allowed", "developer", "maintainer", "owner"], p.ci_pipeline_variables_minimum_override_role)
    ])
    error_message = "gitlab_projects[].ci_pipeline_variables_minimum_override_role must be one of: no_one_allowed, developer, maintainer, owner."
  }

  validation {
    condition = length(var.gitlab_projects) == 0 || length(var.gitlab_groups) > 0 || alltrue([
      for p in var.gitlab_projects : try(p.namespace_id, null) != null
    ])
    error_message = "When gitlab_groups is empty, set namespace_id on every gitlab_projects entry."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      !(try(p.namespace_id, null) != null && try(p.group_key, null) != null)
    ])
    error_message = "Set either namespace_id or group_key for a project, but not both."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.group_key, null) == null || contains([for g in var.gitlab_groups : g.key], coalesce(try(p.group_key, null), "__UNRESOLVED_GROUP_KEY__"))
    ])
    error_message = "gitlab_projects[].group_key must match a declared gitlab_groups[].key."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.namespace_id, null) != null ? true : (
        length(var.gitlab_groups) == 0 ? false : length([
          for g in var.gitlab_groups : g.key
          if g.key == coalesce(
            try(p.group_key, null),
            length(var.gitlab_groups) == 1 ? var.gitlab_groups[0].key : "__UNRESOLVED_GROUP_KEY__"
          ) && (g.create || try(g.existing_group_id, null) != null)
        ]) == 1
      )
    ])
    error_message = "Each project must resolve deterministically through namespace_id, a valid group_key, or the implicit single-group fallback backed by a creatable or existing group id."
  }
}
