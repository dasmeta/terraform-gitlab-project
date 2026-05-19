# basic

This example demonstrates the supported multi-group workflow:

- each project resolves its namespace through an explicit `group_key`
- each group is in managed-group mode with `create = true`
- project-level `env_variables` can replace a shared variable definition by
  reusing the same key
- `dynamic_environments_project` can create a central orchestration repository
  and open a merge request with generated dynamic environment files
- `dynamic_environments_project.gitlab_agent` can generate
  `.gitlab/agents/<agent-name>/config.yaml` in the central dynamic environments
  project by default, with the target repository/path still configurable
- `dynamic_environments_project.gitlab_agent.install.enabled = true` uses the
  example Helm provider configuration to deploy the official GitLab Agent chart
  into the current Kubernetes cluster context
- `gitlab_projects[].dynamic_environment.enabled = true` can opt a service
  repository into a generated reusable CI trigger file and merge request
- field-level defaults and behavioral notes are documented inline in the root
  `variables.tf` schema rather than in a detached shared prose block

Use this example when you want multiple repositories spread across multiple
GitLab groups. If you have exactly one group, the root module also supports the
implicit single-group fallback described in the root README.

Dynamic environment merge request creation uses the GitLab API from Terraform's
local execution environment because the GitLab Terraform provider does not
currently expose a merge-request creation resource. Set `GITLAB_TOKEN` or
`GITLAB_API_TOKEN` before `terraform apply` when this feature is enabled.

GitLab Agent installation uses the Helm provider and the local kubeconfig by
default. For EKS, connect the local kubeconfig before applying:

```sh
aws eks update-kubeconfig --region us-east-2 --name eks-dev
terraform init
terraform apply
```

Override `kubeconfig_path` or `kubeconfig_context` if you do not want to use the
current kubeconfig context. When `gitlab_agent.register_agent` and
`gitlab_agent.install.enabled` are true, Terraform creates a sensitive GitLab
Agent token and stores it in Terraform state so Helm can use it as
`config.token`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubeconfig_context"></a> [kubeconfig\_context](#input\_kubeconfig\_context) | Optional kubeconfig context used by the Helm provider. Leave null to use the current context. | `string` | `null` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig path used by the Helm provider to install the GitLab Agent chart. | `string` | `"~/.kube/config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab"></a> [gitlab](#output\_gitlab) | All outputs from the terraform-gitlab-project module (gitlab\_group\_ids, gitlab\_project\_ids, …). |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubeconfig_context"></a> [kubeconfig\_context](#input\_kubeconfig\_context) | Optional kubeconfig context used by the Helm provider. Leave null to use the current context. | `string` | `"kind-gitlab-agent-dev"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig path used by the Helm provider to install the GitLab Agent chart. | `string` | `"~/.kube/config"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab"></a> [gitlab](#output\_gitlab) | All outputs from the terraform-gitlab-project module (gitlab\_group\_ids, gitlab\_project\_ids, …). |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
