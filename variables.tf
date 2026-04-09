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
    GitLab groups for this module (each entry needs a unique "key"). Set group_key on each gitlab_projects item to choose a group,
    or set namespace_id on the project. With more than one entry here, every project must set group_key or namespace_id.
    For create = false, set existing_group_id to the GitLab group's id so projects with matching group_key resolve there.
    If this list is empty, every gitlab_projects item must set namespace_id.
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
    name        = string           # GitLab project name (Terraform map key / for_each)
    description = optional(string) # Project description; omit for none

    visibility_level       = optional(string, "private") # private, internal, or public
    default_branch         = optional(string, "develop") # Initial default branch name
    initialize_with_readme = optional(bool, false)       # Create empty README on create
    request_access_enabled = optional(bool, true)        # Allow users to request access
    prevent_destroy        = optional(bool, true)        # Hint for operators only (not Terraform lifecycle)
    namespace_id           = optional(number)            # Overrides group resolution when set
    group_key              = optional(string)            # Match gitlab_groups[].key; omit when a single group is defined (uses that entry)
    lfs_enabled            = optional(bool, true)        # Git LFS enabled
    packages_enabled       = optional(bool, false)       # GitLab package registry

    # Merge behavior — full UI mapping in this variable's description block below
    squash_option = optional(string, "default_off")  # never | default_off | default_on | always
    merge_method  = optional(string, "rebase_merge") # merge | rebase_merge | ff

    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)  # Block merge if latest pipeline failed
    only_allow_merge_if_all_discussions_are_resolved = optional(bool, false) # Block merge if open threads
    remove_source_branch_after_merge                 = optional(bool, true)  # Delete source branch after MR merge

    ci_pipeline_variables_minimum_override_role = optional(string, "maintainer") # Min role for pipeline variables (GitLab 17.1+)

    pages_access_level = optional(string, "private") # GitLab Pages: disabled, private, enabled, public

    suggestion_commit_message = optional(string) # Suggested squash commit message template
    merge_commit_template     = optional(string) # Merge commit message template

    branch_protections = optional(list(object({
      branch                       = string                         # Branch name or pattern to protect
      merge_access_level           = optional(string, "maintainer") # Who can merge into this branch
      push_access_level            = optional(string, "maintainer") # Who can push to this branch
      allow_force_push             = optional(bool, false)          # Allow force push
      code_owner_approval_required = optional(bool, false)          # Require CODEOWNERS approval when configured
      unprotect_access_level       = optional(string)               # Who may unprotect; omit for provider default
    })), [])                                                        # Empty = no branch protection rules from this module

    approval_rule = optional(object({
      enabled                           = optional(bool, false)             # Create gitlab_project_approval_rule when true
      name                              = optional(string, "Approval rule") # Rule name in GitLab
      approvals_required                = optional(number, 1)               # Required approval count before merge
      applies_to_all_protected_branches = optional(bool, false)             # Apply to every protected branch
      user_ids                          = optional(list(number))            # Approver user IDs; omit for GitLab defaults
      group_ids                         = optional(list(number))            # Approver group IDs
    }), null)                                                               # null = no approval_rule resource

    push_rules = optional(list(object({
      author_email_regex            = optional(string)      # Allowed author email pattern
      branch_name_regex             = optional(string)      # Allowed branch name pattern
      commit_committer_check        = optional(bool, false) # Require committer matches GitLab user
      commit_message_negative_regex = optional(string)      # Reject commits matching this pattern
      commit_message_regex          = optional(string)      # Require commit message to match
      deny_delete_tag               = optional(bool, false) # Block tag deletion
      file_name_regex               = optional(string)      # Block files matching this name pattern
      max_file_size                 = optional(number)      # Max file size (MB / provider units)
      member_check                  = optional(bool, false) # Restrict commits to project members
      prevent_secrets               = optional(bool, false) # Reject secrets (GitLab push rule)
      reject_unsigned_commits       = optional(bool, false) # Reject commits without verified signature
    })), [])                                                # Empty = no push_rules block on gitlab_project

    env_variables = optional(list(object({
      key       = string                # CI/CD variable name (overrides global_env_variables with same key)
      value     = string                # Variable value
      masked    = optional(bool, false) # Mask in logs where supported
      protected = optional(bool, false) # Only on protected branches/tags
    })), [])                            # Empty = only global_env_variables apply
  }))                                   # Each list element defines one GitLab project to create/manage
  # Long-form description for terraform-docs / consumers
  description = <<-EOT
    List of GitLab project configurations. Use group_key to select a namespace from var.gitlab_groups (must match an entry's key),
    or set namespace_id. If gitlab_groups is non-empty, omitting group_key uses the first entry. If gitlab_groups is empty,
    set namespace_id on every project.

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
    Access is only via merge_access_level / push_access_level (maintainer, developer, admin, no one).
    Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab_branch_protection.

    approval_rule — Optional per project. Omitted or enabled = false: no rule. When the object is set, defaults are
    enabled = false, name = "Approval rule", approvals_required = 1, applies_to_all_protected_branches = false;
    enable the resource with enabled = true (user_ids / group_ids optional; omit for GitLab default approvers).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    ci_pipeline_variables_minimum_override_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).
    Valid values: no_one_allowed, developer, maintainer, owner. Default in type: maintainer.

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project overrides the global value.
  EOT

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      contains(["no_one_allowed", "developer", "maintainer", "owner"], p.ci_pipeline_variables_minimum_override_role)
    ])
    error_message = "gitlab_projects[].ci_pipeline_variables_minimum_override_role must be one of: no_one_allowed, developer, maintainer, owner."
  }
}
