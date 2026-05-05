# terraform-gitlab-project

## Supported Configuration Paths

- Choose exactly one namespace-selection path per project:
  - set `namespace_id` directly, or
  - set `group_key` to a declared `gitlab_groups` entry, or
  - omit both only when exactly one `gitlab_groups` entry exists and you want
    the implicit single-group fallback
- Do not set `namespace_id` and `group_key` together on the same project.
- Declare each `gitlab_groups` entry in one of two modes:
  - managed group: `create = true` with `name` and `path`
  - existing group reference: `create = false` with `existing_group_id`
- Project `env_variables` override `global_env_variables` by key, and the
  project-level entry replaces the full shared definition for that key.
- `projects_enabled = false` skips projects and project-scoped child resources,
  but still allows managed groups to be created.
- Field-level defaults, allowed values, and behavior notes now live inline next
  to the owning attributes in `variables.tf` instead of a separate shared
  project-field description block.
- Existing consumers can keep using the documented single-group fallback; this
  clarification pass does not expand the module into runners, Kubernetes, or
  other unrelated GitLab platform areas.

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
| <a name="input_gitlab_groups"></a> [gitlab\_groups](#input\_gitlab\_groups) | GitLab groups for this module (each entry needs a unique "key"). Each entry must be one of two supported modes:<br/>- managed group: set create = true and provide name + path<br/>- existing group reference: set create = false and provide existing\_group\_id<br/><br/>Projects may resolve their namespace through group\_key, or by the implicit single-group fallback when exactly one<br/>gitlab\_groups entry exists. If this list is empty, every gitlab\_projects item must set namespace\_id directly. | <pre>list(object({<br/>    key               = string                      # Stable id for wiring group_key on projects<br/>    create            = optional(bool, false)       # Create group via API for this entry<br/>    name              = optional(string)            # Display name (required if create is true)<br/>    path              = optional(string)            # URL path (required if create is true)<br/>    description       = optional(string, "")        # Group description<br/>    visibility_level  = optional(string, "private") # private | internal | public<br/>    parent_id         = optional(number)            # Parent namespace id for subgroups<br/>    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true<br/>  }))</pre> | `[]` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | List of GitLab project configurations.<br/><br/>Supported namespace selection paths:<br/>- set namespace\_id directly<br/>- set group\_key to select an entry from var.gitlab\_groups<br/>- omit both namespace\_id and group\_key only when exactly one gitlab\_groups entry exists; that single group is used implicitly<br/><br/>Do not set namespace\_id and group\_key together on the same project.<br/>When gitlab\_groups is empty, set namespace\_id on every project.<br/><br/>Merge behavior (per project; GitLab UI under Settings → Merge requests):<br/><br/>squash\_option — Squash commits when merging:<br/>  - never        → Do not allow (squash disabled; checkbox hidden)<br/>  - default\_off  → Allow (checkbox visible, off by default)<br/>  - default\_on   → Encourage (checkbox visible, on by default)<br/>  - always       → Require (always squash; user cannot disable)<br/><br/>merge\_method — Merge method:<br/>  - merge        → Create a merge commit<br/>  - rebase\_merge → Merge commit with semi-linear history<br/>  - ff           → Fast-forward merge<br/><br/>branch\_protections — Optional list per project: Settings → Repository → Protected branches.<br/>When omitted or set to [], this module creates one default protection for branch "main".<br/>Access is only via merge\_access\_level / push\_access\_level (maintainer, developer, admin, no one).<br/>Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab\_branch\_protection.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>When omitted or set to [], no project approval rule resources are created.<br/>Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>prevent\_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent\_destroy } from this field (dynamic lifecycle is not supported for count/for\_each resources in the same way as static blocks).<br/><br/>ci\_pipeline\_variables\_minimum\_override\_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).<br/>Valid values: no\_one\_allowed, developer, maintainer, owner. Default in type: maintainer.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>If present and non-empty, the module creates one GitLab approval rule resource<br/>per list entry. Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>env\_variables — Per-project CI/CD variables (gitlab\_project\_variable via module ci\_env\_variables), merged with<br/>var.global\_env\_variables; the same key on the project replaces the full global variable definition for that project. | <pre>list(object({<br/>    name                                             = string                         # Project name / slug key used by child resources<br/>    description                                      = optional(string)               # Project description<br/>    visibility_level                                 = optional(string, "private")    # private | internal | public<br/>    default_branch                                   = optional(string, "develop")    # Initial default branch name<br/>    initialize_with_readme                           = optional(bool, true)           # Create repository with README<br/>    request_access_enabled                           = optional(bool, true)           # Allow users to request access<br/>    prevent_destroy                                  = optional(bool, true)           # Contract hint only; not mapped to Terraform lifecycle<br/>    namespace_id                                     = optional(number)               # Explicit GitLab namespace id for the project<br/>    group_key                                        = optional(string)               # Resolve namespace through gitlab_groups[].key<br/>    lfs_enabled                                      = optional(bool, true)           # Enable Git LFS for the project<br/>    packages_enabled                                 = optional(bool, true)           # Enable GitLab package registry<br/>    squash_option                                    = optional(string, "default_on") # never | default_off | default_on | always<br/>    merge_method                                     = optional(string, "merge")      # merge | rebase_merge | ff<br/>    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)           # Require successful pipeline before merge<br/>    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)           # Require resolved discussions before merge<br/>    remove_source_branch_after_merge                 = optional(bool, true)           # Auto-delete source branch after merge<br/>    ci_pipeline_variables_minimum_override_role      = optional(string, "developer")  # no_one_allowed | developer | maintainer | owner<br/>    pages_access_level                               = optional(string, "private")    # GitLab Pages visibility level<br/>    suggestion_commit_message                        = optional(string)               # Suggested squash commit message template<br/>    merge_commit_template                            = optional(string)               # Merge commit message template<br/>    branch_protections = optional(list(object({<br/>      branch                       = string                         # Protected branch name<br/>      merge_access_level           = optional(string, "maintainer") # Merge access role<br/>      push_access_level            = optional(string, "maintainer") # Push access role<br/>      allow_force_push             = optional(bool, false)          # Allow force-push on the branch<br/>      code_owner_approval_required = optional(bool, false)          # Require code-owner approval<br/>      unprotect_access_level       = optional(string, "maintainer") # Unprotect access role<br/>    })), [])<br/>    approval_rule = optional(list(object({<br/>      name                              = optional(string, "Approval rule") # Approval rule display name<br/>      approvals_required                = optional(number, 1)               # Number of approvals required<br/>      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches<br/>      user_ids                          = optional(list(number))            # Explicit approver user ids<br/>      group_ids                         = optional(list(number))            # Explicit approver group ids<br/>    })), [])<br/>    push_rules = optional(list(any), []) # Provider-shaped push rules consumed by gitlab_project.push_rules<br/>    env_variables = optional(list(object({<br/>      key       = string                # CI/CD variable name<br/>      value     = string                # CI/CD variable value<br/>      masked    = optional(bool, false) # Hide value in logs / UI where supported<br/>      protected = optional(bool, false) # Restrict variable to protected refs<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Environment variables applied to every GitLab project. Use for shared NPM\_TOKEN, GITLAB\_TOKEN, etc. | <pre>list(object({<br/>    key       = string                # CI/CD variable name<br/>    value     = string                # Variable value (use masked for secrets)<br/>    masked    = optional(bool, false) # Hide value in job logs / UI where supported<br/>    protected = optional(bool, false) # Available only on protected branches/tags<br/>  }))</pre> | `[]` | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab\_groups[].create is true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_group_full_paths"></a> [gitlab\_group\_full\_paths](#output\_gitlab\_group\_full\_paths) | Map of group key to full\_path for groups created by this module (Terraform-managed only; existing groups referenced via existing\_group\_id are not listed here). |
| <a name="output_gitlab_group_ids"></a> [gitlab\_group\_ids](#output\_gitlab\_group\_ids) | Map of group key (from gitlab\_groups) to namespace id for every resolvable configured group — managed groups contribute their created id and existing-group references require existing\_group\_id. |
| <a name="output_gitlab_project_ids"></a> [gitlab\_project\_ids](#output\_gitlab\_project\_ids) | Map of GitLab project name to project ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
