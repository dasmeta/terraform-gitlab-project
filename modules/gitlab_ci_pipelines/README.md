# GitLab CI Pipelines

Creates opt-in reusable GitLab CI pipeline files inside managed projects.

Supported pipeline types are:

- `build_ecr`, which creates `ci-pipelines/build-gitlab.ci.yaml`
- `deploy_agent`, which creates `ci-pipelines/deploy-gitlab.ci.yaml`

Each generated file includes its shared reusable template from
`das-meta/gitlab-ci-templates` and defines a concrete job that extends the
hidden template job with project-specific variables.

New pipeline types should be added through `local.pipeline_types` in `main.tf`.
Each entry owns its include target, default generated file path, default job
name, default variables, and the mapping from Terraform snake_case variable keys
to GitLab CI variable names.

Example generated shape:

```yaml
include:
  - project: das-meta/gitlab-ci-templates
    ref: DMVP-1150
    file: /ci-templates/templates/build/ecr-buildx.gitlab-ci.yml

build:
  extends: .build
  variables:
    AWS_REGION: "us-east-1"
    IMAGE_REPOSITORY: "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-service"
    IMAGE_TAG: "$CI_COMMIT_SHORT_SHA"
    DOCKERFILE_PATH: "Dockerfile"
    BUILD_CONTEXT: "."
```

Example generated deploy wrapper:

```yaml
include:
  - project: das-meta/gitlab-ci-templates
    ref: DMVP-1150
    file: /ci-templates/templates/deploy/agent-deploy.gitlab-ci.yml

deploy:
  extends: .deploy
  variables:
    DEPLOY_ENVIRONMENT_NAME: "dev"
    DEPLOY_ENVIRONMENT_KUBERNETES_AGENT: "example/platform:eks-agent"
    DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE: "example-service"
    KUBE_NAMESPACE: "example-service"
    KUBE_NAMESPACE_CREATE: "true"
    HELM_RELEASE: "example-service"
    HELM_CHART: "dasmeta/base"
    HELM_WAIT: "true"
    HELM_TIMEOUT: "40m"
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
