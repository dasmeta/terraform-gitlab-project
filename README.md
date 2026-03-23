## Introduction

This Repository allows to manage the lifecycle of a gitlab project. Create protected branch, add piplines, variables etc.

# gitlab_project

## Repository automation

This repository uses GitHub Actions for its own validation, commit-policy, and
release automation. The module can still manage `.gitlab-ci.yml` and
`.releaserc.json` files for downstream GitLab projects, but those managed files
are examples of module output, not this repository's CI runtime.

## Local contributor workflow

Install the tools required by the repository before opening a pull request:

- `terraform`
- `terraform-docs`
- `pre-commit`
- `node` and `npm`

Install the local Node-based tooling from the repository root:

```bash
npm install
```

Enable the local git hooks:

```bash
git config core.hooksPath githooks
```

Run the same root-level validation flow locally that the repository expects in
CI:

```bash
pre-commit run --all-files
terraform fmt -check -recursive
```

Commit messages are validated with the repository-local `commitlint`
configuration from `commitlint.config.mjs`. The `githooks/commit-msg` hook uses
the dependencies installed by `npm install`; it does not install tooling for
you.

## Maintainer notes

- `Pre-Commit`, `Terraform Test`, `Tflint`, `TFSEC`, and `Checkov` workflows
  validate repository changes against the repository root layout.
- `Commitlint` validates commit messages in CI.
- `Semantic-Release` is the single release workflow for this repository.

## Configuration of provider
```bash

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.8.2"
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
  source  = "dasmeta/project/gitlab/"
  version = "1.1.1"

  name                      = "test-project"
  description               = "Some test project"
  initialize_with_readme    = true
  visibility_level          = "public"
  approvals_before_merge    = 1
  default_branch            = main
  merge_method              = "ff"   <!-- `ff` to create fast-forward merges. Valid values are `merge`, `rebase_merge`, `ff`." -->
  url                       = "https://xxxxxxx.xxx"
  pipline_schedule_value    = "test"
  pipline_schedule_key      = "test"
}
```

## Some other example of usage to create variable

```terraform
module "gitlab_project" {
  source  = "dasmeta/project/gitlab/"
  version = "1.1.1"

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
  url                                              = "https://xxxxxxx.xxx"
  pipline_schedule_value                           = "test"
  pipline_schedule_key                             = "test"

}
```

## Some other example of usage with createing webhook, pipline, branch

```terraform
module "gitlab_project" {
  source  = "dasmeta/project/gitlab/"
  version = "1.1.1"

  name                                             = "test-project"
  description                                      = "Some test project"
  visibility_level                                 = "private"
  create_webhook                                   = true
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
  url                                              = "https://xxxxxxx.xxx"
  pipline_schedule_value                           = "test"
  pipline_schedule_key                             = "test"
  branch_name                                      = "das-meta"

}
```

## Example with semantic-release, GitLab CI and environment variables

```terraform
provider "gitlab" {
  token = "YOUR_GITLAB_TOKEN"
}

terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.9.0"
    }
  }
}

module "semantic_release_project" {
  source = "dasmeta/project/gitlab"
  # version = ">= 1.2.0"

  projects_enabled = true

  gitlab_projects = [
    {
      name                   = "semantic-release-example"
      description            = "Example project with semantic-release and GitLab CI managed by Terraform"
      default_branch         = "main"
      initialize_with_readme = true

      # Project-level environment variables
      env_variables = [
        {
          key    = "NPM_TOKEN"
          value  = "replace-with-your-npm-token"
          masked = true
        },
        {
          key       = "GITLAB_TOKEN"
          value     = "replace-with-your-gitlab-token"
          masked    = true
          protected = true
        }
      ]

      # Repository files (semantic-release config and GitLab CI pipeline)
      repository_files = [
        {
          file_path = ".releaserc.json"
          content   = jsonencode({
            branches = ["main", "next"]
            plugins = [
              "@semantic-release/commit-analyzer",
              "@semantic-release/release-notes-generator",
              "@semantic-release/npm",
              "@semantic-release/gitlab"
            ]
          })
          commit_message = "chore: add semantic-release configuration"
        },
        {
          file_path = ".gitlab-ci.yml"
          content   = <<-YAML
            stages:
              - test
              - release

            variables:
              NODE_ENV: production

            cache:
              paths:
                - node_modules/

            install:
              stage: test
              image: node:18
              script:
                - npm ci
                - npm test

            release:
              stage: release
              image: node:18
              script:
                - npm ci
                - npx semantic-release
              only:
                - main
          YAML
          commit_message = "ci: add GitLab pipeline with semantic-release"
        }
      ]
    }
  ]
}
```

