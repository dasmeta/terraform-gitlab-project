locals {
  project_env_variables = {
    for item in flatten([
      for p in var.gitlab_projects : [
        for key, env in merge(
          { for e in var.global_env_variables : e.key => e },
          { for e in lookup(p, "env_variables", []) : e.key => e }
          ) : {
          project_name = p.name
          key          = key
          env          = env
        }
      ]
    ]) : "${item.project_name}:${item.key}" => item
  }
}

resource "gitlab_project_variable" "env" {
  for_each = local.project_env_variables

  project = var.project_ids[each.value.project_name]

  key       = each.value.env.key
  value     = each.value.env.value
  protected = try(each.value.env.protected, false)
  masked    = try(each.value.env.masked, false)
}
