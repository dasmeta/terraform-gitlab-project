output "id" {
  description = "GitLab group id (namespace id), or null if not created."
  value       = length(gitlab_group.this) > 0 ? gitlab_group.this[0].id : null
}

output "full_path" {
  description = "Group full_path, or null if not created."
  value       = length(gitlab_group.this) > 0 ? gitlab_group.this[0].full_path : null
}
