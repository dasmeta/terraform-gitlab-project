output "gitlab_project_ids" {
  description = "Map of GitLab project name to project ID"
  value       = module.project.project_ids
}

output "gitlab_group_ids" {
  description = "Map of group key (from gitlab_groups) to namespace id for every resolvable configured group — managed groups contribute their created id and existing-group references require existing_group_id."
  value       = local.namespace_by_key
}

output "gitlab_group_full_paths" {
  description = "Map of group key to full_path for groups created by this module (Terraform-managed only; existing groups referenced via existing_group_id are not listed here)."
  value       = { for k, m in module.gitlab_group : k => m.full_path }
}

output "dynamic_environments_project_id" {
  description = "GitLab project ID for the central dynamic environments project when enabled."
  value       = module.dynamic_environment.project_id
}

output "dynamic_environments_project_path" {
  description = "Path with namespace for the central dynamic environments project when enabled."
  value       = module.dynamic_environment.project_path
}

output "dynamic_environment_service_ci_file_paths" {
  description = "Map of service project name to generated dynamic environment CI trigger file path."
  value       = module.dynamic_environment.service_ci_file_paths
}

output "gitlab_ci_build_pipeline_file_paths" {
  description = "Map of service project name to generated reusable build CI file path."
  value       = module.gitlab_ci_pipelines.build_pipeline_ci_file_paths
}

output "gitlab_ci_build_pipeline_source_branches" {
  description = "Map of service project name to generated reusable build CI source branch."
  value       = module.gitlab_ci_pipelines.build_pipeline_source_branches
}

output "gitlab_ci_deploy_pipeline_file_paths" {
  description = "Map of service project name to generated reusable deploy CI file path."
  value       = module.gitlab_ci_pipelines.deploy_pipeline_ci_file_paths
}

output "gitlab_ci_deploy_pipeline_source_branches" {
  description = "Map of service project name to generated reusable deploy CI source branch."
  value       = module.gitlab_ci_pipelines.deploy_pipeline_source_branches
}

output "dynamic_environment_gitlab_agent_path" {
  description = "GitLab Agent context path referenced by generated dynamic environment CI."
  value       = module.dynamic_environment.gitlab_agent_path
}

output "dynamic_environment_gitlab_agent_config_file_path" {
  description = "Generated GitLab Agent config file path when agent config generation is enabled."
  value       = module.gitlab_agent_config.config_file_path
}

output "dynamic_environment_gitlab_agent_config_project_id" {
  description = "GitLab project ID where the GitLab Agent config is generated when enabled."
  value       = module.gitlab_agent_config.config_project_id
}

output "dynamic_environment_gitlab_agent_cluster_agent_id" {
  description = "Registered GitLab Agent ID when registration is enabled."
  value       = module.gitlab_agent_config.cluster_agent_id
}

output "dynamic_environment_gitlab_agent_helm_release_name" {
  description = "Helm release name for the installed GitLab Agent when install is enabled."
  value       = module.gitlab_agent_config.helm_release_name
}

output "dynamic_environment_gitlab_agent_helm_release_namespace" {
  description = "Kubernetes namespace for the installed GitLab Agent when install is enabled."
  value       = module.gitlab_agent_config.helm_release_namespace
}
