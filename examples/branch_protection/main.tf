module "example" {
  source = "../../"

  name = "test"

  approval_rule = {
    enabled                           = true
    name                              = "Approval Rules"
    approvals_required                = 1
    applies_to_all_protected_branches = true
  }
  gitlab_projects = [{
    enabled = true
    name    = "test_project"
  }]
}

provider "gitlab" {
  # Configuration options
  token = "pst token"
}

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.8.2"
    }
  }
}
