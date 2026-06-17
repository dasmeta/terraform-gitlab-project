# Two GitLab groups: one project in the first group, two in the second (`gitlab_groups` + `group_key`).
#
#   export GITLAB_TOKEN='<gitlab-token>'
#   terraform init && terraform apply
# On GitLab.com, API-created groups often need parent_group_id (subgroup under an existing namespace).

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 19.0"
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
    { key = "AWS_REGION", value = "eu-central-1" }, # Replaces the previous definition with the same key
  ]

  gitlab_groups = [
    {
      key              = "first_group"
      create           = true
      name             = "First TEST Group"
      path             = "first-test-group-tf"
      description      = "First group — one repo in this example"
      parent_id        = 129092988 # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
    {
      key              = "second_group"
      create           = true
      name             = "Second TEST Group"
      path             = "second-test-group-tf"
      description      = "Second group — two repos in this example"
      parent_id        = 129092988 # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
  ]

  gitlab_projects = [
    {
      name                                  = "service-one"
      group_key                             = "first_group"
      description                           = "Single project in first_group"
      default_branch                        = "main"
      visibility_level                      = "private"
      initialize_with_readme                = true
      only_allow_merge_if_pipeline_succeeds = false
      gitlab_ci_pipelines = [
        {
          type = "build_ecr"
          variables = {
            aws_region       = "eu-central-1"
            image_repository = "565580475168.dkr.ecr.eu-central-1.amazonaws.com/vazgen-test"
            image_tag        = "$CI_COMMIT_SHORT_SHA"
            dockerfile_path  = "Dockerfile"
            build_context    = "."
          }
        }
      ]
      merge_requests_template = <<-EOT
        ## Story

        ## Dependencies added/updated

        ## Changes
      EOT
    },
    {
      name                                  = "service-two"
      group_key                             = "second_group"
      description                           = "First project in second_group"
      default_branch                        = "main"
      visibility_level                      = "private"
      initialize_with_readme                = true
      only_allow_merge_if_pipeline_succeeds = false
    },
    {
      name                                  = "service-three"
      group_key                             = "second_group"
      description                           = "Second project in second_group"
      default_branch                        = "main"
      visibility_level                      = "private"
      initialize_with_readme                = true
      only_allow_merge_if_pipeline_succeeds = false
      branch_protections = [
        { branch = "main", allow_force_push = true, merge_access_level = "maintainer", push_access_level = "maintainer" },
      ]

      env_variables = [
        { key = "SERVICE_THREE_DEPLOY_TARGET", value = "staging" },
        { key = "SERVICE_THREE_BUILD_ARGS", value = "--profile=service-three" },
        { key = "GLOBAL_LOG_LEVEL", value = "debug" }, # Replaces the full global definition with the same key
      ]
    },
  ]
}
