output "agent_path" {
  description = "GitLab Agent context path in <config-project-path>:<agent-name> format."
  value       = local.agent_path
}

output "config_file_path" {
  description = "Generated GitLab Agent config file path when enabled."
  value       = try(gitlab_repository_file.this["agent"].file_path, null)
}

output "config_project_id" {
  description = "GitLab project ID where the GitLab Agent config is generated when enabled."
  value       = var.enabled ? local.config_project_id : null
}

output "config_yaml" {
  description = "Rendered GitLab Agent config.yaml content."
  value       = local.config_yaml
}

output "cluster_agent_id" {
  description = "Registered GitLab Agent ID when registration is enabled."
  value       = try(gitlab_cluster_agent.this["agent"].agent_id, null)
}

output "cluster_agent_token_id" {
  description = "GitLab Agent token ID when registration is enabled."
  value       = try(gitlab_cluster_agent_token.this["agent"].token_id, null)
}

output "helm_release_name" {
  description = "Helm release name for the installed GitLab Agent when install is enabled."
  value       = try(helm_release.gitlab_agent["agent"].name, null)
}

output "helm_release_namespace" {
  description = "Kubernetes namespace for the installed GitLab Agent when install is enabled."
  value       = try(helm_release.gitlab_agent["agent"].namespace, null)
}
