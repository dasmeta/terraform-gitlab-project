module "example" {
  source = "../../"

  name = "repo-managed"
  gitlab_projects = [
    for name in ["test-project"] : {
      name                   = name
      description            = "Managed repo: ${name}"
      default_branch         = "main"
      initialize_with_readme = true
      # Optional: per-repo overrides (env_variables / repository_files) go here
    }
  ]
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
