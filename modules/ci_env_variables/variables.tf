variable "gitlab_projects" {
  type        = any
  description = "Same shape as the root module variable gitlab_projects."
}

variable "global_env_variables" {
  type        = any
  description = "Same shape as the root module variable global_env_variables."
}

variable "project_ids" {
  type        = map(number)
  description = "Map of project name to GitLab project ID (from modules/project)."
}
