# gitlab_agent_config

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | = 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | = 18.8.2 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.17.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.this](https://registry.terraform.io/providers/gitlabhq/gitlab/18.8.2/docs/resources/branch) | resource |
| [gitlab_cluster_agent.this](https://registry.terraform.io/providers/gitlabhq/gitlab/18.8.2/docs/resources/cluster_agent) | resource |
| [gitlab_cluster_agent_token.this](https://registry.terraform.io/providers/gitlabhq/gitlab/18.8.2/docs/resources/cluster_agent_token) | resource |
| [gitlab_repository_file.this](https://registry.terraform.io/providers/gitlabhq/gitlab/18.8.2/docs/resources/repository_file) | resource |
| [helm_release.gitlab_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.merge_request](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_central_project_id"></a> [central\_project\_id](#input\_central\_project\_id) | GitLab project ID for the generated central dynamic environments project. | `string` | `null` | no |
| <a name="input_central_project_path"></a> [central\_project\_path](#input\_central\_project\_path) | Path with namespace for the generated central dynamic environments project. | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name used as the default GitLab Agent name. | `string` | `"eks-dev"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | When true, generates GitLab Agent config in the configured repository. | `bool` | `false` | no |
| <a name="input_gitlab_agent"></a> [gitlab\_agent](#input\_gitlab\_agent) | GitLab Agent config generation settings from dynamic\_environments\_project.gitlab\_agent. | `any` | `{}` | no |
| <a name="input_gitlab_api_url"></a> [gitlab\_api\_url](#input\_gitlab\_api\_url) | GitLab API URL used by the merge request local-exec helper. | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Map of managed project names to GitLab project IDs. | `map(string)` | `{}` | no |
| <a name="input_project_paths"></a> [project\_paths](#input\_project\_paths) | Map of managed project names to GitLab path\_with\_namespace values. | `map(string)` | `{}` | no |
| <a name="input_service_project_paths"></a> [service\_project\_paths](#input\_service\_project\_paths) | Enabled service project paths that should receive default GitLab Agent CI access. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_path"></a> [agent\_path](#output\_agent\_path) | GitLab Agent context path in <config-project-path>:<agent-name> format. |
| <a name="output_cluster_agent_id"></a> [cluster\_agent\_id](#output\_cluster\_agent\_id) | Registered GitLab Agent ID when registration is enabled. |
| <a name="output_cluster_agent_token_id"></a> [cluster\_agent\_token\_id](#output\_cluster\_agent\_token\_id) | GitLab Agent token ID when registration is enabled. |
| <a name="output_config_file_path"></a> [config\_file\_path](#output\_config\_file\_path) | Generated GitLab Agent config file path when enabled. |
| <a name="output_config_project_id"></a> [config\_project\_id](#output\_config\_project\_id) | GitLab project ID where the GitLab Agent config is generated when enabled. |
| <a name="output_config_yaml"></a> [config\_yaml](#output\_config\_yaml) | Rendered GitLab Agent config.yaml content. |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Helm release name for the installed GitLab Agent when install is enabled. |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Kubernetes namespace for the installed GitLab Agent when install is enabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
