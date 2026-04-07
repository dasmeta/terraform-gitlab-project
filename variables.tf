variable "create" {
  type        = bool
  default     = true
  description = "When false, no GitLab projects or child resources are created (projects_enabled is treated as false for project-related locals)."
}

variable "projects_enabled" {
  type        = bool
  default     = true
  description = "When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). Takes effect with var.create as create && projects_enabled in module locals; group namespaces may still be created when create is true."
}

variable "gitlab_group" {
  type = object({
    create                = optional(bool, false)
    name                  = optional(string)
    path                  = optional(string)
    description           = optional(string, "")
    visibility_level      = optional(string, "private")
    parent_id             = optional(number)
    existing_namespace_id = optional(number)
  })
  default = {
    create = false
  }
  description = <<-EOT
    Legacy single-group interface. Ignored when var.gitlab_groups is non-empty.
    When create is true (and var.create is true), creates one GitLab group; its id is the default namespace
    for gitlab_projects entries that omit namespace_id and group_key. Explicit namespace_id on a project always wins.
  EOT

  validation {
    condition = (
      !var.gitlab_group.create ||
      (try(var.gitlab_group.name, null) != null && try(var.gitlab_group.path, null) != null)
    )
    error_message = "When gitlab_group.create is true, name and path are required."
  }
}

variable "gitlab_groups" {
  type = list(object({
    key                   = string
    create                = optional(bool, false)
    name                  = optional(string)
    path                  = optional(string)
    description           = optional(string, "")
    visibility_level      = optional(string, "private")
    parent_id             = optional(number)
    existing_namespace_id = optional(number)
  }))
  default     = []
  description = <<-EOT
    Multiple GitLab groups. When this list is non-empty, it replaces the legacy var.gitlab_group single-object
    wiring (each entry needs a unique "key"). Set group_key on each gitlab_projects item to choose a group,
    or set namespace_id. With more than one entry here, every project must set group_key or namespace_id.
    For create = false, set existing_namespace_id to use a pre-existing group's id as that key's namespace.
  EOT

  validation {
    condition     = length(var.gitlab_groups) == 0 || length(distinct([for g in var.gitlab_groups : g.key])) == length(var.gitlab_groups)
    error_message = "gitlab_groups: each entry must have a unique \"key\"."
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
    key       = string
    value     = string
    masked    = optional(bool, false)
    protected = optional(bool, false)
  }))
  default     = []
  description = "Environment variables applied to every GitLab project. Use for shared NPM_TOKEN, GITLAB_TOKEN, etc."
}

variable "gitlab_projects" {
  type = list(object({
    name        = string
    description = optional(string)

    visibility_level       = optional(string, "private")
    default_branch         = optional(string, "main")
    initialize_with_readme = optional(bool, false)
    request_access_enabled = optional(bool, true)
    prevent_destroy        = optional(bool, true)
    namespace_id           = optional(number)
    group_key              = optional(string)
    lfs_enabled            = optional(bool, true)
    packages_enabled       = optional(bool, false)

    # Merge behavior — full UI mapping in this variable's description above
    squash_option = optional(string, "default_off")
    merge_method  = optional(string, "rebase_merge")

    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)
    only_allow_merge_if_all_discussions_are_resolved = optional(bool, false)
    remove_source_branch_after_merge                 = optional(bool, true)

    pages_access_level = optional(string, "private")

    suggestion_commit_message = optional(string)
    merge_commit_template     = optional(string)

    branch_protections = optional(list(object({
      branch                       = string
      merge_access_level           = optional(string)
      push_access_level            = optional(string)
      allow_force_push             = optional(bool)
      code_owner_approval_required = optional(bool)
      unprotect_access_level       = optional(string)
    })), [])

    approval_rule = optional(object({
      enabled                           = bool
      name                              = optional(string)
      approvals_required                = optional(number)
      applies_to_all_protected_branches = optional(bool)
      user_ids                          = optional(list(number))
      group_ids                         = optional(list(number))
    }))

    # Push rules (all optional)
    push_rules = optional(list(object({
      author_email_regex            = optional(string)
      branch_name_regex             = optional(string)
      commit_committer_check        = optional(bool, false)
      commit_message_negative_regex = optional(string)
      commit_message_regex          = optional(string)
      deny_delete_tag               = optional(bool, false)
      file_name_regex               = optional(string)
      max_file_size                 = optional(number)
      member_check                  = optional(bool, false)
      prevent_secrets               = optional(bool, false)
      reject_unsigned_commits       = optional(bool, false)
    })), [])

    # Project-level environment variables
    env_variables = optional(list(object({
      key       = string
      value     = string
      masked    = optional(bool, false)
      protected = optional(bool, false)
    })), [])
  }))
  description = <<-EOT
    List of GitLab project configurations. Use group_key to select a namespace from var.gitlab_groups (must match an entry's key).
    With multiple gitlab_groups, set group_key or namespace_id on every project. Omitting group_key uses the first group in the list.

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

    approval_rule — Optional per project: one gitlab_project_approval_rule when enabled = true (MR approvals).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project overrides the global value.
  EOT
}
