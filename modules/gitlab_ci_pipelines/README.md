# GitLab CI Pipelines

Creates opt-in reusable GitLab CI pipeline files inside managed projects.

Supported pipeline types are:

- `build` with `target = "ecr"` or `target = "onprem"`, which creates
  `ci-pipelines/build-gitlab.ci.yaml`
- `build_ecr`, retained as a compatibility alias for existing consumers
- `deploy_agent`, which creates `ci-pipelines/deploy.gitlab-ci.yml`

Each generated file includes its shared reusable template from
`das-meta/gitlab-ci-templates`. A build or deploy entry may define multiple
jobs in one generated file; each job extends the hidden template job with its
own variables. When `jobs` is omitted, the legacy `job_name` and `variables`
fields still generate one job. Each job may also define ordered GitLab CI
`rules` using `if`, `when`, `allow_failure`, `changes`, `exists`, and
`start_in`.

New pipeline types should be added through `local.pipeline_types` in `main.tf`.
Each entry owns its include target, default generated file path, default job
name, default variables, and the mapping from Terraform snake_case variable keys
to GitLab CI variable names.

Select ECR with:

```hcl
{
  type   = "build"
  target = "ecr"
  variables = {
    aws_region       = "eu-central-1"
    image_repository = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/example-service"
  }
}
```

Select Harbor or Docker Hub with:

```hcl
{
  type   = "build"
  target = "onprem"
  variables = {
    registry_host    = "harbor.example.com"
    image_repository = "harbor.example.com/example/example-service"
    image_tags       = ["$CI_COMMIT_SHORT_SHA", "latest"]
  }
}
```

`image_tags` is a list of strings. Each configured value is pushed as a
separate tag for the same image.

The on-premises template reads `REGISTRY_USERNAME` and `REGISTRY_PASSWORD`
from GitLab CI/CD variables. Manage them as masked and protected project
variables rather than putting credentials in the generated pipeline:

```hcl
env_variables = [
  {
    key       = "REGISTRY_USERNAME"
    value     = var.registry_username
    masked    = true
    protected = true
  },
  {
    key       = "REGISTRY_PASSWORD"
    value     = var.registry_password
    masked    = true
    protected = true
  },
]
```

Example generated shape:

```yaml
include:
  - project: das-meta/gitlab-ci-templates
    ref: DMVP-1150
    file: /ci-templates/templates/build/ecr-build.gitlab-ci.yml

build:
  extends: .build-ecr
  variables:
    AWS_REGION: "us-east-1"
    IMAGE_REPOSITORY: "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-service"
    IMAGE_TAGS: "$CI_COMMIT_SHORT_SHA"
    DOCKERFILE_PATH: "Dockerfile"
    BUILD_CONTEXT: "."
```

Example generated build wrapper:

```yaml
include:
  - project: das-meta/gitlab-ci-templates
    ref: DMVP-1150
    file: /ci-templates/templates/build/ecr-build.gitlab-ci.yml

build-dev:
  extends: .build-ecr
  variables:
    AWS_REGION: "us-east-1"
    IMAGE_REPOSITORY: "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-service"
    IMAGE_TAGS: "dev-$CI_COMMIT_SHORT_SHA"
    DOCKERFILE_PATH: "Dockerfile"
    BUILD_CONTEXT: "."
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'
      when: on_success

build-prod:
  extends: .build-ecr
  variables:
    AWS_REGION: "us-east-1"
    IMAGE_REPOSITORY: "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-service"
    IMAGE_TAGS: "prod-$CI_COMMIT_SHORT_SHA\nlatest"
    DOCKERFILE_PATH: "Dockerfile"
    BUILD_CONTEXT: "."
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual
```

Example generated deploy wrapper:

```yaml
include:
  - project: das-meta/gitlab-ci-templates
    ref: DMVP-1150
    file: /ci-templates/templates/deploy/agent-deploy.gitlab-ci.yml

deploy-dev:
  extends: .deploy-agent
  variables:
    DEPLOY_ENVIRONMENT_NAME: "dev"
    DEPLOY_ENVIRONMENT_KUBERNETES_AGENT: "example/platform:eks-agent"
    DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE: "dev"
    KUBE_NAMESPACE: "dev"
    KUBE_NAMESPACE_CREATE: "true"
    HELM_RELEASE: "example-service"
    HELM_CHART: "dasmeta/base"
    HELM_WAIT: "true"
    HELM_TIMEOUT: "40m"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: on_success

deploy-prod:
  extends: .deploy-agent
  variables:
    DEPLOY_ENVIRONMENT_NAME: "prod"
    DEPLOY_ENVIRONMENT_KUBERNETES_AGENT: "example/platform:eks-agent"
    DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE: "prod"
    KUBE_NAMESPACE: "prod"
    KUBE_NAMESPACE_CREATE: "true"
    HELM_RELEASE: "example-service"
    HELM_CHART: "dasmeta/base"
    HELM_WAIT: "true"
    HELM_TIMEOUT: "40m"
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | ~> 19.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | ~> 19.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.ci_pipeline](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_repository_file.ci_pipeline](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [null_resource.ci_pipeline_merge_request](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Same normalized shape as the root module variable gitlab\_projects, including gitlab\_ci\_pipelines entries. | `any` | n/a | yes |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Map of project name to GitLab project ID (from modules/project). | `map(number)` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
