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
      key    = "incomplete_existing_group"
      create = false
    },
  ]

  gitlab_projects = [
    {
      name      = "invalid-unresolvable-group"
      group_key = "incomplete_existing_group"
    },
  ]
}
