# Renovate configuration proposals

Used by root gitlab_projects[].renovate.enabled. Creates a dedicated branch and
`renovate.json`, then opens/reuses an MR targeting the project's default branch.
Does not install a worker or merge changes. Existing CI and approval rules remain
in force. No opted-in projects means no resources.

The fixed config enables config:recommended, disables automerge, extends Helm
values matching to values-*.yaml, and enables Kubernetes YAML image detection.
Standard Helm/Docker/Terraform managers apply. Bounded regex/JSONata custom
managers support nonstandard source files; inspect actual extraction with dry-run.
Use include_paths/ignore_paths to restrict coverage and exclude generated files.
Existing Renovate config in other paths must be reconciled before adoption.

A Python 3 API helper is needed because provider 19.0 has no MR creation resource.
Supply GITLAB_API_TOKEN or GITLAB_TOKEN to the Terraform process, using the same
GitLab instance/access as the provider. Missing token/API errors fail apply;
repeat apply retries a failed proposal and reuses an existing open MR.
When no MR is open, it compares the exact renovate.json content on both branches
before creating one, including after squash merges; identical content is a no-op.

Keep the source branch after merge: Terraform owns it and its file. Deleting it
causes Terraform to recreate it. The MR requests remove_source_branch=false.
If a project requires source-branch deletion, reconcile ownership before adoption.
Future configuration changes use that branch; rebase it when required by the
project's fast-forward/CI policy. Disabling opt-in removes Terraform's proposal
resources; it does not remove the already merged config from the default branch.
To stop updates, remove the repository from the bot allowlist or suspend the bot.

Verify using `terraform test` and
`python3 -m unittest discover -s tests -p '*_test.py'`; the latter uses only a local
fake server and fixture credentials. No live GitLab or Kubernetes writes occur.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
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
| [gitlab_branch.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_repository_file.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [null_resource.merge_request](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | GitLab API endpoint for configuration merge requests. | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Projects whose Renovate configuration should be proposed through merge requests. | <pre>list(object({<br/>    name           = string<br/>    default_branch = optional(string, "main")<br/>    renovate = optional(object({<br/>      enabled             = optional(bool, false)<br/>      source_branch       = optional(string, "terraform/renovate")<br/>      merge_request_title = optional(string, "chore: configure Renovate")<br/>      extends             = optional(list(string), ["config:recommended"])<br/>      include_paths       = optional(list(string), [])<br/>      ignore_paths        = optional(list(string), [])<br/>      custom_managers = optional(list(object({<br/>        custom_type           = optional(string, "regex")<br/>        manager_file_patterns = list(string)<br/>        match_strings         = list(string)<br/>        file_format           = optional(string)<br/>        datasource_template   = optional(string)<br/>        dep_name_template     = optional(string)<br/>        package_name_template = optional(string)<br/>        versioning_template   = optional(string)<br/>        registry_url_template = optional(string)<br/>      })), [])<br/>    }), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Managed project IDs indexed by gitlab\_projects[].name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configurations"></a> [configurations](#output\_configurations) | Generated nonsecret Renovate repository configurations indexed by project name. |
| <a name="output_source_branches"></a> [source\_branches](#output\_source\_branches) | Branches holding configuration proposals; retained after merge for Terraform ownership. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
