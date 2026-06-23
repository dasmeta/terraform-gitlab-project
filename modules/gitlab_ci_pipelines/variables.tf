variable "gitlab_projects" {
  type        = any
  description = "Same normalized shape as the root module variable gitlab_projects, including gitlab_ci_pipelines entries."
}

variable "project_ids" {
  type        = map(number)
  description = "Map of project name to GitLab project ID (from modules/project)."
}
