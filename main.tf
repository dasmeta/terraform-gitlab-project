module "gitlab_group" {
  source = "./modules/gitlab_group"
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

  projects_enabled = local.effective_projects_enabled
  gitlab_projects  = local.gitlab_projects_resolved
}

module "ci_env_variables" {
  source = "./modules/ci_env_variables"

  gitlab_projects      = local.gitlab_projects_for_children
  global_env_variables = var.global_env_variables
  project_ids          = module.project.project_ids
}
