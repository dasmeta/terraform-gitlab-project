# terraform-gitlab-project

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ci_env_variables"></a> [ci\_env\_variables](#module\_ci\_env\_variables) | ./modules/ci_env_variables | n/a |
| <a name="module_gitlab_group"></a> [gitlab\_group](#module\_gitlab\_group) | ./modules/gitlab_group | n/a |
| <a name="module_project"></a> [project](#module\_project) | ./modules/project | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_groups"></a> [gitlab\_groups](#input\_gitlab\_groups) | GitLab groups for this module (each entry needs a unique "key"). Set group\_key on each gitlab\_projects item to choose a group,<br/>or set namespace\_id on the project. With more than one entry here, every project must set group\_key or namespace\_id.<br/>For create = false, set existing\_group\_id to the GitLab group's id so projects with matching group\_key resolve there.<br/>If this list is empty, every gitlab\_projects item must set namespace\_id. | <pre>list(object({<br/>    key               = string                      # Stable id for wiring group_key on projects<br/>    create            = optional(bool, false)       # Create group via API for this entry<br/>    name              = optional(string)            # Display name (required if create is true)<br/>    path              = optional(string)            # URL path (required if create is true)<br/>    description       = optional(string, "")        # Group description<br/>    visibility_level  = optional(string, "private") # private | internal | public<br/>    parent_id         = optional(number)            # Parent namespace id for subgroups<br/>    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true<br/>  }))</pre> | `[]` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | List of GitLab project configurations. Use group\_key to select a namespace from var.gitlab\_groups (must match an entry's key),<br/>or set namespace\_id. If gitlab\_groups is non-empty, omitting group\_key uses the first entry. If gitlab\_groups is empty,<br/>set namespace\_id on every project.<br/><br/>Merge behavior (per project; GitLab UI under Settings → Merge requests):<br/><br/>squash\_option — Squash commits when merging:<br/>  - never        → Do not allow (squash disabled; checkbox hidden)<br/>  - default\_off  → Allow (checkbox visible, off by default)<br/>  - default\_on   → Encourage (checkbox visible, on by default)<br/>  - always       → Require (always squash; user cannot disable)<br/><br/>merge\_method — Merge method:<br/>  - merge        → Create a merge commit<br/>  - rebase\_merge → Merge commit with semi-linear history<br/>  - ff           → Fast-forward merge<br/><br/>branch\_protections — Optional list per project: Settings → Repository → Protected branches.<br/>When omitted or set to [], this module creates one default protection for branch "main".<br/>Access is only via merge\_access\_level / push\_access\_level (maintainer, developer, admin, no one).<br/>Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab\_branch\_protection.<br/><br/>approval\_rule — Optional per project. Accepts either one approval rule object or a list of approval rule objects.<br/>Disabled entries are ignored. Defaults are enabled = false, name = "Approval rule",<br/>approvals\_required = 1, applies\_to\_all\_protected\_branches = false;<br/>enable the resource with enabled = true (user\_ids / group\_ids optional; omit for GitLab default approvers).<br/><br/>prevent\_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent\_destroy } from this field (dynamic lifecycle is not supported for count/for\_each resources in the same way as static blocks).<br/><br/>ci\_pipeline\_variables\_minimum\_override\_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).<br/>Valid values: no\_one\_allowed, developer, maintainer, owner. Default in type: maintainer.<br/><br/>approval\_rule — Optional per project. Accepts either one approval rule object or a list of approval rule objects.<br/>If present, the module creates the rule or rules. Defaults are name = "Approval rule",<br/>approvals\_required = 1, applies\_to\_all\_protected\_branches = false<br/>(user\_ids / group\_ids optional; omit for GitLab default approvers).<br/><br/>env\_variables — Per-project CI/CD variables (gitlab\_project\_variable via module ci\_env\_variables), merged with<br/>var.global\_env\_variables; the same key on the project overrides the global value. | `any` | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Environment variables applied to every GitLab project. Use for shared NPM\_TOKEN, GITLAB\_TOKEN, etc. | <pre>list(object({<br/>    key       = string                # CI/CD variable name<br/>    value     = string                # Variable value (use masked for secrets)<br/>    masked    = optional(bool, false) # Hide value in job logs / UI where supported<br/>    protected = optional(bool, false) # Available only on protected branches/tags<br/>  }))</pre> | `[]` | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab\_groups[].create is true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_group_full_paths"></a> [gitlab\_group\_full\_paths](#output\_gitlab\_group\_full\_paths) | Map of group key to full\_path for groups created by this module (Terraform-managed only; existing groups referenced via existing\_group\_id are not listed here). |
| <a name="output_gitlab_group_ids"></a> [gitlab\_group\_ids](#output\_gitlab\_group\_ids) | Map of group key (from gitlab\_groups) to namespace id — use this for every group instead of a separate 'first group' id. |
| <a name="output_gitlab_project_ids"></a> [gitlab\_project\_ids](#output\_gitlab\_project\_ids) | Map of GitLab project name to project ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
