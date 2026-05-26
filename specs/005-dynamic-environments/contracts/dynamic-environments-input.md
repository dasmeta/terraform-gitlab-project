# Contract: Dynamic Environments Inputs

## Root Input: `dynamic_environments_project`

```hcl
dynamic_environments_project = {
  enabled = true

  name           = "example-dynamic-environments"
  group_key      = "example"
  default_branch = "main"
  deploy_mode    = "gitlab_agent"

  gitlab_agent = {
    enabled          = true
    name             = "eks-dev"
    source_branch    = "feature/gitlab-agent-config"
    target_branch    = "main"
    # Optional target override; omit to use this dynamic environments project.
    # config_project_name = "service-two"
    # config_project_id   = "123456"
    # config_project_path = "example/service-two"
    config_file_path = ".gitlab/agents/eks-dev/config.yaml"
    register_agent   = true

    install = {
      enabled     = true
      namespace   = "gitlab-agent-eks-dev"
      kas_address = "wss://kas.gitlab.com"
    }

    ci_access = {
      projects = [
        { id = "example/example-dynamic-environments" },
        { id = "example/backend" },
        { id = "example/scheduler" },
        { id = "example/pipecat" },
        { id = "example/evals" },
      ]
    }

    user_access = {
      access_as_agent = true
      projects = [
        { id = "example/example-dynamic-environments" },
        { id = "example/backend" },
        { id = "example/talk" },
        { id = "example/scheduler" },
        { id = "example/pipecat" },
        { id = "example/evals" },
      ]
    }
  }

  applications = {
    defaults = {
      aws_region          = "us-east-2"
      secret_env          = "dev"
      base_ref            = "main"
      base_ref_fallbacks  = ["e2e-dynamic", "main", "master"]
      helm_chart          = "dasmeta/base"
      helm_timeout        = "40m"
      dynamic_base_domain = "dev.example.com"
      dynamic_env_release = "app"
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
        release   = "postgres"
        repo_name = "bitnami"
        repo_url  = "https://charts.bitnami.com/bitnami"
        chart     = "bitnami/postgresql"
        version   = "15.5.38"
        values = {
          auth = {
            enablePostgresUser = true
            postgresPassword   = "postgres"
            database           = "app"
          }
          primary = {
            persistence = {
              enabled = false
            }
            resources = {
              requests = {
                cpu    = "200m"
                memory = "512Mi"
              }
              limits = {
                cpu    = "1000m"
                memory = "1Gi"
              }
            }
          }
        }
      }
    ]

    deployments = [
      {
        project        = "example/backend"
        helm_release   = "backend"
        app_component  = "backend"
        helm_version   = "0.3.14"
        db_migration   = true
        helm_overrides = [
          "ingress.hosts[0].host=backend-<DYNAMIC_ENV_HOST>.dev.example.com",
          "config.DO_MIGRATION=true"
        ]
      }
    ]
  }
}
```

Expected behavior:

- `enabled = false` creates no central dynamic environment project resources.
- `applications` renders into `config/applications.yaml`.
- Generated central files are committed to branch
  `feature/dynamic-environments`.
- Central MR targets the central project's `default_branch`.
- When `gitlab_agent.enabled = true`, generated agent config targets the
  central dynamic environments project by default.
- `gitlab_agent.config_project_name`, `config_project_id`,
  `config_project_path`, and `config_file_path` can override the default target.
- `gitlab_agent.ci_access.projects` and `gitlab_agent.user_access.projects`
  render input-driven project access lists in the generated `config.yaml`.
- `deploy_mode = "gitlab_agent"` makes central CI select the GitLab Agent
  context with `kubectl config use-context "$GITLAB_AGENT_PATH"`.
- GitLab Agent registration and Helm install are disabled by default.
- If `register_agent = true`, Terraform creates the GitLab cluster agent and an
  agent token in the configured agent config project.
- If `install.enabled = true`, Terraform installs the `gitlab/gitlab-agent`
  Helm chart with the generated token and configured KAS address.
- The generated token is sensitive, but it is stored in Terraform state when
  registration/install is enabled.

## Per-Project Input: `gitlab_projects[].dynamic_environment`

```hcl
gitlab_projects = [
  {
    name      = "backend"
    group_key = "example"

    dynamic_environment = {
      enabled      = true
      ci_file_path = "ci-pipelines/dynamic-environment.gitlab-ci.yml"
    }
  }
]
```

Expected behavior:

- `enabled = false` or omitted creates no service trigger resources.
- `ci_file_path` defaults to
  `ci-pipelines/dynamic-environment.gitlab-ci.yml`.
- Service MR targets the service project's `default_branch`.
- Root service `.gitlab-ci.yml` remains unchanged by default.
