locals {
  # One gitlab_branch_protection per (project name, branch). Keys must be unique per project.
  branch_protections_flat = flatten([
    for p in var.gitlab_projects : [
      for bp in length(try(p.branch_protections, [])) > 0 ? p.branch_protections : [{ branch = "main" }] : {
        key                          = "${p.name}::${bp.branch}"
        project_name                 = p.name
        branch                       = bp.branch
        merge_access_level           = coalesce(try(bp.merge_access_level, null), "maintainer")
        push_access_level            = coalesce(try(bp.push_access_level, null), "maintainer")
        allow_force_push             = coalesce(try(bp.allow_force_push, null), false)
        code_owner_approval_required = coalesce(try(bp.code_owner_approval_required, null), false)
        unprotect_access_level       = coalesce(try(bp.unprotect_access_level, null), "maintainer")
      }
    ]
  ])
}
