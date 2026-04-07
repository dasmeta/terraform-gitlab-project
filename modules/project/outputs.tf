output "project_ids" {
  description = "Map of GitLab project name (config key) to numeric project ID."
  value       = { for k, p in gitlab_project.this : k => p.id }
}

output "path_with_namespace" {
  description = "Map of project name to path_with_namespace (e.g. group/repo)."
  value       = { for k, p in gitlab_project.this : k => p.path_with_namespace }
}

output "web_url" {
  description = "Map of project name to GitLab UI URL."
  value       = { for k, p in gitlab_project.this : k => p.web_url }
}

output "http_url_to_repo" {
  description = "Map of project name to HTTP clone URL."
  value       = { for k, p in gitlab_project.this : k => p.http_url_to_repo }
}

output "ssh_url_to_repo" {
  description = "Map of project name to SSH clone URL."
  value       = { for k, p in gitlab_project.this : k => p.ssh_url_to_repo }
}
