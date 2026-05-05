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
    for p in var.gitlab_projects : merge({
      description                                      = null
      visibility_level                                 = "private"
      default_branch                                   = "develop"
      initialize_with_readme                           = true
      request_access_enabled                           = true
      prevent_destroy                                  = true
      namespace_id                                     = null
      group_key                                        = null
      lfs_enabled                                      = true
      packages_enabled                                 = true
      squash_option                                    = "default_on"
      merge_method                                     = "merge"
      only_allow_merge_if_pipeline_succeeds            = true
      only_allow_merge_if_all_discussions_are_resolved = true
      remove_source_branch_after_merge                 = true
      ci_pipeline_variables_minimum_override_role      = "developer"
      pages_access_level                               = "private"
      suggestion_commit_message                        = null
      merge_commit_template                            = null
      branch_protections                               = []
      approval_rule                                    = null
      push_rules                                       = []
      env_variables                                    = []
      }, p, {
      namespace_id = coalesce(
        try(p.namespace_id, null),
        length(var.gitlab_groups) > 0 ? lookup(
          local.namespace_by_key,
          coalesce(try(p.group_key, null), var.gitlab_groups[0].key),
          null
        ) : null
      )
    })
  ]

  gitlab_projects_for_children = [
    for p in local.gitlab_projects_resolved : p
    if local.effective_projects_enabled
  ]
}
