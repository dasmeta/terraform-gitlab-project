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
  type = any
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
    When omitted or set to [], this module creates one default protection for branch "main".
    Access is only via merge_access_level / push_access_level (maintainer, developer, admin, no one).
    Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab_branch_protection.

    approval_rule — Optional per project. Accepts either one approval rule object or a list of approval rule objects.
    Disabled entries are ignored. Defaults are enabled = false, name = "Approval rule",
    approvals_required = 1, applies_to_all_protected_branches = false;
    enable the resource with enabled = true (user_ids / group_ids optional; omit for GitLab default approvers).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    ci_pipeline_variables_minimum_override_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).
    Valid values: no_one_allowed, developer, maintainer, owner. Default in type: maintainer.

    approval_rule — Optional per project. Accepts either one approval rule object or a list of approval rule objects.
    If present, the module creates the rule or rules. Defaults are name = "Approval rule",
    approvals_required = 1, applies_to_all_protected_branches = false
    (user_ids / group_ids optional; omit for GitLab default approvers).

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project overrides the global value.
  EOT

  validation {
    condition     = can([for p in var.gitlab_projects : p.name])
    error_message = "gitlab_projects must be a list of project objects."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      contains(["no_one_allowed", "developer", "maintainer", "owner"], coalesce(try(p.ci_pipeline_variables_minimum_override_role, null), "developer"))
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
    condition = length(var.gitlab_groups) <= 1 || alltrue([
      for p in var.gitlab_projects :
      try(p.namespace_id, null) != null || try(p.group_key, null) != null
    ])
    error_message = "With multiple gitlab_groups entries, each gitlab_projects item must set namespace_id or group_key."
  }
}
