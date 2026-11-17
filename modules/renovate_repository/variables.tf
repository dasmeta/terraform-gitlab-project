variable "gitlab_projects" {
  type = list(object({
    name           = string
    default_branch = optional(string, "main")
    renovate = optional(object({
      enabled             = optional(bool, false)
      source_branch       = optional(string, "terraform/renovate")
      merge_request_title = optional(string, "chore: configure Renovate")
      extends             = optional(list(string), ["config:recommended"])
      include_paths       = optional(list(string), [])
      ignore_paths        = optional(list(string), [])
      custom_managers = optional(list(object({
        custom_type           = optional(string, "regex")
        manager_file_patterns = list(string)
        match_strings         = list(string)
        file_format           = optional(string)
        datasource_template   = optional(string)
        dep_name_template     = optional(string)
        package_name_template = optional(string)
        versioning_template   = optional(string)
        registry_url_template = optional(string)
      })), [])
    }), {})
  }))
  default     = []
  description = "Projects whose Renovate configuration should be proposed through merge requests."
  validation {
    condition = alltrue([for project in var.gitlab_projects : !project.renovate.enabled || (
      trimspace(project.renovate.source_branch) != "" && project.renovate.source_branch != project.default_branch && trimspace(project.renovate.merge_request_title) != ""
    )])
    error_message = "Enabled projects require a nonempty MR title and a source branch different from the default branch."
  }
  validation {
    condition = alltrue(flatten([for project in var.gitlab_projects : [for manager in project.renovate.custom_managers :
      contains(["regex", "jsonata"], manager.custom_type) && length(manager.manager_file_patterns) > 0 && length(manager.match_strings) > 0 && (manager.custom_type != "jsonata" || contains(["yaml", "json", "toml"], (manager.file_format == null ? "" : manager.file_format)))
    ]]))
    error_message = "Custom managers require regex/jsonata, nonempty file patterns/matches, and a file_format for JSONata."
  }
}

variable "project_ids" {
  type        = map(string)
  default     = {}
  description = "Managed project IDs indexed by gitlab_projects[].name."
}

variable "endpoint" {
  type        = string
  default     = "https://gitlab.com/api/v4"
  description = "GitLab API endpoint for configuration merge requests."
}
