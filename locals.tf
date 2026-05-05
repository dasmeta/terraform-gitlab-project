locals {
  effective_projects_enabled = var.projects_enabled

  gitlab_groups_effective = var.gitlab_groups

  namespace_by_key = merge(
    {
      for g in local.gitlab_groups_effective : g.key => g.existing_group_id
      if !g.create && try(g.existing_group_id, null) != null
    },
    { for k, m in module.gitlab_group : k => m.id },
  )

  gitlab_projects_resolved = [
    for p in var.gitlab_projects : merge(p, {
      namespace_id = coalesce(
        try(p.namespace_id, null),
        lookup(
          local.namespace_by_key,
          coalesce(
            try(p.group_key, null),
            length(local.gitlab_groups_effective) == 1 ? local.gitlab_groups_effective[0].key : "__UNRESOLVED_GROUP_KEY__"
          ),
          null
        )
      )
    })
  ]

  gitlab_projects_for_children = [
    for p in local.gitlab_projects_resolved : p
    if local.effective_projects_enabled
  ]
}
