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
      name         = "invalid-both-namespace-and-group"
      namespace_id = 54321
      group_key    = "existing_platform_group"
    },
  ]
}
