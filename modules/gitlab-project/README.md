

# gitlab_project

## Configuration of provider
```bash

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">3.0.0"
    }
  }
}

provider "gitlab" {
  token = ""  // your gitlab Personal access token
}

```
## Minimal example of module

```terraform
module "gitlab_project" {
  source  = "dasmeta/project/gitlab//modules/gitlab-project"
  version = "1.1.0"

  name                      = "test-project"
  description               = "Some test project"
  initialize_with_readme    = true
  visibility_level          = "public"
  approvals_before_merge    = 1
  default_branch            = main
  merge_method              = "ff"   <!-- `ff` to create fast-forward merges. Valid values are `merge`, `rebase_merge`, `ff`." -->
}
```

## Some other example of usage to create variable

```terraform
module "gitlab_project" {
  source  = "dasmeta/project/gitlab//modules/gitlab-project"
  version = "1.1.0"

  name                                             = "test-project"
  description                                      = "Some test project"
  visibility_level                                 = "private"
  create_variable                                  = true
  only_allow_merge_if_all_discussions_are_resolved = true
  only_allow_merge_if_pipeline_succeeds            = true
  remove_source_branch_after_merge                 = true
  project_variable_key                             = "project_variable_key"
  project_variable_value                           = "project_variable_value"  
  masked                                           = true
  protected                                        = true

}
```

## Some other example of usage with createing webhook, pipline, branch

