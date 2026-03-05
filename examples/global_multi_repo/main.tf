# Example: 30 GitLab repos with shared global env variables, pipeline and semantic-release
# All config comes from files (templates/), not inline content.
locals {
  token = "glpat-D_d_se1UaQJmw447z-b91286MQp1OmR5aDQwCw.01.120d9z32e"
}
provider "gitlab" {
  token = local.token
}

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.9.0"
    }
  }
}

locals {
  # List of repository names (e.g. 30 repos)
  repo_names = ["REPO-1-TEST", "REPO-2-TEST"]
}

module "gitlab_repos" {
  source = "../../"

  name             = "multi-repo-managed"
  projects_enabled = true

  # Global env variables applied to every project
  global_env_variables = [
    {
      key    = "NPM_TOKEN"
      value  = "NPM_TOKEN"
      masked = true
    },
    {
      key       = "GITLAB_TOKEN"
      value     = "GITLAB_TOKEN"
      masked    = true
      protected = true
    },
    {
      key   = "NODE_ENV"
      value = "production"
    }
  ]

  # Global repository files: same .gitlab-ci.yml and .releaserc in every repo (from files)
  global_repository_files = [
    {
      file_path      = ".gitlab-ci.yml"
      content_file   = "${path.module}/templates/.gitlab-ci.yml"
      branch         = "main"
      commit_message = "ci: add GitLab pipeline (managed by Terraform)"
    },
    {
      file_path      = ".releaserc.json"
      content_file   = "${path.module}/templates/.releaserc.json"
      branch         = "main"
      commit_message = "chore: add semantic-release config (managed by Terraform)"
    }
  ]

  gitlab_projects = [
    for name in local.repo_names : {
      name                   = name
      description            = "Managed repo: ${name}"
      default_branch         = "main"
      initialize_with_readme = true
      # Optional: per-repo overrides (env_variables / repository_files) go here
    }
  ]
}
