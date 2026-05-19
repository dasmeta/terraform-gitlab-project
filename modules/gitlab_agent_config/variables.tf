variable "enabled" {
  type        = bool
  default     = false
  description = "When true, generates GitLab Agent config in the configured repository."
}

variable "gitlab_agent" {
  type        = any
  default     = {}
  description = "GitLab Agent config generation settings from dynamic_environments_project.gitlab_agent."
}

variable "gitlab_api_url" {
  type        = string
  default     = "https://gitlab.com/api/v4"
  description = "GitLab API URL used by the merge request local-exec helper."
}

variable "cluster_name" {
  type        = string
  default     = "eks-dev"
  description = "Cluster name used as the default GitLab Agent name."
}

variable "project_ids" {
  type        = map(string)
  default     = {}
  description = "Map of managed project names to GitLab project IDs."
}

variable "project_paths" {
  type        = map(string)
  default     = {}
  description = "Map of managed project names to GitLab path_with_namespace values."
}

variable "central_project_id" {
  type        = string
  default     = null
  description = "GitLab project ID for the generated central dynamic environments project."
}

variable "central_project_path" {
  type        = string
  default     = null
  description = "Path with namespace for the generated central dynamic environments project."
}

variable "service_project_paths" {
  type        = list(string)
  default     = []
  description = "Enabled service project paths that should receive default GitLab Agent CI access."
}
