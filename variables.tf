variable "create" {
  type        = bool
  description = "Boolean to create the resource. Defaults to true."
  default     = true
}

variable "create_variable" {
  type        = bool
  description = "Boolean to create the resource variable. Defaults to true."
  default     = false
}

variable "create_webhook" {
  type        = bool
  description = "Boolean to create the webhook. Defaults to true."
  default     = false
}

variable "create_pipline" {
  type        = bool
  description = "Boolean to create the pipline. Defaults to true."
  default     = false
}


variable "name" {
  type        = string
  description = "The name of the project to be created"

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.name))
    error_message = "Projects must be named in lowercase, using a-z, 0-9, and - (hyphen) symbols only."
  }
}


variable "description" {
  type        = string
  description = "(Optional) A description of the project."
  default     = "Repository for testing"
}

variable "project_variable_key" {
  description = "(String) The name of the variable."
  type        = string
  default     = null
}

variable "project_variable_value" {
  description = "(String, Sensitive) The value of the variable."
  type        = string
  default     = null
}

variable "masked" {
  description = "(Boolean) If set to true, the value of the variable will be hidden in job logs. The value must meet the masking requirements. Defaults to false."
  type        = bool
  default     = false
}

variable "protected" {
  description = "(Boolean) If set to true, the variable will be passed only to pipelines running on protected branches and tags. Defaults to false."
  type        = bool
  default     = false
}

variable "url" {
  description = "(String) The url of the hook to invoke."
  type        = string
  default     = null
}

variable "confidential_issues_events" {
  description = "(Boolean) Invoke the hook for confidential issues events."
  type        = bool
  default     = false
}

variable "confidential_note_events" {
  description = "(Boolean) Invoke the hook for confidential notes events."
  type        = bool
  default     = false
}

variable "deployment_events" {
  description = "(Boolean) Invoke the hook for deployment events."
  type        = bool
  default     = false
}

variable "enable_ssl_verification" {
  description = "(Boolean) Enable ssl verification when invoking the hook."
  type        = bool
  default     = false
}

variable "issues_events" {
  description = "(Boolean) Invoke the hook for issues events."
  type        = bool
  default     = false
}

variable "job_events" {
  description = "(Boolean) Invoke the hook for job events."
  type        = bool
  default     = false
}

variable "merge_requests_events" {
  description = "(Boolean) Invoke the hook for merge requests."
  type        = bool
  default     = false
}

variable "pipeline_events" {
  description = "(Boolean) Invoke the hook for pipeline events."
  type        = bool
  default     = false
}

variable "push_events" {
  description = "(Boolean) Invoke the hook for push events."
  type        = bool
  default     = false
}

variable "push_events_branch_filter" {
  description = "(String) Invoke the hook for push events on matching branches only."
  type        = bool
  default     = false
}

variable "releases_events" {
  description = "(Boolean) Invoke the hook for releases events."
  type        = bool
  default     = false
}

variable "tag_push_events" {
  description = "(Boolean) Invoke the hook for tag push events."
  type        = bool
  default     = false
}

variable "token" {
  description = "(String, Sensitive) A token to present when invoking the hook. The token is not available for imported resources."
  type        = bool
  default     = false
}

variable "ref" {
  description = "(String) The branch/tag name to be triggered."
  type        = string
  default     = "main"
}

variable "cron" {
  description = "(String) The cron (e.g. 0 1 * * *)."
  type        = string
  default     = "0 1 * * *"
}

variable "active" {
  description = "(Boolean) The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially."
  type        = bool
  default     = false
}

variable "pipline_schedule_key" {
  description = "(String) Name of the variable."
  type        = string
  default     = null
}

variable "pipline_schedule_value" {
  description = "(String) Value of the variable."
  type        = string
  default     = null
}

variable "pipline_trigger_description" {
  description = "(String) The description of the pipeline trigger."
  type        = string
  default     = ""
}

variable "branch_name" {
  description = "(String) The name for this branch."
  type        = string
  default     = "develop"
}

variable "merge_access_level" {
  description = "(String) Access levels allowed to merge. Valid values are: no one, developer, maintainer."
  type        = string
  default     = "maintainer"
}

variable "push_access_level" {
  description = "(String) Access levels allowed to push. Valid values are: no one, developer, maintainer."
  type        = string
  default     = "maintainer"
}

variable "approval_rule" {
  description = "Merge request approval rule configuration"
  type = object({
    enabled                           = bool
    name                              = optional(string)
    approvals_required                = optional(number)
    applies_to_all_protected_branches = optional(bool)
    user_ids                          = optional(list(number))
    group_ids                         = optional(list(number))
  })
  default = {
    enabled = false
  }
}

variable "branch_protection" {
  description = "Branch protection configuration"
  type = object({
    enabled                      = bool
    branch                       = optional(string)
    allow_force_push             = optional(bool)
    push_access_level            = optional(string)
    merge_access_level           = optional(string)
    code_owner_approval_required = optional(bool)
  })
  default = {
    enabled = false
  }
}

variable "projects_enabled" {
  type    = bool
  default = true
}

# -----------------------------------------------------------------------------
# Global settings applied to all projects (e.g. 30 repos with same CI and env)
# -----------------------------------------------------------------------------

variable "global_env_variables" {
  description = "Environment variables applied to every GitLab project. Use for shared NPM_TOKEN, GITLAB_TOKEN, etc."
  type = list(object({
    key       = string
    value     = string
    masked    = optional(bool, false)
    protected = optional(bool, false)
  }))
  default = []
}

variable "global_repository_files" {
  description = "Repository files applied to every project. Use content_file to load from disk (e.g. .gitlab-ci.yml, .releaserc.json). Path is typically path.module from the caller."
  type = list(object({
    file_path      = string
    content_file   = optional(string) # path to file, e.g. \"${path.module}/templates/.gitlab-ci.yml\"
    content        = optional(string) # inline content; one of content_file or content required
    branch         = optional(string, "main")
    commit_message = optional(string, "Managed by Terraform")
    author_name    = optional(string)
    author_email   = optional(string)
  }))
  default = []
}

variable "gitlab_projects" {
  description = "List of GitLab project configurations"
  type = list(object({
    name        = string
    description = optional(string)

    visibility_level       = optional(string, "private")
    default_branch         = optional(string, "main")
    initialize_with_readme = optional(bool, false)
    request_access_enabled = optional(bool, true)
    prevent_destroy        = optional(bool, true)
    lfs_enabled            = optional(bool, false)
    packages_enabled       = optional(bool, false)

    # Merge behavior
    squash_option = optional(string, "default_on") # always | default_on | never
    merge_method  = optional(string, "ff")         # merge | rebase_merge | ff

    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)
    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)
    remove_source_branch_after_merge                 = optional(bool, true)

    pages_access_level = optional(string, "private")

    suggestion_commit_message = optional(string)
    merge_commit_template     = optional(string)

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

    # Repository files to manage (e.g. .releaserc, .gitlab-ci.yml). Use content_file to load from disk.
    repository_files = optional(list(object({
      file_path      = string
      content_file   = optional(string) # path to file from caller, e.g. path.module/templates/file
      content        = optional(string) # inline content; one of content_file or content
      branch         = optional(string, "main")
      commit_message = optional(string, "Managed by Terraform")
      author_name    = optional(string)
      author_email   = optional(string)
    })), [])
  }))
}