```terraform
module "gitlab_project" {
  source  = "dasmeta/project/gitlab//modules/gitlab-project"
  version = "1.1.0"

  name                                             = "test-project"
  description                                      = "Some test project"
  visibility_level                                 = "private"
  create_webhook                                   = true
  url                                              = "https://xxx.xxx"
  confidential_issues_events                       = true
  enable_ssl_verification                          = true
  create_pipline                                   = true
  create_branch                                    = true
  job_events                                       = true
  pipeline_events                                  = true
  push_events                                      = true
  token                                            = true
  ref                                              = "main"
  cron                                             = "0 1 * * *"
  pipline_schedule_key                             = "EXAMPLE_KEY
  pipline_schedule_value                           = "EXAMPLE_VALUE"
  branch_name                                      = "das-meta"

}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.branch](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_branch_protection.branch_protection](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/branch_protection) | resource |
| [gitlab_pipeline_schedule.pipline_schedule](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/pipeline_schedule) | resource |
| [gitlab_pipeline_schedule_variable.pipline_schedule_variable](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/pipeline_schedule_variable) | resource |
| [gitlab_pipeline_trigger.pipline_trigger](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/pipeline_trigger) | resource |
| [gitlab_project.this](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/project) | resource |
| [gitlab_project_hook.project_webhook](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/project_hook) | resource |
| [gitlab_project_variable.project_variable](https://registry.terraform.io/providers/hashicorp/gitlab/latest/docs/resources/project_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active"></a> [active](#input\_active) | (Boolean) The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially. | `bool` | `false` | no |
| <a name="input_approvals_before_merge"></a> [approvals\_before\_merge](#input\_approvals\_before\_merge) | (Optional) Number of merge request approvals required for merging. Default is 0. | `string` | `1` | no |
| <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name) | (String) The name for this branch. | `string` | `"develop"` | no |
| <a name="input_confidential_issues_events"></a> [confidential\_issues\_events](#input\_confidential\_issues\_events) | (Boolean) Invoke the hook for confidential issues events. | `bool` | `false` | no |
| <a name="input_confidential_note_events"></a> [confidential\_note\_events](#input\_confidential\_note\_events) | (Boolean) Invoke the hook for confidential notes events. | `bool` | `false` | no |
| <a name="input_create"></a> [create](#input\_create) | Boolean to create the resource. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_branch"></a> [create\_branch](#input\_create\_branch) | Boolean to create the branch. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_pipline"></a> [create\_pipline](#input\_create\_pipline) | Boolean to create the pipline. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_variable"></a> [create\_variable](#input\_create\_variable) | Boolean to create the resource variable. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_webhook"></a> [create\_webhook](#input\_create\_webhook) | Boolean to create the webhook. Defaults to true. | `bool` | `true` | no |
| <a name="input_cron"></a> [cron](#input\_cron) | (String) The cron (e.g. 0 1 * * *). | `string` | `"0 1 * * *"` | no |
| <a name="input_default_branch"></a> [default\_branch](#input\_default\_branch) | (Optional) The default branch the repository will use. Defaults to main. | `string` | `"main"` | no |
| <a name="input_deployment_events"></a> [deployment\_events](#input\_deployment\_events) | (Boolean) Invoke the hook for deployment events. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) A description of the project. | `string` | `"Repository for testing"` | no |
| <a name="input_enable_ssl_verification"></a> [enable\_ssl\_verification](#input\_enable\_ssl\_verification) | (Boolean) Enable ssl verification when invoking the hook. | `bool` | `false` | no |
| <a name="input_initialize_with_readme"></a> [initialize\_with\_readme](#input\_initialize\_with\_readme) | (Optional) Create main branch with first commit containing a README.md file. | `bool` | `false` | no |
| <a name="input_issues_events"></a> [issues\_events](#input\_issues\_events) | (Boolean) Invoke the hook for issues events. | `bool` | `false` | no |
| <a name="input_job_events"></a> [job\_events](#input\_job\_events) | (Boolean) Invoke the hook for job events. | `bool` | `false` | no |
| <a name="input_lfs_enabled"></a> [lfs\_enabled](#input\_lfs\_enabled) | (Optional) Enable LFS for the project. | `bool` | `false` | no |
| <a name="input_masked"></a> [masked](#input\_masked) | (Boolean) If set to true, the value of the variable will be hidden in job logs. The value must meet the masking requirements. Defaults to false. | `bool` | `false` | no |
| <a name="input_merge_access_level"></a> [merge\_access\_level](#input\_merge\_access\_level) | (String) Access levels allowed to merge. Valid values are: no one, developer, maintainer. | `string` | `"maintainer"` | no |
| <a name="input_merge_method"></a> [merge\_method](#input\_merge\_method) | (Optional) Set to `ff` to create fast-forward merges. Valid values are `merge`, `rebase_merge`, `ff`. | `string` | `"ff"` | no |
| <a name="input_merge_requests_events"></a> [merge\_requests\_events](#input\_merge\_requests\_events) | (Boolean) Invoke the hook for merge requests. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the project to be created | `string` | n/a | yes |
| <a name="input_only_allow_merge_if_all_discussions_are_resolved"></a> [only\_allow\_merge\_if\_all\_discussions\_are\_resolved](#input\_only\_allow\_merge\_if\_all\_discussions\_are\_resolved) | (Optional) Set to true if you want to allow merges only if all discussions are resolved. | `bool` | `true` | no |
| <a name="input_only_allow_merge_if_pipeline_succeeds"></a> [only\_allow\_merge\_if\_pipeline\_succeeds](#input\_only\_allow\_merge\_if\_pipeline\_succeeds) | (Optional) Set to true if you want to allow merges only if a pipeline succeeds. | `bool` | `true` | no |
| <a name="input_packages_enabled"></a> [packages\_enabled](#input\_packages\_enabled) | (Optional) Enable packages repository for the project. | `bool` | `false` | no |
| <a name="input_pages_access_level"></a> [pages\_access\_level](#input\_pages\_access\_level) | (Optional) Enable pages access control. Valid values are `disabled`, `private`, `enabled`, `public`. | `string` | `"private"` | no |
| <a name="input_pipeline_events"></a> [pipeline\_events](#input\_pipeline\_events) | (Boolean) Invoke the hook for pipeline events. | `bool` | `false` | no |
| <a name="input_pipline_schedule_key"></a> [pipline\_schedule\_key](#input\_pipline\_schedule\_key) | (String) Name of the variable. | `string` | `"EXAMPLE_KEY"` | no |
| <a name="input_pipline_schedule_value"></a> [pipline\_schedule\_value](#input\_pipline\_schedule\_value) | (String) Value of the variable. | `string` | `"EXAMPLE_VALUE"` | no |
| <a name="input_pipline_trigger_description"></a> [pipline\_trigger\_description](#input\_pipline\_trigger\_description) | (String) The description of the pipeline trigger. | `string` | `""` | no |
| <a name="input_project_variable_key"></a> [project\_variable\_key](#input\_project\_variable\_key) | (String) The name of the variable. | `string` | `"project_variable_key"` | no |
| <a name="input_project_variable_value"></a> [project\_variable\_value](#input\_project\_variable\_value) | (String, Sensitive) The value of the variable. | `string` | `"project_variable_value"` | no |
| <a name="input_protected"></a> [protected](#input\_protected) | (Boolean) If set to true, the variable will be passed only to pipelines running on protected branches and tags. Defaults to false. | `bool` | `false` | no |
| <a name="input_push_access_level"></a> [push\_access\_level](#input\_push\_access\_level) | (String) Access levels allowed to push. Valid values are: no one, developer, maintainer. | `string` | `"maintainer"` | no |
| <a name="input_push_events"></a> [push\_events](#input\_push\_events) | (Boolean) Invoke the hook for push events. | `bool` | `false` | no |
| <a name="input_push_events_branch_filter"></a> [push\_events\_branch\_filter](#input\_push\_events\_branch\_filter) | (String) Invoke the hook for push events on matching branches only. | `bool` | `false` | no |
| <a name="input_push_rules"></a> [push\_rules](#input\_push\_rules) | An array containing the push rules object. | `list(object({}))` | <pre>[<br>  {<br>    "commit_committer_check": true,<br>    "prevent_secrets": true<br>  }<br>]</pre> | no |
| <a name="input_ref"></a> [ref](#input\_ref) | (String) The branch/tag name to be triggered. | `string` | `"main"` | no |
| <a name="input_releases_events"></a> [releases\_events](#input\_releases\_events) | (Boolean) Invoke the hook for releases events. | `bool` | `false` | no |
| <a name="input_remove_source_branch_after_merge"></a> [remove\_source\_branch\_after\_merge](#input\_remove\_source\_branch\_after\_merge) | (Optional) Enable `Delete source branch` option by default for all new merge requests. | `bool` | `true` | no |
| <a name="input_request_access_enabled"></a> [request\_access\_enabled](#input\_request\_access\_enabled) | (Optional) Allow users to request member access. | `bool` | `true` | no |
| <a name="input_snippets_enabled"></a> [snippets\_enabled](#input\_snippets\_enabled) | (Optional) Enable snippets for the project. | `bool` | `false` | no |
| <a name="input_tag_push_events"></a> [tag\_push\_events](#input\_tag\_push\_events) | (Boolean) Invoke the hook for tag push events. | `bool` | `false` | no |
| <a name="input_token"></a> [token](#input\_token) | (String, Sensitive) A token to present when invoking the hook. The token is not available for imported resources. | `bool` | `false` | no |
| <a name="input_url"></a> [url](#input\_url) | (String) The url of the hook to invoke. | `string` | `"https://gitlab.com/dashboard/projects"` | no |
| <a name="input_visibility_level"></a> [visibility\_level](#input\_visibility\_level) | (Optional) Set to `public` to create a public project. Valid values are `private`, `internal`, `public`. | `string` | `"private"` | no |
| <a name="input_wiki_enabled"></a> [wiki\_enabled](#input\_wiki\_enabled) | (Optional) Enable wiki for the project. | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
