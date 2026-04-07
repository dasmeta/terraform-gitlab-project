# gitlab_group

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
| [gitlab_group.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | When true, create one GitLab group. When false, no resources are created and outputs are null. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Group description. | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Group display name (required when create is true). | `string` | `""` | no |
| <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id) | Optional parent group id for a subgroup. | `number` | `null` | no |
| <a name="input_path"></a> [path](#input\_path) | Group URL path / slug (required when create is true). | `string` | `""` | no |
| <a name="input_visibility_level"></a> [visibility\_level](#input\_visibility\_level) | private \| internal \| public | `string` | `"private"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_full_path"></a> [full\_path](#output\_full\_path) | Group full\_path, or null if not created. |
| <a name="output_id"></a> [id](#output\_id) | GitLab group id (namespace id), or null if not created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
