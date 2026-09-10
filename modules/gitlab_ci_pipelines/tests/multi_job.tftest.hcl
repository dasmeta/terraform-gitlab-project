mock_provider "gitlab" {}
mock_provider "null" {}

run "deploy_agent_multi_job" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            stop_environment = {
              enabled      = true
              auto_stop_in = "1 hour"
            }
            jobs = [
              {
                name = "deploy-dev"
                rules = [
                  {
                    if      = "$CI_COMMIT_BRANCH == \"main\""
                    when    = "on_success"
                    changes = null
                    exists  = null
                  },
                ]
                variables = {
                  deploy_environment_name                = "dev"
                  deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
                  deploy_environment_dashboard_namespace = "dev"
                  kube_namespace                         = "dev"
                  helm_release                           = "example-service"
                  helm_chart                             = "dasmeta/base"
                  helm_wait                              = false
                }
              },
              {
                name = "deploy-prod"
                variables = {
                  deploy_environment_name                = "prod"
                  deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
                  deploy_environment_dashboard_namespace = "prod"
                  kube_namespace                         = "prod"
                  helm_release                           = "example-service"
                  helm_chart                             = "dasmeta/base"
                  helm_wait                              = false
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].file_path == "ci-pipelines/deploy.gitlab-ci.yml"
    error_message = "deploy_agent must use the new default file path."
  }

  assert {
    condition     = length(regexall("(?m)^include:$", gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content)) == 1
    error_message = "The generated multi-job file must contain exactly one include block."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  extends: .deploy-agent")
    error_message = "deploy_agent jobs must extend the .deploy-agent template."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "\ndeploy-dev:\n") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "\ndeploy-prod:\n")
    error_message = "The generated file must contain deploy-dev and deploy-prod jobs."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "DEPLOY_ENVIRONMENT_NAME: \"dev\"") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "DEPLOY_ENVIRONMENT_NAME: \"prod\"")
    error_message = "Each generated job must retain its environment-specific variables."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  rules:\n    - if: '$CI_COMMIT_BRANCH == \"main\"'\n      when: \"on_success\"")
    error_message = "The generated deploy-dev job must include its configured branch rule."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  environment:\n    name: \"dev\"") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "    on_stop: stop-deploy-dev")
    error_message = "The deploy job must render GitLab environment metadata with a paired stop job."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "    auto_stop_in: \"1 hour\"")
    error_message = "The deploy job must render a 1 hour auto-stop duration."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "\nstop-deploy-dev:\n") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  extends: .stop-deploy-agent")
    error_message = "The generated deploy pipeline must include a stop job using the reusable stop template."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "stop-deploy-dev:\n  extends: .stop-deploy-agent") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  rules:\n    - if: '$CI_COMMIT_BRANCH == \"main\"'\n      when: \"manual\"\n      allow_failure: true")
    error_message = "The generated stop job must inherit the deploy job rule selector and stay manual."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  environment:\n    name: \"dev\"\n    action: stop")
    error_message = "The stop job must mark the GitLab environment as stopped."
  }
}

run "build_ecr_multi_job" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "build_ecr"
            create_merge_request = false
            jobs = [
              {
                name = "build-dev"
                rules = [
                  {
                    if   = "$CI_COMMIT_BRANCH == \"develop\""
                    when = "on_success"
                  },
                ]
                variables = {
                  aws_region       = "eu-central-1"
                  image_repository = "example/platform"
                  image_tags       = ["dev-$CI_COMMIT_SHORT_SHA"]
                  dockerfile_path  = "Dockerfile"
                  build_context    = "."
                }
              },
              {
                name = "build-prod"
                variables = {
                  aws_region       = "eu-central-1"
                  image_repository = "example/platform"
                  image_tags       = ["prod-$CI_COMMIT_SHORT_SHA"]
                  dockerfile_path  = "Dockerfile"
                  build_context    = "."
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = gitlab_repository_file.ci_pipeline["service-one:build_ecr"].file_path == "ci-pipelines/build-gitlab.ci.yaml"
    error_message = "build_ecr must keep its default file path."
  }

  assert {
    condition     = length(regexall("(?m)^include:$", gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content)) == 1
    error_message = "The generated build file must contain exactly one include block."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "  extends: .build-ecr")
    error_message = "ECR build jobs must extend the .build-ecr template."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "\nbuild-dev:\n") && strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "\nbuild-prod:\n")
    error_message = "The generated build file must contain build-dev and build-prod jobs."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "IMAGE_REPOSITORY: \"example/platform\"") && strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "IMAGE_TAGS: \"dev-$CI_COMMIT_SHORT_SHA\"")
    error_message = "Each generated build job must retain its image variables."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "  rules:\n    - if: '$CI_COMMIT_BRANCH == \"develop\"'\n      when: \"on_success\"")
    error_message = "The generated build-dev job must include its configured branch rule."
  }
}

run "build_ecr_without_when" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "build_ecr"
            create_merge_request = false
            jobs = [
              {
                name = "build-dev"
                rules = [
                  {
                    if = "$CI_COMMIT_BRANCH == \"develop\""
                  },
                ]
                variables = {
                  aws_region       = "eu-central-1"
                  image_repository = "example/platform"
                  image_tags       = ["dev-$CI_COMMIT_SHORT_SHA"]
                  dockerfile_path  = "Dockerfile"
                  build_context    = "."
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = !strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "when:")
    error_message = "A rule without when must not render a when block."
  }
}

