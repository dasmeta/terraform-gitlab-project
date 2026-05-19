# Quickstart: Dynamic Environments

## 1. Enable the Central Dynamic Environments Project

Add a central project configuration with applications data:

```hcl
dynamic_environments_project = {
  enabled = true

  name      = "example-dynamic-environments"
  group_key = "example"

  deploy_mode = "gitlab_agent"

  gitlab_agent = {
    enabled        = true
    name           = "eks-dev"
    source_branch  = "feature/gitlab-agent-config"
    target_branch  = "main"
    register_agent = true
    # Optional target override; omit to use this dynamic environments project.
    # config_project_name = "service-two"
    # config_project_id   = "123456"
    # config_project_path = "example/service-two"
    install = {
      enabled     = true
      namespace   = "gitlab-agent-eks-dev"
      kas_address = "wss://kas.gitlab.com"
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
      }
    ]
    deployments       = []
  }
}
```

Expected result: Terraform creates or manages the central project and opens a
merge request from `feature/dynamic-environments` to the central project's
default branch containing `config/applications.yaml`, deployment scripts, and
central `.gitlab-ci.yml`.

When `gitlab_agent.enabled = true`, Terraform also opens a merge request in the
configured agent config repository. The default target is the central dynamic
environments project, and the generated file path defaults to
`.gitlab/agents/<agent-name>/config.yaml`.

When `register_agent = true`, Terraform creates the GitLab cluster agent and
token. When `install.enabled = true`, Terraform installs the official
`gitlab/gitlab-agent` Helm chart into the Kubernetes cluster configured on the
Helm provider. The generated token is sensitive and is stored in Terraform
state.

## 2. Opt In a Service Repository

Add per-project dynamic environment settings:

```hcl
gitlab_projects = [
  {
    name      = "backend"
    group_key = "example"

    dynamic_environment = {
      enabled = true
    }
  }
]
```

Expected result: Terraform opens a service repository merge request from
`feature/dynamic-environments` to the service project's default branch with
`ci-pipelines/dynamic-environment.gitlab-ci.yml`.

## 3. Include the Reusable CI File Manually

Review the generated service MR description and add the include snippet to the
service repository's root `.gitlab-ci.yml` when appropriate:

```yaml
include:
  - local: ci-pipelines/dynamic-environment.gitlab-ci.yml
```

## 4. Verify Locally

Run:

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

When GitLab credentials are available, run a plan for the example configuration
and confirm only enabled central/service dynamic environment resources are
present.
