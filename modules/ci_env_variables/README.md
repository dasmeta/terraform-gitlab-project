# ci_env_variables

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | >= 18.8.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_project_variable.env](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Same shape as the root module variable gitlab\_projects. | `any` | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Same shape as the root module variable global\_env\_variables. | `any` | n/a | yes |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Map of project name to GitLab project ID (from modules/project). | `map(number)` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