run "deploy_agent_stop_inherits_when_only_rule" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            stop_environment = {
              enabled = true
            }
            jobs = [
              {
                name = "deploy-dev"
                rules = [
                  {
                    when = "always"
                  },
                ]
                variables = {
                  deploy_environment_name                = "dev"
                  deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
                  deploy_environment_dashboard_namespace = "dev"
                  kube_namespace                         = "dev"
                  helm_release                           = "example-service"
                  helm_chart                             = "dasmeta/base"
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "stop-deploy-dev:\n  extends: .stop-deploy-agent") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  rules:\n    - when: \"manual\"\n      allow_failure: true")
    error_message = "A stop job inherited from a when-only deploy rule must render a valid GitLab CI rules list item."
  }
}

run "reject_stop_environment_without_required_variables" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            stop_environment = {
              enabled = true
            }
            jobs = [
              {
                name = "deploy-dev"
                variables = {
                  kube_namespace = "dev"
                  helm_release   = "example-service"
                }
              },
            ]
          },
        ]
      },
    ]
  }

  expect_failures = [
    var.gitlab_projects,
  ]
}

run "deploy_agent_stop_rule_renders_all_fields" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            jobs = [
              {
                name = "deploy-dev"
                stop_environment = {
                  enabled = true
                  rules = [
                    {
                      if            = "$CI_COMMIT_BRANCH == \"main\""
                      when          = "delayed"
                      allow_failure = true
                      changes       = ["k8s/**"]
                      exists        = ["Chart.yaml"]
                      start_in      = "5 minutes"
                    },
                  ]
                }
                variables = {
                  deploy_environment_name                = "dev"
                  deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
                  deploy_environment_dashboard_namespace = "dev"
                  kube_namespace                         = "dev"
                  helm_release                           = "example-service"
                  helm_chart                             = "dasmeta/base"
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "stop-deploy-dev:\n  extends: .stop-deploy-agent") && strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "      changes:\n        - \"k8s/**\"\n      exists:\n        - \"Chart.yaml\"\n      start_in: \"5 minutes\"")
    error_message = "Stop environment rules must render changes, exists, and start_in fields."
  }
}

run "deploy_agent_environment_without_stop_job" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            jobs = [
              {
                name = "deploy-dev"
                variables = {
                  deploy_environment_name                = "dev"
                  deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
                  deploy_environment_dashboard_namespace = "dev"
                  kube_namespace                         = "dev"
                  helm_release                           = "example-service"
                  helm_chart                             = "dasmeta/base"
                }
              },
            ]
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "  environment:\n    name: \"dev\"\n    kubernetes:") && !strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "    on_stop:") && !strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "    auto_stop_in:") && !strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "\nstop-deploy-dev:\n")
    error_message = "Deploy jobs with environment metadata must render an environment block even when stop_environment is disabled."
  }
}

run "build_target_ecr" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "build"
            target               = "ecr"
            create_merge_request = false
            variables = {
              aws_region       = "eu-central-1"
              image_repository = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/example-service"
            }
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "/ci-templates/templates/build/ecr-build.gitlab-ci.yml")
    error_message = "The ECR build target must include the ECR build template."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_ecr"].content, "AWS_REGION: \"eu-central-1\"")
    error_message = "The ECR build target must render AWS_REGION."
  }
}

run "build_target_onprem" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "build"
            target               = "onprem"
            create_merge_request = false
            variables = {
              registry_host    = "harbor.example.com"
              image_repository = "harbor.example.com/example/example-service"
              image_tags       = ["dev-$CI_COMMIT_SHORT_SHA", "latest"]
            }
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "/ci-templates/templates/build/onprem-build.gitlab-ci.yml")
    error_message = "The on-premises build target must include the on-premises build template."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "REGISTRY_HOST: \"harbor.example.com\"")
    error_message = "The on-premises build target must render REGISTRY_HOST."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "IMAGE_TAGS: \"dev-$CI_COMMIT_SHORT_SHA\\nlatest\"")
    error_message = "The on-premises build target must render all image tags as a newline-delimited string."
  }

  assert {
    condition     = !strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "REGISTRY_PASSWORD") && !strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "REGISTRY_USERNAME")
    error_message = "Generated on-premises pipeline files must not render registry credentials."
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:build_onprem"].content, "  extends: .build-onprem")
    error_message = "On-premises build jobs must extend the .build-onprem template."
  }
}

run "deploy_agent_legacy_single_job" {
  command = plan

  variables {
    project_ids = {
      service-one = 1
    }

    gitlab_projects = [
      {
        name           = "service-one"
        default_branch = "main"
        gitlab_ci_pipelines = [
          {
            type                 = "deploy_agent"
            create_merge_request = false
            job_name             = "deploy"
            variables = {
              deploy_environment_name                = "dev"
              deploy_environment_kubernetes_agent    = "example/platform:eks-agent"
              deploy_environment_dashboard_namespace = "dev"
              kube_namespace                         = "dev"
              helm_release                           = "example-service"
              helm_chart                             = "dasmeta/base"
            }
          },
        ]
      },
    ]
  }

  assert {
    condition     = strcontains(gitlab_repository_file.ci_pipeline["service-one:deploy_agent"].content, "\ndeploy:\n")
    error_message = "The legacy single-job shape must continue to generate its configured job."
  }
}
