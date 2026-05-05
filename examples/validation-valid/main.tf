terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.8.2"
    }
  }
}

module "gitlab" {
  source = "../.."

  projects_enabled = false

  gitlab_groups = [
    {
      key               = "existing_platform_group"
      create            = false
      existing_group_id = 12345
    },
  ]

  gitlab_projects = [
    {
      name        = "valid-single-group-fallback"
      description = "Uses the implicit single-group fallback"
      approval_rule = [
        {
          name               = "merge into main"
          approvals_required = 1
        },
      ]
    },
  ]
}
