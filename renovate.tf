locals {
  renovate_managed_file_paths = {
    for project in local.gitlab_projects_for_children : project.name => distinct(concat(
      lookup(module.gitlab_ci_pipelines.repository_file_paths, project.name, []),
      contains(keys(module.dynamic_environment.service_ci_file_paths), project.name) ? [module.dynamic_environment.service_ci_file_paths[project.name]] : [],
      module.gitlab_agent_config.config_project_id == module.project.project_ids[project.name] && module.gitlab_agent_config.config_file_path != null ? [module.gitlab_agent_config.config_file_path] : []
    ))
  }
  renovate_repositories = sort(distinct(concat(
    var.renovate.repositories,
    [for project in local.gitlab_projects_for_children : module.project.path_with_namespace[project.name] if project.renovate.enabled]
  )))
}

module "renovate" {
  source = "./modules/renovate"

  repositories   = local.renovate_repositories
  endpoint       = var.renovate.endpoint
  install        = var.renovate.install
  renovate_token = var.renovate_token
}

module "renovate_repository" {
  source = "./modules/renovate_repository"

  gitlab_projects     = local.gitlab_projects_for_children
  project_ids         = module.project.project_ids
  endpoint            = var.renovate.endpoint
  repository_defaults = var.renovate.defaults
  managed_file_paths  = local.renovate_managed_file_paths
}
