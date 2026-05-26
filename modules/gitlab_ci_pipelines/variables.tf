variable "projects_enabled" {
  type        = bool
  description = "When false, GitLab CI pipeline repository files and merge requests are skipped."
}

variable "gitlab_projects" {
  type        = any
  description = "Normalized GitLab project objects from the root module."
}

variable "project_ids" {
  type        = map(string)
  description = "Map of service project names to GitLab project IDs from the project submodule."
}

variable "gitlab_api_url" {
  type        = string
  default     = "https://gitlab.com/api/v4"
  description = "GitLab API URL used by local merge request creation."
}
