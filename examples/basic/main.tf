# Two GitLab groups: one project in the first group, two in the second (`gitlab_groups` + `group_key`).
#
#   export GITLAB_TOKEN='glpat-...'
#   terraform init && terraform apply
# On GitLab.com, API-created groups often need parent_group_id (subgroup under an existing namespace).

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.8.2"
    }
  }
}

provider "gitlab" {
  # GitLab.com is the default; set GITLAB_TOKEN in the environment (do not commit tokens).
}

module "gitlab" {
  source = "../.."

  projects_enabled = true

  global_env_variables = [
    { key = "GLOBAL_CI_TOKEN", value = "replace-with-shared-ci-token", masked = false },
    { key = "GLOBAL_LOG_LEVEL", value = "info" },
  ]

  gitlab_groups = [
    {
      key              = "first_group"
      create           = true
      name             = "First Group"
      path             = "example-team-a-tf"
      description      = "First group — one repo in this example"
      parent_id        = "" # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
    {
      key              = "second_group"
      create           = true
      name             = "Second Group"
      path             = "example-team-b-tf"
      description      = "Second group — two repos in this example"
      parent_id        = "" # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
  ]

  gitlab_projects = [
    {
      name                   = "service-one"
      group_key              = "first_group"
      description            = "Single project in first_group"
      default_branch         = "main"
      visibility_level       = "private"
      initialize_with_readme = true
    },
    {
      name                   = "service-two"
      group_key              = "second_group"
      description            = "First project in second_group"
      default_branch         = "main"
      visibility_level       = "private"
      initialize_with_readme = true
    },
    {
      name                   = "service-three"
      group_key              = "second_group"
      description            = "Second project in second_group"
      default_branch         = "main"
      visibility_level       = "private"
      initialize_with_readme = true
      branch_protections = [
        { branch = "main", allow_force_push = true, merge_access_level = "maintainer", push_access_level = "maintainer" },
      ]

      env_variables = [
        { key = "SERVICE_THREE_DEPLOY_TARGET", value = "staging" },
        { key = "SERVICE_THREE_BUILD_ARGS", value = "--profile=service-three" },
        { key = "GLOBAL_LOG_LEVEL", value = "debug" }, # Overrides the global variable with the same key
      ]
    },
  ]
}
