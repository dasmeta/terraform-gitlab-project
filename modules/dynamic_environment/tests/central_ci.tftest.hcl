mock_provider "gitlab" {}
mock_provider "null" {}

run "central_ci_uses_safe_defaults" {
  command = plan

  variables {
    projects_enabled  = true
    gitlab_projects   = []
    project_ids       = {}
    gitlab_agent_path = "platform/dynamic-environments:eks-agent"

    dynamic_environments_project = {
      enabled      = true
      name         = "dynamic-environments"
      cluster_name = "eks-dev"
      applications = {
        defaults          = {}
        infra_deployments = []
        deployments       = []
      }
    }
  }

  assert {
    condition = !contains(
      keys(yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)),
      "e2e_tests"
    )
    error_message = "The default central pipeline must not emit an unusable placeholder E2E job."
  }

  assert {
    condition = !strcontains(
      gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content,
      "postgresql://postgres:postgres"
    )
    error_message = "The generated central pipeline must not contain literal database credentials."
  }
}

run "central_ci_uses_custom_runtime_and_e2e_config" {
  command = plan

  variables {
    projects_enabled  = true
    gitlab_projects   = []
    project_ids       = {}
    gitlab_agent_path = "platform/dynamic-environments:eks-agent"

    dynamic_environments_project = {
      enabled      = true
      name         = "dynamic-environments"
      cluster_name = "eks-dev"

      ci_config = {
        deploy_image                   = "registry.example.com/platform/k8s:1.30.3"
        cleanup_image                  = "registry.example.com/platform/cleanup:1.30.3"
        placeholder_image              = "registry.example.com/platform/alpine:3.21"
        alpine_packages                = ["python3", "git"]
        python_packages                = ["pyyaml", "requests"]
        migration_job_name             = "database-migration"
        migration_timeout              = "900s"
        aws_access_key_id_variable     = "CUSTOM_AWS_ACCESS_KEY_ID"
        aws_secret_access_key_variable = "CUSTOM_AWS_SECRET_ACCESS_KEY"
      }

      e2e_config = {
        enabled  = true
        project  = "platform/e2e-tests"
        branch   = "e2e-dynamic"
        strategy = "depend"
        variables = {
          APP_BASE_URL  = "https://app-$DYNAMIC_ENV_HOST"
          CUSTOM_WS_URL = "wss://app-$DYNAMIC_ENV_HOST/ws"
          DATABASE_URL  = "postgresql://postgres:postgres@postgres-postgresql.$DYNAMIC_NAMESPACE.svc.cluster.local:5432/postgres"
          TEST_SUITE    = "dynamic"
        }
        rules = [
          {
            if   = "$CI_PIPELINE_SOURCE == \"schedule\""
            when = "manual"
          }
        ]
      }

      applications = {
        defaults          = {}
        infra_deployments = []
        deployments       = []
      }
    }
  }

  assert {
    condition = (
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)[".deploy-dynamic"].image.name ==
      "registry.example.com/platform/k8s:1.30.3"
    )
    error_message = "The deploy job must use ci_config.deploy_image."
  }

  assert {
    condition = (
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)["remove-dynamic-stack"].image.name ==
      "registry.example.com/platform/cleanup:1.30.3"
    )
    error_message = "The cleanup job must use ci_config.cleanup_image."
  }

  assert {
    condition = (
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).mr_pipeline_placeholder.image ==
      "registry.example.com/platform/alpine:3.21"
    )
    error_message = "The MR placeholder job must use ci_config.placeholder_image."
  }

  assert {
    condition = alltrue([
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "apk add --no-cache python3 git"),
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "pip3 install --no-cache-dir pyyaml requests"),
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "job/database-migration"),
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "--timeout=900s"),
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "$CUSTOM_AWS_ACCESS_KEY_ID"),
      strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "$CUSTOM_AWS_SECRET_ACCESS_KEY"),
    ])
    error_message = "The deploy job must use all configured runtime values."
  }

  assert {
    condition = (
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).variables.E2E_PROJECT ==
      "platform/e2e-tests" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).variables.E2E_BRANCH ==
      "e2e-dynamic" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.trigger.project ==
      "$E2E_PROJECT" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.trigger.branch ==
      "$E2E_BRANCH" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.trigger.strategy ==
      "depend"
    )
    error_message = "The E2E trigger must read project and branch from global CI variables."
  }

  assert {
    condition = (
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.variables.TEST_SUITE ==
      "dynamic" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.variables.E2E_DYNAMIC_STACK ==
      "true" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.variables.APP_BASE_URL ==
      "https://app-$DYNAMIC_ENV_HOST" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.variables.CUSTOM_WS_URL ==
      "wss://app-$DYNAMIC_ENV_HOST/ws" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.variables.DATABASE_URL ==
      "postgresql://postgres:postgres@postgres-postgresql.$DYNAMIC_NAMESPACE.svc.cluster.local:5432/postgres"
    )
    error_message = "The E2E job must merge configured variables over the standard E2E variable map."
  }

  assert {
    condition = (
      !contains(
        keys(local.dynamic_environments_e2e_default_variables),
        "APP_BASE_URL"
      ) &&
      !contains(
        keys(local.dynamic_environments_e2e_default_variables),
        "CUSTOM_WS_URL"
      ) &&
      !contains(
        keys(local.dynamic_environments_e2e_default_variables),
        "DATABASE_URL"
      )
    )
    error_message = "Environment-specific E2E URLs and database connection must come only from Terraform input."
  }

  assert {
    condition = (
      length(yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.rules) == 6 &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.rules[0].if ==
      "$REMOVE_DYNAMIC" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.rules[4].if ==
      "$CI_PIPELINE_SOURCE == \"trigger\"" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.rules[5].if ==
      "$CI_PIPELINE_SOURCE == \"schedule\"" &&
      yamldecode(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content).e2e_tests.rules[5].when ==
      "manual"
    )
    error_message = "The E2E job must append configured rules to the five standard E2E rules."
  }

  assert {
    condition = (
      strcontains(
        gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content,
        "stages:\n  - deploy\n  - e2e-test\n  - remove\n\nvariables:\n"
      ) &&
      strcontains(
        gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content,
        "\n\n.deploy-dynamic:\n"
      ) &&
      !strcontains(
        gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content,
        "\"stages\""
      ) &&
      !strcontains(
        gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content,
        "\"variables\""
      )
    )
    error_message = "The generated YAML must keep stages first, variables second, unquoted keys, and blank lines between top-level sections."
  }

  assert {
    condition = alltrue([
      length(regexall("(?s)\\.deploy-dynamic:\\n  stage:.*?\\n  image:.*?\\n  tags:.*?\\n  environment:.*?\\n  before_script:.*?\\n  script:", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 1,
      length(regexall("(?s)deploy-dynamic-stack:\\n  extends:.*?\\n  rules:", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 1,
      length(regexall("(?s)mr_pipeline_placeholder:\\n  stage:.*?\\n  image:.*?\\n  tags:.*?\\n  script:.*?\\n  rules:", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 1,
      length(regexall("(?s)e2e_tests:\\n  stage:.*?\\n  trigger:.*?\\n  variables:.*?\\n  rules:", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 1,
      length(regexall("(?s)remove-dynamic-stack:\\n  stage:.*?\\n  image:.*?\\n  tags:.*?\\n  environment:.*?\\n  script:.*?\\n  rules:", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 1,
    ])
    error_message = "Each generated job must preserve the required field order."
  }

  assert {
    condition = (
      !strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "if: \"$REMOVE_DYNAMIC\"") &&
      !strcontains(gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content, "if: \"$CI_PIPELINE_SOURCE")
    )
    error_message = "Rule expressions must render without outer YAML quotes."
  }

  assert {
    condition = (
      length(regexall("entrypoint: \\[\"/bin/sh\", \"-c\"\\]", gitlab_repository_file.dynamic_environment_central[".gitlab-ci.yml"].content)) == 2
    )
    error_message = "Deploy and remove image entrypoints must quote both shell arguments."
  }
}
