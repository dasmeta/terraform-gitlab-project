# seperate_gitlab_agent

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | = 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab_agent_prod"></a> [gitlab\_agent\_prod](#module\_gitlab\_agent\_prod) | ../../modules/gitlab_agent_config | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubeconfig_context"></a> [kubeconfig\_context](#input\_kubeconfig\_context) | Optional kubeconfig context used by the Helm provider. Leave null to use the current context. | `string` | `"kind-gitlab-agent-dev"` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig path used by the Helm provider to install the GitLab Agent chart. | `string` | `"~/.kube/config"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
