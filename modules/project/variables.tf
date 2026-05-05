variable "projects_enabled" {
  type        = bool
  description = "When true, create one GitLab project per entry in gitlab_projects."
}

variable "gitlab_projects" {
  description = <<-EOT
    Same structure as the root module input `gitlab_projects` (see root `variables.tf`).
    Validated and normalized at the root module; namespace resolution and
    ambiguous input rejection happen before this submodule consumes the objects.
    This submodule uses `any` to avoid duplicating the full object type.
  EOT
  type        = any
}
