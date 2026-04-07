module "gitlab_group" {
  source = "./modules/gitlab_group"
  for_each = {
    for g in local.gitlab_groups_effective : g.key => g
    if var.create && g.create
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

check "gitlab_projects_target_group_when_multi" {
  assert {
    condition = length(local.gitlab_groups_effective) <= 1 || alltrue([
      for p in var.gitlab_projects :
      try(p.namespace_id, null) != null || try(p.group_key, null) != null
    ])
    error_message = "With multiple gitlab_groups entries, each gitlab_projects item must set namespace_id or group_key."
  }
}
