output "gitlab_project_ids" {
  description = "Map of GitLab project name to project ID"
  value       = module.project.project_ids
}

output "gitlab_group_ids" {
  description = "Map of group key (from gitlab_groups / legacy default key) to namespace id — use this for every group instead of a separate 'first group' id."
  value       = local.namespace_by_key
}

output "gitlab_group_full_paths" {
  description = "Map of group key to full_path for groups created by this module (keys match Terraform-managed groups only; existing_namespace_id-only groups are omitted)."
  value       = { for k, m in module.gitlab_group : k => m.full_path }
}
