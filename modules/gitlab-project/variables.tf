variable "create" {
  type        = bool
  description = "Boolean to create the resource. Defaults to true."
  default     = true
}

variable "create_variable" {
  type        = bool
  description = "Boolean to create the resource variable. Defaults to true."
  default     = true
}

variable "create_webhook" {
  type        = bool
  description = "Boolean to create the webhook. Defaults to true."
  default     = true
}

variable "create_pipline" {
  type        = bool
  description = "Boolean to create the pipline. Defaults to true."
  default     = true
}

variable "create_branch" {
  type        = bool
  description = "Boolean to create the branch. Defaults to true."
  default     = true
}

variable "name" {
  type        = string
  description = "The name of the project to be created"

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.name))
    error_message = "Projects must be named in lowercase, using a-z, 0-9, and - (hyphen) symbols only."
  }
}

variable "approvals_before_merge" {
  type        = string
  description = "(Optional) Number of merge request approvals required for merging. Default is 0."
  default     = 1
}

variable "default_branch" {
  type        = string
  description = "(Optional) The default branch the repository will use. Defaults to main."
  default     = "main"
}

variable "description" {
  type        = string
  description = "(Optional) A description of the project."
  default     = "Repository for testing"
}

variable "initialize_with_readme" {
  type        = bool
  description = "(Optional) Create main branch with first commit containing a README.md file."
  default     = false
}

variable "lfs_enabled" {
  type        = bool
  description = "(Optional) Enable LFS for the project."
  default     = false
}

variable "merge_method" {
  type        = string
  description = "(Optional) Set to `ff` to create fast-forward merges. Valid values are `merge`, `rebase_merge`, `ff`."
  default     = "ff"
}

variable "only_allow_merge_if_all_discussions_are_resolved" {
  type        = bool
  description = "(Optional) Set to true if you want to allow merges only if all discussions are resolved."
  default     = true
}

variable "only_allow_merge_if_pipeline_succeeds" {
  type        = bool
  description = "(Optional) Set to true if you want to allow merges only if a pipeline succeeds."
  default     = true
}

variable "packages_enabled" {
  type        = bool
  description = "(Optional) Enable packages repository for the project."
  default     = false
}

variable "pages_access_level" {
  type        = string
  description = "(Optional) Enable pages access control. Valid values are `disabled`, `private`, `enabled`, `public`."
  default     = "private"
}

variable "remove_source_branch_after_merge" {
  type        = bool
  description = "(Optional) Enable `Delete source branch` option by default for all new merge requests."
  default     = true
}

variable "request_access_enabled" {
  type        = bool
  description = "(Optional) Allow users to request member access."
  default     = true
}

variable "snippets_enabled" {
  type        = bool
  description = "(Optional) Enable snippets for the project."
  default     = false
}

variable "visibility_level" {
  type        = string
  description = "(Optional) Set to `public` to create a public project. Valid values are `private`, `internal`, `public`."
  default     = "private"
}

variable "wiki_enabled" {
  type        = bool
  description = "(Optional) Enable wiki for the project."
  default     = false
}

variable "push_rules" {
  description = "An array containing the push rules object."
  type        = list(object({}))
  default = [{
    commit_committer_check = true
    prevent_secrets        = true
  }]
}

# variable "gitlab_token" {
#   description = "An Personal Access Token."
#   type        = string
#   default     = ""
# }

# variable "username" {
#   description = "A username of you account."
#   type        = string
#   default     = "0katrinpetrosyan0"
# }

variable "project_variable_key" {
  description = "(String) The name of the variable."
  type        = string
  default     = "project_variable_key"
}

variable "project_variable_value" {
  description = "(String, Sensitive) The value of the variable."
  type        = string
  default     = "project_variable_value"
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
  default     = "https://gitlab.com/dashboard/projects"
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
  default     = "EXAMPLE_KEY"
}

variable "pipline_schedule_value" {
  description = "(String) Value of the variable."
  type        = string
  default     = "EXAMPLE_VALUE"
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
