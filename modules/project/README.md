# project

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | 18.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch_protection.branch](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch_protection) | resource |
| [gitlab_project.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project) | resource |
| [gitlab_project_approval_rule.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_approval_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Same structure as the root module input `gitlab_projects` (see root `variables.tf`).<br/>Validated at the root module; this submodule uses `any` to avoid duplicating the full object type. | `any` | n/a | yes |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When true, create one GitLab project per entry in gitlab\_projects. | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_http_url_to_repo"></a> [http\_url\_to\_repo](#output\_http\_url\_to\_repo) | Map of project name to HTTP clone URL. |
| <a name="output_path_with_namespace"></a> [path\_with\_namespace](#output\_path\_with\_namespace) | Map of project name to path\_with\_namespace (e.g. group/repo). |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | Map of GitLab project name (config key) to numeric project ID. |
| <a name="output_ssh_url_to_repo"></a> [ssh\_url\_to\_repo](#output\_ssh\_url\_to\_repo) | Map of project name to SSH clone URL. |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Map of project name to GitLab UI URL. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
