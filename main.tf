module "gitlab_group" {
  source = "./modules/gitlab_group"
  # Only creation-mode groups are materialized here; referenced existing groups
  # participate through existing_group_id resolution in the root module.
  for_each = {
    for g in local.gitlab_groups_effective : g.key => g
    if g.create
  }

  create           = true
  name             = coalesce(each.value.name, "")
  path             = coalesce(each.value.path, "")
  description      = each.value.description
  visibility_level = each.value.visibility_level
  parent_id        = try(each.value.parent_id, null)
}

module "project" {
  source = "./modules/project"
  # Child modules receive normalized project objects so they do not need to
  # re-interpret ambiguous consumer input combinations.

  projects_enabled = local.effective_projects_enabled
  gitlab_projects  = local.gitlab_projects_resolved
}

module "ci_env_variables" {
  source = "./modules/ci_env_variables"
  # Variable assignment consumes the normalized project list; project entries
  # replace global variable definitions by key.

  gitlab_projects      = local.gitlab_projects_for_children
  global_env_variables = var.global_env_variables
  project_ids          = module.project.project_ids
}

module "dynamic_environment" {
  source = "./modules/dynamic_environment"
  # Dynamic environments orchestration is separated from standard project
  # lifecycle management so it can evolve independently.

  projects_enabled             = local.effective_projects_enabled
  gitlab_projects              = local.gitlab_projects_resolved
  project_ids                  = module.project.project_ids
  dynamic_environments_project = local.dynamic_environments_project_resolved
  gitlab_agent_path            = local.dynamic_environment_gitlab_agent_path
}

module "gitlab_agent_config" {
  source = "./modules/gitlab_agent_config"
  # GitLab Agent config belongs to the dynamic environments project by default,
  # while still allowing consumers to target another managed or external project.

  enabled               = local.gitlab_agent_enabled
  gitlab_agent          = local.gitlab_agent_config
  gitlab_api_url        = try(var.dynamic_environments_project.gitlab_api_url, "https://gitlab.com/api/v4")
  cluster_name          = try(var.dynamic_environments_project.cluster_name, "eks-dev")
  project_ids           = module.project.project_ids
  project_paths         = module.project.path_with_namespace
  central_project_id    = module.dynamic_environment.project_id
  central_project_path  = module.dynamic_environment.project_path
  service_project_paths = local.dynamic_environment_enabled_service_paths
}