## Many repos (e.g. 30) with global env variables and file-based pipeline/semantic-release

For many repositories that share the same CI, semantic-release config, and env variables, use **global** settings and load content from **files** (no inline YAML/JSON in Terraform):

- **`global_env_variables`** — applied to every project (e.g. `NPM_TOKEN`, `GITLAB_TOKEN`).
- **`global_repository_files`** — same files in every repo; use **`content_file`** to point to a path (e.g. `"${path.module}/templates/.gitlab-ci.yml"`).

Per-project `env_variables` and `repository_files` override globals for that project. For repository files, you can use either **`content`** (inline string) or **`content_file`** (path to a file).

See the full example in **[examples/global_multi_repo](examples/global_multi_repo)** (30 repos, templates in `templates/`).

```terraform
module "gitlab_repos" {
  source = "dasmeta/project/gitlab"

  name             = "multi-repo-managed"
  projects_enabled = true

  global_env_variables = [
    { key = "NPM_TOKEN", value = var.npm_token, masked = true },
    { key = "GITLAB_TOKEN", value = var.gitlab_token, masked = true, protected = true }
  ]

  global_repository_files = [
    { file_path = ".gitlab-ci.yml", content_file = "${path.module}/templates/.gitlab-ci.yml", branch = "main" },
    { file_path = ".releaserc.json", content_file = "${path.module}/templates/.releaserc.json", branch = "main" }
  ]

  gitlab_projects = [ for name in var.repo_names : { name = name, default_branch = "main", initialize_with_readme = true } ]
}
```

