locals {
  renovate_repositories = sort(distinct(concat(
    var.renovate.repositories,
    [for project in local.gitlab_projects_for_children : module.project.path_with_namespace[project.name] if project.renovate.enabled]
  )))
}

module "renovate" {
  source = "./modules/renovate"

  repositories = local.renovate_repositories
  endpoint     = var.renovate.endpoint
  install      = var.renovate.install
}

module "renovate_repository" {
  source = "./modules/renovate_repository"

  gitlab_projects = local.gitlab_projects_for_children
  project_ids     = module.project.project_ids
  endpoint        = var.renovate.endpoint
}
