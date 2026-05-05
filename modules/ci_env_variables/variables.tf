variable "gitlab_projects" {
  type        = any
  description = "Same normalized shape as the root module variable gitlab_projects, including resolved namespace behavior and project-level env_variables."
}

variable "global_env_variables" {
  type        = any
  description = "Same shape as the root module variable global_env_variables; project-level env_variables replace the full definition for matching keys."
}

variable "project_ids" {
  type        = map(number)
  description = "Map of project name to GitLab project ID (from modules/project)."
}