## Requirements for pre-commit hooks
For local validation, install `terraform`, `terraform-docs`, `pre-commit`,
`node`, and `npm`, then run `npm install` and `git config core.hooksPath
githooks`.

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
| [gitlab_branch_protection.main](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch_protection) | resource |
| [gitlab_pipeline_schedule.pipline_schedule](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/pipeline_schedule) | resource |
| [gitlab_pipeline_schedule_variable.pipline_schedule_variable](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/pipeline_schedule_variable) | resource |
| [gitlab_pipeline_trigger.pipline_trigger](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/pipeline_trigger) | resource |
| [gitlab_project.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project) | resource |
| [gitlab_project_approval_rule.default](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_approval_rule) | resource |
| [gitlab_project_hook.project_webhook](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_hook) | resource |
| [gitlab_project_variable.env](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_variable) | resource |
| [gitlab_project_variable.project_variable](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_variable) | resource |
| [gitlab_repository_file.project_files](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active"></a> [active](#input\_active) | (Boolean) The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially. | `bool` | `false` | no |
| <a name="input_approval_rule"></a> [approval\_rule](#input\_approval\_rule) | Merge request approval rule configuration | <pre>object({<br/>    enabled                           = bool<br/>    name                              = optional(string)<br/>    approvals_required                = optional(number)<br/>    applies_to_all_protected_branches = optional(bool)<br/>    user_ids                          = optional(list(number))<br/>    group_ids                         = optional(list(number))<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name) | (String) The name for this branch. | `string` | `"develop"` | no |
| <a name="input_branch_protection"></a> [branch\_protection](#input\_branch\_protection) | Branch protection configuration | <pre>object({<br/>    enabled                      = bool<br/>    branch                       = optional(string)<br/>    allow_force_push             = optional(bool)<br/>    push_access_level            = optional(string)<br/>    merge_access_level           = optional(string)<br/>    code_owner_approval_required = optional(bool)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_confidential_issues_events"></a> [confidential\_issues\_events](#input\_confidential\_issues\_events) | (Boolean) Invoke the hook for confidential issues events. | `bool` | `false` | no |
| <a name="input_confidential_note_events"></a> [confidential\_note\_events](#input\_confidential\_note\_events) | (Boolean) Invoke the hook for confidential notes events. | `bool` | `false` | no |
| <a name="input_create"></a> [create](#input\_create) | Boolean to create the resource. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_pipline"></a> [create\_pipline](#input\_create\_pipline) | Boolean to create the pipline. Defaults to true. | `bool` | `false` | no |
| <a name="input_create_variable"></a> [create\_variable](#input\_create\_variable) | Boolean to create the resource variable. Defaults to true. | `bool` | `false` | no |
| <a name="input_create_webhook"></a> [create\_webhook](#input\_create\_webhook) | Boolean to create the webhook. Defaults to true. | `bool` | `false` | no |
| <a name="input_cron"></a> [cron](#input\_cron) | (String) The cron (e.g. 0 1 * * *). | `string` | `"0 1 * * *"` | no |
| <a name="input_deployment_events"></a> [deployment\_events](#input\_deployment\_events) | (Boolean) Invoke the hook for deployment events. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) A description of the project. | `string` | `"Repository for testing"` | no |
| <a name="input_enable_ssl_verification"></a> [enable\_ssl\_verification](#input\_enable\_ssl\_verification) | (Boolean) Enable ssl verification when invoking the hook. | `bool` | `false` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | List of GitLab project configurations | <pre>list(object({<br/>    name        = string<br/>    description = optional(string)<br/><br/>    visibility_level       = optional(string, "private")<br/>    default_branch         = optional(string, "main")<br/>    initialize_with_readme = optional(bool, false)<br/>    request_access_enabled = optional(bool, true)<br/>    prevent_destroy        = optional(bool, true)<br/>    lfs_enabled            = optional(bool, false)<br/>    packages_enabled       = optional(bool, false)<br/><br/>    # Merge behavior<br/>    squash_option = optional(string, "default_on") # always | default_on | never<br/>    merge_method  = optional(string, "ff")         # merge | rebase_merge | ff<br/><br/>    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)<br/>    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)<br/>    remove_source_branch_after_merge                 = optional(bool, true)<br/><br/>    pages_access_level = optional(string, "private")<br/><br/>    suggestion_commit_message = optional(string)<br/>    merge_commit_template     = optional(string)<br/><br/>    # Push rules (all optional)<br/>    push_rules = optional(list(object({<br/>      author_email_regex            = optional(string)<br/>      branch_name_regex             = optional(string)<br/>      commit_committer_check        = optional(bool, false)<br/>      commit_message_negative_regex = optional(string)<br/>      commit_message_regex          = optional(string)<br/>      deny_delete_tag               = optional(bool, false)<br/>      file_name_regex               = optional(string)<br/>      max_file_size                 = optional(number)<br/>      member_check                  = optional(bool, false)<br/>      prevent_secrets               = optional(bool, false)<br/>      reject_unsigned_commits       = optional(bool, false)<br/>    })), [])<br/><br/>    # Project-level environment variables<br/>    env_variables = optional(list(object({<br/>      key       = string<br/>      value     = string<br/>      masked    = optional(bool, false)<br/>      protected = optional(bool, false)<br/>    })), [])<br/><br/>    # Repository files to manage (e.g. .releaserc, .gitlab-ci.yml). Use content_file to load from disk.<br/>    repository_files = optional(list(object({<br/>      file_path      = string<br/>      content_file   = optional(string) # path to file from caller, e.g. path.module/templates/file<br/>      content        = optional(string) # inline content; one of content_file or content<br/>      branch         = optional(string, "main")<br/>      commit_message = optional(string, "Managed by Terraform")<br/>      author_name    = optional(string)<br/>      author_email   = optional(string)<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Environment variables applied to every GitLab project. Use for shared NPM\_TOKEN, GITLAB\_TOKEN, etc. | <pre>list(object({<br/>    key       = string<br/>    value     = string<br/>    masked    = optional(bool, false)<br/>    protected = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_global_repository_files"></a> [global\_repository\_files](#input\_global\_repository\_files) | Repository files applied to every project. Use content\_file to load from disk (e.g. .gitlab-ci.yml, .releaserc.json). Path is typically path.module from the caller. | <pre>list(object({<br/>    file_path      = string<br/>    content_file   = optional(string) # path to file, e.g. \"${path.module}/templates/.gitlab-ci.yml\"<br/>    content        = optional(string) # inline content; one of content_file or content required<br/>    branch         = optional(string, "main")<br/>    commit_message = optional(string, "Managed by Terraform")<br/>    author_name    = optional(string)<br/>    author_email   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_issues_events"></a> [issues\_events](#input\_issues\_events) | (Boolean) Invoke the hook for issues events. | `bool` | `false` | no |
| <a name="input_job_events"></a> [job\_events](#input\_job\_events) | (Boolean) Invoke the hook for job events. | `bool` | `false` | no |
| <a name="input_masked"></a> [masked](#input\_masked) | (Boolean) If set to true, the value of the variable will be hidden in job logs. The value must meet the masking requirements. Defaults to false. | `bool` | `false` | no |
| <a name="input_merge_access_level"></a> [merge\_access\_level](#input\_merge\_access\_level) | (String) Access levels allowed to merge. Valid values are: no one, developer, maintainer. | `string` | `"maintainer"` | no |
| <a name="input_merge_requests_events"></a> [merge\_requests\_events](#input\_merge\_requests\_events) | (Boolean) Invoke the hook for merge requests. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the project to be created | `string` | n/a | yes |
| <a name="input_pipeline_events"></a> [pipeline\_events](#input\_pipeline\_events) | (Boolean) Invoke the hook for pipeline events. | `bool` | `false` | no |
| <a name="input_pipline_schedule_key"></a> [pipline\_schedule\_key](#input\_pipline\_schedule\_key) | (String) Name of the variable. | `string` | `null` | no |
| <a name="input_pipline_schedule_value"></a> [pipline\_schedule\_value](#input\_pipline\_schedule\_value) | (String) Value of the variable. | `string` | `null` | no |
| <a name="input_pipline_trigger_description"></a> [pipline\_trigger\_description](#input\_pipline\_trigger\_description) | (String) The description of the pipeline trigger. | `string` | `""` | no |
| <a name="input_project_variable_key"></a> [project\_variable\_key](#input\_project\_variable\_key) | (String) The name of the variable. | `string` | `null` | no |
| <a name="input_project_variable_value"></a> [project\_variable\_value](#input\_project\_variable\_value) | (String, Sensitive) The value of the variable. | `string` | `null` | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_protected"></a> [protected](#input\_protected) | (Boolean) If set to true, the variable will be passed only to pipelines running on protected branches and tags. Defaults to false. | `bool` | `false` | no |
| <a name="input_push_access_level"></a> [push\_access\_level](#input\_push\_access\_level) | (String) Access levels allowed to push. Valid values are: no one, developer, maintainer. | `string` | `"maintainer"` | no |
| <a name="input_push_events"></a> [push\_events](#input\_push\_events) | (Boolean) Invoke the hook for push events. | `bool` | `false` | no |
| <a name="input_push_events_branch_filter"></a> [push\_events\_branch\_filter](#input\_push\_events\_branch\_filter) | (String) Invoke the hook for push events on matching branches only. | `bool` | `false` | no |
| <a name="input_ref"></a> [ref](#input\_ref) | (String) The branch/tag name to be triggered. | `string` | `"main"` | no |
| <a name="input_releases_events"></a> [releases\_events](#input\_releases\_events) | (Boolean) Invoke the hook for releases events. | `bool` | `false` | no |
| <a name="input_tag_push_events"></a> [tag\_push\_events](#input\_tag\_push\_events) | (Boolean) Invoke the hook for tag push events. | `bool` | `false` | no |
| <a name="input_token"></a> [token](#input\_token) | (String, Sensitive) A token to present when invoking the hook. The token is not available for imported resources. | `bool` | `false` | no |
| <a name="input_url"></a> [url](#input\_url) | (String) The url of the hook to invoke. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_project_ids"></a> [gitlab\_project\_ids](#output\_gitlab\_project\_ids) | Map of GitLab project name to project ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
