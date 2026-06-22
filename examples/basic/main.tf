# Two GitLab groups: one project in the first group, two in the second (`gitlab_groups` + `group_key`).
#
#   export GITLAB_TOKEN='<gitlab-token>'
#   terraform init && terraform apply
# On GitLab.com, API-created groups often need parent_group_id (subgroup under an existing namespace).

module "gitlab" {
  source = "../.."

  projects_enabled = true

  global_env_variables = [
    { key = "GLOBAL_CI_TOKEN", value = "replace-with-shared-ci-token", masked = false },
    { key = "GLOBAL_LOG_LEVEL", value = "info" },
    { key = "AWS_REGION", value = "eu-central-1" },
    { key = "AWS_ACCESS_KEY_ID", value = "access_key" },
    { key = "AWS_SECRET_ACCESS_KEY", value = "secret_access_key", masked = true },
    { key = "AWS_SESSION_TOKEN", value = "session_token" },
    { key = "REGISTRY_USERNAME", value = "registry_username", masked = true },
    { key = "REGISTRY_PASSWORD", value = "registry_password", masked = true },
  ]

  gitlab_groups = [
    {
      key              = "first_group"
      create           = true
      name             = "First TEST Group"
      path             = "first-test-group-tf"
      description      = "First group — one repo in this example"
      parent_id        = null # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
    {
      key              = "second_group"
      create           = true
      name             = "Second TEST Group"
      path             = "second-test-group-tf"
      description      = "Second group — two repos in this example"
      parent_id        = null # Optional parent group/namespace for GitLab.com; set to null or omit for top-level groups or self-managed instances.
      visibility_level = "private"
    },
  ]

  dynamic_environments_project = {
    enabled        = true
    name           = "dynamic-environments"
    group_key      = "first_group"
    default_branch = "main"
    cluster_name   = "kind-local"
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
          { id = "terraform-gitlab-module/first-test-group-tf/example-dynamic-environments" },
          { id = "terraform-gitlab-module/first-test-group-tf/service-one" },
          { id = "terraform-gitlab-module/second-test-group-tf/service-two" },
          { id = "terraform-gitlab-module/second-test-group-tf/service-three" },
        ]
      }
      user_access = {
        access_as_agent = true
        projects = [
          { id = "terraform-gitlab-module/first-test-group-tf/example-dynamic-environments" },
          { id = "terraform-gitlab-module/first-test-group-tf/service-one" },
          { id = "terraform-gitlab-module/second-test-group-tf/service-two" },
          { id = "terraform-gitlab-module/second-test-group-tf/service-three" },
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
          type   = "build"
          target = "onprem"
          jobs = [
            {
              name = "build-dev"
              variables = {
                registry_host    = "docker.io"
                image_repository = "dasmeta/test"
                image_tags       = ["dev-$CI_COMMIT_SHORT_SHA", "latest"]
                dockerfile_path  = "Dockerfile"
                build_context    = "."
              }
            },
            {
              name = "build-prod"
              rules = [
                {
                  if = "$CI_COMMIT_TAG"
                },
              ]
              variables = {
                registry_host    = "docker.io"
                image_repository = "dasmeta/test"
                image_tags      = ["prod-$CI_COMMIT_SHORT_SHA"]
                dockerfile_path = "Dockerfile"
                build_context   = "."
              }
            },
          ]
        },
        {
          type = "deploy_agent"
          jobs = [
            {
              name = "deploy-dev"
              rules = [
                {
                  if = "$CI_COMMIT_BRANCH == \"develop\""
                },
              ]
              variables = {
                deploy_environment_name                = "dev"
                deploy_environment_kubernetes_agent    = "terraform-gitlab-module/second-test-group-tf/service-two:eks-agent"
                deploy_environment_dashboard_namespace = "dev"
                kube_namespace                         = "dev"
                helm_release                           = "demo-nginx"
                helm_chart                             = "bitnami/nginx"
                helm_repository_name                   = "bitnami"
                helm_repository_url                    = "https://charts.bitnami.com/bitnami"
                helm_wait                              = false
              }
            },
            {
              name = "deploy-prod"
              rules = [
                {
                  if = "$CI_COMMIT_TAG"
                },
              ]
              variables = {
                deploy_environment_name                = "prod"
                deploy_environment_kubernetes_agent    = "terraform-gitlab-module/second-test-group-tf/service-two:eks-agent"
                deploy_environment_dashboard_namespace = "prod"
                kube_namespace                         = "prod"
                helm_release                           = "demo-nginx"
                helm_chart                             = "bitnami/nginx"
                helm_repository_name                   = "bitnami"
                helm_repository_url                    = "https://charts.bitnami.com/bitnami"
                helm_wait                              = false
              }
            },
          ]
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
      dynamic_environment = {
        enabled = true
      }
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
