mock_provider "gitlab" {
  mock_resource "gitlab_project" {
    defaults = {
      id = "4242"
    }
  }
}

variables {
  projects_enabled = true
  gitlab_projects = [
    {
      name                                             = "locked"
      namespace_id                                     = 1
      default_branch                                   = "main"
      visibility_level                                 = "private"
      initialize_with_readme                           = false
      request_access_enabled                           = true
      lfs_enabled                                      = true
      packages_enabled                                 = true
      squash_option                                    = "default_on"
      merge_method                                     = "ff"
      only_allow_merge_if_pipeline_succeeds            = true
      only_allow_merge_if_all_discussions_are_resolved = true
      remove_source_branch_after_merge                 = true
      ci_pipeline_variables_minimum_override_role      = "developer"
      pages_access_level                               = "private"
      ci_delete_pipelines_in_seconds                   = 7776000
      mr_approvals                                     = { reset_approvals_on_push = true }
      branch_protections = [
        {
          branch            = "main"
          push_access_level = "no one"
          push_user_ids     = [10901987]
        }
      ]
    },
    {
      name                                             = "plain"
      namespace_id                                     = 1
      default_branch                                   = "main"
      visibility_level                                 = "private"
      initialize_with_readme                           = false
      request_access_enabled                           = true
      lfs_enabled                                      = true
      packages_enabled                                 = true
      squash_option                                    = "default_on"
      merge_method                                     = "ff"
      only_allow_merge_if_pipeline_succeeds            = true
      only_allow_merge_if_all_discussions_are_resolved = true
      remove_source_branch_after_merge                 = true
      ci_pipeline_variables_minimum_override_role      = "developer"
      pages_access_level                               = "private"
    }
  ]
}

run "retention_is_passed_through" {
  command = apply

  assert {
    condition     = gitlab_project.this["locked"].ci_delete_pipelines_in_seconds == 7776000
    error_message = "ci_delete_pipelines_in_seconds was not set on the project."
  }
}

run "push_user_ids_extend_allowed_to_push" {
  command = apply

  assert {
    condition     = length(gitlab_branch_protection.branch["locked::main"].allowed_to_push) == 2
    error_message = "Expected the access-level row plus one user row."
  }

  assert {
    condition     = contains([for row in gitlab_branch_protection.branch["locked::main"].allowed_to_push : row.access_level if row.access_level != null], "no one")
    error_message = "push_access_level row is missing."
  }

  assert {
    condition     = contains([for row in gitlab_branch_protection.branch["locked::main"].allowed_to_push : row.user_id if row.user_id != null], 10901987)
    error_message = "push_user_ids row is missing."
  }
}

run "partial_mr_approvals_only_manage_given_fields" {
  command = apply

  assert {
    condition     = gitlab_project_level_mr_approvals.this["locked"].reset_approvals_on_push == true
    error_message = "reset_approvals_on_push was not set."
  }

  assert {
    condition     = !contains(keys(gitlab_project_level_mr_approvals.this), "plain")
    error_message = "mr_approvals must stay unmanaged when it is omitted."
  }
}

run "default_branch_protection_without_input" {
  command = apply

  assert {
    condition     = gitlab_branch_protection.branch["plain::main"].branch == "main"
    error_message = "Projects without branch_protections must still get the default main protection."
  }

  assert {
    condition     = length(gitlab_branch_protection.branch["plain::main"].allowed_to_push) == 1
    error_message = "The default protection must have only the access-level row."
  }
}
