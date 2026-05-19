# dynamic_environment

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | >= 18.8.2 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.dynamic_environment_central](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_branch.dynamic_environment_service](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_project.dynamic_environment](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project) | resource |
| [gitlab_repository_file.dynamic_environment_central](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [gitlab_repository_file.dynamic_environment_service](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [null_resource.dynamic_environment_central_mr](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.dynamic_environment_service_mr](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamic_environments_project"></a> [dynamic\_environments\_project](#input\_dynamic\_environments\_project) | Normalized central dynamic environments project configuration from the root module. | `any` | n/a | yes |
| <a name="input_gitlab_agent_path"></a> [gitlab\_agent\_path](#input\_gitlab\_agent\_path) | Effective GitLab Agent context path referenced by generated dynamic environment CI. | `string` | `""` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Normalized GitLab project objects from the root module. | `any` | n/a | yes |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Map of service project names to GitLab project IDs from the project submodule. | `map(string)` | n/a | yes |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When false, dynamic environment project and service resources are skipped. | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_agent_path"></a> [gitlab\_agent\_path](#output\_gitlab\_agent\_path) | GitLab Agent context path referenced by generated dynamic environment CI. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | GitLab project ID for the central dynamic environments project when enabled. |
| <a name="output_project_path"></a> [project\_path](#output\_project\_path) | Path with namespace for the central dynamic environments project when enabled. |
| <a name="output_service_ci_file_paths"></a> [service\_ci\_file\_paths](#output\_service\_ci\_file\_paths) | Map of service project name to generated dynamic environment CI trigger file path. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
