variable "projects_enabled" {
  type        = bool
  description = "When true, create one GitLab project per entry in gitlab_projects."
}

variable "gitlab_projects" {
  description = <<-EOT
    Same structure as the root module input `gitlab_projects` (see root `variables.tf`).
    Validated at the root module; this submodule uses `any` to avoid duplicating the full object type.
  EOT
  type        = any
}
