output "build_pipeline_ci_file_paths" {
  description = "Map of project name to generated build pipeline file path."
  value       = { for name in keys(local.build_pipeline_projects) : name => local.build_pipeline_file_path }
}

output "build_pipeline_source_branches" {
  description = "Map of project name to generated build pipeline source branch."
  value       = { for name in keys(local.build_pipeline_projects) : name => local.build_pipeline_source_branch }
}

output "deploy_pipeline_ci_file_paths" {
  description = "Map of project name to generated deploy pipeline file path."
  value       = { for name in keys(local.deploy_pipeline_projects) : name => local.deploy_pipeline_file_path }
}

output "deploy_pipeline_source_branches" {
  description = "Map of project name to generated deploy pipeline source branch."
  value       = { for name in keys(local.deploy_pipeline_projects) : name => local.deploy_pipeline_source_branch }
}
