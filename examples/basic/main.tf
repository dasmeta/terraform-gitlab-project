# Two GitLab groups: one project in the first group, two in the second (`gitlab_groups` + `group_key`).
#
#   export GITLAB_TOKEN='replace-with-gitlab-token'
#   aws eks update-kubeconfig --region us-east-2 --name eks-dev
#   terraform init && terraform apply
# On GitLab.com, API-created groups often need parent_group_id (subgroup under an existing namespace).

module "gitlab" {
  source = "../.."

  providers = {
    gitlab = gitlab
    helm   = helm
  }

  projects_enabled = true

  global_env_variables = [
    { key = "AWS_ACCESS_KEY_ID", value = "replace-with-aws-access-key-id", masked = true },
    { key = "AWS_SECRET_ACCESS_KEY", value = "replace-with-aws-secret-access-key", masked = true },
    { key = "AWS_SESSION_TOKEN", value = "replace-with-aws-session-token", masked = true },
    { key = "AWS_REGION", value = "replace-with-aws-region" },
    { key = "AWS_ECR_REGISTRY", value = "replace-with-aws-ecr-registry" },
    { key = "ECR_REPOSITORY_NAME", value = "replace-with-ecr-repository-name" },
  ]

  gitlab_groups = [
    {
      key              = "first_group"
      create           = true
      name             = "First Group"
      path             = "example-team-a-tf"
      description      = "First group — one repo in this example"
      parent_id        = null # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
    {
      key              = "second_group"
      create           = true
      name             = "Second Group"
      path             = "example-team-b-tf"
      description      = "Second group — two repos in this example"
      parent_id        = null # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
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
      only_allow_merge_if_pipeline_succeeds = false
      initialize_with_readme                = true
      dynamic_environment = {
        enabled = true
      }
    },
    {
      name                                  = "service-two"
      group_key                             = "second_group"
      description                           = "First project in second_group"
      default_branch                        = "main"
      only_allow_merge_if_pipeline_succeeds = false
      visibility_level                      = "private"
      initialize_with_readme                = true
    },
    {
      name             = "service-three"
      group_key        = "second_group"
      description      = "Second project in second_group"
      default_branch   = "main"
      visibility_level = "private"
      dynamic_environment = {
        enabled = true
      }

      only_allow_merge_if_pipeline_succeeds = false
      initialize_with_readme                = true
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

  dynamic_environments_project = {
    enabled        = true
    name           = "example-dynamic-environments"
    group_key      = "first_group"
    default_branch = "main"
    deploy_mode    = "gitlab_agent"

    gitlab_agent = {
      enabled             = true
      name                = "eks-agent"
      source_branch       = "feature/gitlab-agent-config"
      target_branch       = "main"
      register_agent      = true
      config_project_name = "service-two"
      install = {
        enabled     = true
        namespace   = "gitlab-agent"
        kas_address = "wss://kas.gitlab.com"
      }
      ci_access = {
        projects = [
          { id = "terraform-gitlab-module/example-team-a-tf/example-dynamic-environments" },
          { id = "terraform-gitlab-module/example-team-a-tf/service-one" },
          { id = "terraform-gitlab-module/example-team-b-tf/service-two" },
          { id = "terraform-gitlab-module/example-team-b-tf/service-three" },
        ]
      }
      user_access = {
        access_as_agent = true
        projects = [
          { id = "terraform-gitlab-module/example-team-a-tf/example-dynamic-environments" },
          { id = "terraform-gitlab-module/example-team-a-tf/service-one" },
          { id = "terraform-gitlab-module/example-team-b-tf/service-two" },
          { id = "terraform-gitlab-module/example-team-b-tf/service-three" },
        ]
      }
    }

    deploy_config = {
      namespace_prefix      = "e2e-"
      gitlab_clone_base_url = "https://gitlab.com"
      helm_repo_name        = "dasmeta"
      helm_repo_url         = "https://dasmeta.github.io/helm"
      work_dir              = "/tmp/dynamic-deploy"
    }

    cleanup_config = {
      max_attempts          = 3
      retry_backoff_seconds = 5
    }

    applications = {
      defaults = {
        secret_env = "dev"
      }

      infra_deployments = [
        {
          release   = "redis"
          repo_name = "bitnami"
          repo_url  = "https://charts.bitnami.com/bitnami"
          chart     = "bitnami/redis"
          version   = "20.6.3"
          values = {
            architecture = "standalone"
            auth = {
              enabled = false
            }
          }
        },
        {
          release   = "mq"
          repo_name = "bitnami"
          repo_url  = "https://charts.bitnami.com/bitnami"
          chart     = "bitnami/rabbitmq"
          version   = "15.5.3"
          values = {
            auth = {
              username = "guest"
              password = "guest"
            }
            persistence = {
              enabled = false
            }
          }
        }
      ]

      deployments = [
        {
          project       = "example/service-one"
          helm_release  = "service-one"
          app_component = "service-one"
          helm_version  = "0.3.14"
          helm_overrides = [
            "ingress.hosts[0].host=service-one-<DYNAMIC_ENV_HOST>.dev.example.com",
          ]
        },
        {
          project       = "example/service-two"
          helm_release  = "service-two"
          app_component = "service-two"
          helm_version  = "0.3.14"
          helm_overrides = [
            "ingress.hosts[0].host=service-two-<DYNAMIC_ENV_HOST>.dev.example.com",
          ]
        },
      ]
    }
  }
}
