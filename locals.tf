locals {
  effective_projects_enabled = var.create && var.projects_enabled

  gitlab_groups_effective = length(var.gitlab_groups) > 0 ? var.gitlab_groups : [
    {
      key                   = "default"
      create                = var.gitlab_group.create
      name                  = try(var.gitlab_group.name, null)
      path                  = try(var.gitlab_group.path, null)
      description           = var.gitlab_group.description
      visibility_level      = var.gitlab_group.visibility_level
      parent_id             = try(var.gitlab_group.parent_id, null)
      existing_namespace_id = try(var.gitlab_group.existing_namespace_id, null)
    }
  ]

  default_group_key = local.gitlab_groups_effective[0].key

  namespace_by_key = merge(
    {
      for g in local.gitlab_groups_effective : g.key => g.existing_namespace_id
      if !g.create && try(g.existing_namespace_id, null) != null
    },
    { for k, m in module.gitlab_group : k => m.id },
  )

  gitlab_projects_resolved = [
    for p in var.gitlab_projects : merge(p, {
      namespace_id = coalesce(
        try(p.namespace_id, null),
        try(local.namespace_by_key[coalesce(try(p.group_key, null), local.default_group_key)], null)
      )
    })
  ]

  gitlab_projects_for_children = local.effective_projects_enabled ? local.gitlab_projects_resolved : []
}
