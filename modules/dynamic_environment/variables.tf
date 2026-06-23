variable "projects_enabled" {
  type        = bool
  description = "When false, dynamic environment project and service resources are skipped."
}

variable "gitlab_projects" {
  type        = any
  description = "Normalized GitLab project objects from the root module."
}

variable "project_ids" {
  type        = map(string)
  description = "Map of service project names to GitLab project IDs from the project submodule."
}

variable "dynamic_environments_project" {
  type        = any
  description = "Normalized central dynamic environments project configuration from the root module."
}

variable "gitlab_agent_path" {
  type        = string
  default     = ""
  description = "Effective GitLab Agent context path referenced by generated dynamic environment CI."
}

locals {
  dynamic_environment_service_enabled = anytrue([
    for p in var.gitlab_projects : try(p.dynamic_environment.enabled, false)
  ])
}

check "dynamic_environment_central_project_required" {
  assert {
    condition     = !local.dynamic_environment_service_enabled || try(var.dynamic_environments_project.enabled, false)
    error_message = "dynamic_environments_project.enabled must be true when any gitlab_projects[].dynamic_environment.enabled is true."
  }
}
