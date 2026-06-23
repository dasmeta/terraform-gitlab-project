output "project_id" {
  description = "GitLab project ID for the central dynamic environments project when enabled."
  value       = try(gitlab_project.dynamic_environment["central"].id, null)
}

output "project_path" {
  description = "Path with namespace for the central dynamic environments project when enabled."
  value       = try(gitlab_project.dynamic_environment["central"].path_with_namespace, null)
}

output "service_ci_file_paths" {
  description = "Map of service project name to generated dynamic environment CI trigger file path."
  value = {
    for name, file in gitlab_repository_file.dynamic_environment_service : name => file.file_path
  }
}

output "gitlab_agent_path" {
  description = "GitLab Agent context path referenced by generated dynamic environment CI."
  value       = local.dynamic_environments_agent_path
}
