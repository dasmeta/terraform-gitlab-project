output "gitlab_project_ids" {
  description = "Map of GitLab project name to project ID"
  value       = { for k, p in gitlab_project.this : k => p.id }
}
