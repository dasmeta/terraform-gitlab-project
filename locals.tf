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

  dynamic_environments_project_resolved = merge(var.dynamic_environments_project, {
    namespace_id = local.effective_projects_enabled && try(var.dynamic_environments_project.enabled, false) ? coalesce(
      try(var.dynamic_environments_project.namespace_id, null),
      lookup(
        local.namespace_by_key,
        coalesce(
          try(var.dynamic_environments_project.group_key, null),
          length(local.gitlab_groups_effective) == 1 ? local.gitlab_groups_effective[0].key : "__UNRESOLVED_GROUP_KEY__"
        ),
        null
      )
    ) : null
  })

  dynamic_environment_enabled_service_names = [
    for p in local.gitlab_projects_resolved : p.name
    if local.effective_projects_enabled && try(p.dynamic_environment.enabled, false)
  ]
  dynamic_environment_enabled_service_paths = [
    for name in local.dynamic_environment_enabled_service_names : module.project.path_with_namespace[name]
    if contains(keys(module.project.path_with_namespace), name)
  ]

  gitlab_agent_config              = try(var.dynamic_environments_project.gitlab_agent, {})
  gitlab_agent_enabled             = local.effective_projects_enabled && try(var.dynamic_environments_project.enabled, false) && try(local.gitlab_agent_config.enabled, false)
  gitlab_agent_name                = coalesce(try(local.gitlab_agent_config.name, null), try(var.dynamic_environments_project.cluster_name, "eks-dev"))
  gitlab_agent_config_project_name = try(local.gitlab_agent_config.config_project_name, null)
  gitlab_agent_config_project_path = try(coalesce(
    try(local.gitlab_agent_config.config_project_path, null),
    local.gitlab_agent_config_project_name == null ? null : try(module.project.path_with_namespace[local.gitlab_agent_config_project_name], null),
    module.dynamic_environment.project_path
  ), null)
  dynamic_environment_gitlab_agent_path = coalesce(
    try(var.dynamic_environments_project.gitlab_agent_path, null),
    local.gitlab_agent_enabled && local.gitlab_agent_config_project_path != null ? "${local.gitlab_agent_config_project_path}:${local.gitlab_agent_name}" : null,
    ""
  )
}
