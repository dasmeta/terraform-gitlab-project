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

## Dynamic Environments

The module can generate reviewable GitLab dynamic environment setup across the
repositories involved in the workflow:

- `dynamic_environments_project` manages a central orchestration project.
- `dynamic_environments_project.gitlab_agent` can manage the GitLab Agent
  config file in the central dynamic environments project by default.
- `gitlab_projects[].dynamic_environment` opts an individual service project
  into a reusable CI trigger file.

Central project example:

```hcl
dynamic_environments_project = {
  enabled        = true
  name           = "example-dynamic-environments"
  group_key      = "example"
  default_branch = "main"
  deploy_mode    = "gitlab_agent"

  gitlab_agent = {
    enabled        = true
    name           = "eks-dev"
    source_branch  = "feature/gitlab-agent-config"
    target_branch  = "main"
    register_agent = true
    # Optional target override; omit to write config.yaml to this dynamic
    # environments project by default.
    # config_project_name = "service-two"
    # config_project_id   = "123456"
    # config_project_path = "example/service-two"
    # Optional; defaults to .gitlab/agents/<name>/config.yaml.
    config_file_path = ".gitlab/agents/eks-dev/config.yaml"

    install = {
      enabled     = true
      namespace   = "gitlab-agent-eks-dev"
      kas_address = "wss://kas.gitlab.com"
    }

    ci_access = {
      projects = [
        { id = "example/example-dynamic-environments" },
        { id = "example/backend" },
        { id = "example/scheduler" },
        { id = "example/pipecat" },
        { id = "example/evals" },
      ]
    }

    user_access = {
      access_as_agent = true
      projects = [
        { id = "example/example-dynamic-environments" },
        { id = "example/backend" },
        { id = "example/talk" },
        { id = "example/scheduler" },
        { id = "example/pipecat" },
        { id = "example/evals" },
      ]
    }
  }

  # Script-only configuration. These values are baked into generated CI/scripts
  # and do not appear in config/applications.yaml.
  deploy_config = {
    namespace_prefix      = "e2e-"
    gitlab_clone_base_url = "https://gitlab.com"
    helm_repo_name        = "dasmeta"
    helm_repo_url         = "https://dasmeta.github.io/helm"
    work_dir              = "/tmp/dynamic-deploy"
  }

  cleanup_config = {
    max_attempts          = 3
    retry_backoff_seconds = 5
  }

  applications = {
    defaults = {
      aws_region          = "us-east-2"
      secret_env          = "dev"
      base_ref            = "main"
      base_ref_fallbacks  = ["e2e-dynamic", "main", "master"]
      helm_chart          = "dasmeta/base"
      helm_timeout        = "40m"
      dynamic_base_domain = "dev.example.com"
      dynamic_env_release = "app"
    }

    infra_deployments = [
      {
        release   = "redis"
        repo_name = "bitnami"
        repo_url  = "https://charts.bitnami.com/bitnami"
        chart     = "bitnami/redis"
        version   = "20.6.3"
        values = {
          architecture = "standalone"
          auth = {
            enabled = false
          }
        }
      }
    ]
    deployments       = []
  }
}
```

When enabled, Terraform creates a managed source branch named
`feature/dynamic-environments`, writes these generated files, and opens a merge
request to the central project's default branch:

- `config/applications.yaml`
- `scripts/deploy_stack.py`
- `scripts/clean_stack.py`
- `.gitlab-ci.yml`

When `gitlab_agent.enabled = true`, Terraform also generates a GitLab Agent
configuration file in the central dynamic environments project by default.
Override it with `gitlab_agent.config_project_name` for another managed project, or use
`gitlab_agent.config_project_id` plus `gitlab_agent.config_project_path` for an
external repository. The generated file defaults to
`.gitlab/agents/<agent-name>/config.yaml`, is written on
`feature/gitlab-agent-config`, and gets its own merge request.

The GitLab Agent config resources are implemented in the dedicated
`modules/gitlab_agent_config` submodule. The dynamic environment submodule only
consumes the effective `GITLAB_AGENT_PATH` for generated CI.

The example intentionally shows defaultable GitLab Agent fields such as
`source_branch`, `target_branch`, `config_file_path`, and the optional
`config_project_*` target selectors so consumers can see which parts are safe to
customize.

If `gitlab_agent.register_agent = true`, the submodule creates the GitLab
cluster agent and an agent token with `gitlab_cluster_agent` and
`gitlab_cluster_agent_token`. If `gitlab_agent.install.enabled = true`, it also
installs the official `gitlab/gitlab-agent` Helm chart through `helm_release`
using the created token and configured KAS address. Configure the Helm provider
for the target Kubernetes cluster in the calling stack before enabling install.

The generated token is marked sensitive by the provider, but it is still stored
in Terraform state because Terraform must pass it to Helm as
`config.token`. Protect the state backend accordingly.

The generated agent `config.yaml` is rendered from
`modules/gitlab_agent_config/templates/config.yaml.tftpl`. When
`ci_access.projects` is omitted, the config includes the central dynamic
environments project and enabled service projects automatically. When
`ci_access.projects` is set, that input list is used as the rendered project
access list. `user_access.projects` is rendered independently, and
`user_access.access_as_agent = true` renders `access_as.agent`. GitLab Agent
registration tokens and Kubernetes installation secrets are intentionally not
managed by this module.

Set `dynamic_environments_project.deploy_mode = "gitlab_agent"` to make the
central generated CI use `kubectl config use-context "$GITLAB_AGENT_PATH"`.
The default `deploy_mode = "aws_eks"` keeps the existing
`aws eks update-kubeconfig` flow.

Service project opt-in example:

```hcl
gitlab_projects = [
  {
    name      = "service-one"
    group_key = "example"

    dynamic_environment = {
      enabled = true
      # Optional; default shown.
      ci_file_path = "ci-pipelines/dynamic-environment.gitlab-ci.yml"
    }
  }
]
```

When a service project opts in, Terraform writes the reusable CI trigger file on
`feature/dynamic-environments` and opens a merge request to that project's
default branch. Service project root `.gitlab-ci.yml` files are not modified by
default. The generated MR description includes this manual include snippet:

```yaml
include:
  - local: ci-pipelines/dynamic-environment.gitlab-ci.yml
```

Merge request creation uses a bounded GitLab API call from Terraform's local
execution environment because `gitlabhq/gitlab` does not expose a merge-request
creation resource. Set `GITLAB_TOKEN` or `GITLAB_API_TOKEN` in the environment
before `terraform apply` when dynamic environments are enabled.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ci_env_variables"></a> [ci\_env\_variables](#module\_ci\_env\_variables) | ./modules/ci_env_variables | n/a |
| <a name="module_dynamic_environment"></a> [dynamic\_environment](#module\_dynamic\_environment) | ./modules/dynamic_environment | n/a |
| <a name="module_gitlab_agent_config"></a> [gitlab\_agent\_config](#module\_gitlab\_agent\_config) | ./modules/gitlab_agent_config | n/a |
| <a name="module_gitlab_group"></a> [gitlab\_group](#module\_gitlab\_group) | ./modules/gitlab_group | n/a |
| <a name="module_project"></a> [project](#module\_project) | ./modules/project | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamic_environments_project"></a> [dynamic\_environments\_project](#input\_dynamic\_environments\_project) | Optional central GitLab project for dynamic environments orchestration.<br/>When enabled, the module creates a project, generates orchestration files on<br/>source\_branch, and opens a merge request to default\_branch. The applications<br/>object renders to config/applications.yaml. | <pre>object({<br/>    enabled                = optional(bool, false)<br/>    name                   = optional(string)<br/>    description            = optional(string, "Dynamic environments orchestration")<br/>    visibility_level       = optional(string, "private")<br/>    default_branch         = optional(string, "main")<br/>    initialize_with_readme = optional(bool, true)<br/>    namespace_id           = optional(number)<br/>    group_key              = optional(string)<br/>    source_branch          = optional(string, "feature/dynamic-environments")<br/>    mr_title               = optional(string, "Add dynamic environments orchestration")<br/>    gitlab_api_url         = optional(string, "https://gitlab.com/api/v4")<br/>    gitlab_agent_path      = optional(string)<br/>    cluster_name           = optional(string, "eks-dev")<br/>    deploy_mode            = optional(string, "aws_eks")<br/>    runner_tags            = optional(list(string), ["k8s-runner"])<br/>    gitlab_agent = optional(object({<br/>      enabled             = optional(bool, false)                              # Generate .gitlab/agents/<agent-name>/config.yaml when true<br/>      name                = optional(string)                                   # GitLab Agent name; defaults to dynamic_environments_project.cluster_name<br/>      config_project_name = optional(string)                                   # Optional managed gitlab_projects[].name that receives config.yaml; omit to use the dynamic environments project<br/>      config_project_id   = optional(string)                                   # Optional external/existing GitLab project ID that receives config.yaml<br/>      config_project_path = optional(string)                                   # Required with config_project_id unless dynamic_environments_project.gitlab_agent_path is set; used for <project-path>:<agent-name><br/>      source_branch       = optional(string, "feature/gitlab-agent-config")    # Branch where Terraform writes generated GitLab Agent config<br/>      target_branch       = optional(string, "main")                           # Merge request target branch for generated GitLab Agent config<br/>      mr_title            = optional(string, "Add GitLab Agent configuration") # Merge request title for generated GitLab Agent config<br/>      config_file_path    = optional(string)                                   # Optional file path; defaults to .gitlab/agents/<agent-name>/config.yaml<br/>      register_agent      = optional(bool, false)                              # Create gitlab_cluster_agent and token when true<br/>      token_name          = optional(string)                                   # Optional GitLab Agent token name; defaults to <agent-name>-token<br/>      token_description   = optional(string)                                   # Optional GitLab Agent token description<br/>      install = optional(object({<br/>        enabled          = optional(bool, false)                        # Install the GitLab Agent Helm chart; requires register_agent = true<br/>        release_name     = optional(string)                             # Helm release name; defaults to agent name<br/>        namespace        = optional(string)                             # Kubernetes namespace; defaults to gitlab-agent-<agent-name><br/>        create_namespace = optional(bool, true)                         # Let Helm create the namespace<br/>        repository       = optional(string, "https://charts.gitlab.io") # Helm repository for the GitLab Agent chart<br/>        chart            = optional(string, "gitlab-agent")             # Helm chart name<br/>        chart_version    = optional(string)                             # Optional Helm chart version pin<br/>        kas_address      = optional(string, "wss://kas.gitlab.com")     # GitLab KAS websocket address passed to chart config.kasAddress<br/>        timeout          = optional(number, 300)                        # Helm operation timeout in seconds<br/>        wait             = optional(bool, true)                         # Wait for Helm resources to become ready<br/>        atomic           = optional(bool, false)                        # Roll back failed Helm install/upgrade<br/>        values           = optional(list(string), [])                   # Raw Helm values YAML strings<br/>        set_values = optional(list(object({<br/>          name  = string           # Helm set name<br/>          value = string           # Helm set value<br/>          type  = optional(string) # Optional Helm set type<br/>        })), [])<br/>      }), {})<br/>      ci_access = optional(object({<br/>        instance = optional(bool, false) # Render ci_access.instance when true<br/>        projects = optional(list(object({<br/>          id                      = string                 # Project path or ID allowed to use this agent from CI<br/>          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions<br/>          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction<br/>          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry<br/>        })), [])<br/>        groups = optional(list(object({<br/>          id                      = string                 # Group path or ID allowed to use this agent from CI<br/>          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions<br/>          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction<br/>          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry<br/>        })), [])<br/>      }), {})<br/>      user_access = optional(object({<br/>        access_as_agent = optional(bool) # Render user_access.access_as.agent; defaults to true when user_access.projects is non-empty<br/>        projects = optional(list(object({<br/>          id = string # Project path or ID allowed to access Kubernetes through this agent as a user<br/>        })), [])<br/>      }), {})<br/>    }), {})<br/>    deploy_config = optional(object({<br/>      aws_region                   = optional(string, "us-east-2")<br/>      namespace_prefix             = optional(string, "e2e-")<br/>      fallback_image_tag           = optional(string, "latest")<br/>      gitlab_api_timeout_seconds   = optional(number, 20)<br/>      gitlab_api_url               = optional(string)<br/>      gitlab_clone_base_url        = optional(string, "https://gitlab.com")<br/>      helm_repo_name               = optional(string, "dasmeta")<br/>      helm_repo_url                = optional(string, "https://dasmeta.github.io/helm")<br/>      work_dir                     = optional(string, "/tmp/dynamic-deploy")<br/>      helm_dir                     = optional(string, "helm")<br/>      image_tag_set_path           = optional(string, "image.tag")<br/>      migration_image_tag_set_path = optional(string, "job.image.tag")<br/>      base_ref_fallbacks           = optional(list(string), ["main", "master"])<br/>      helm_value_files             = optional(list(string), ["values.yaml", "values.dev.yaml"])<br/>      helm_optional_value_files    = optional(list(string), ["values.dev.<APP_COMPONENT>.yaml"])<br/>      helm_required_value_files    = optional(list(string), ["values.e2e.yaml"])<br/>      helm_migration_value_files   = optional(list(string), ["values.e2e.migration.yaml"])<br/>    }), {})<br/>    cleanup_config = optional(object({<br/>      namespace_prefix      = optional(string, "e2e-")<br/>      max_attempts          = optional(number, 3)<br/>      retry_backoff_seconds = optional(number, 5)<br/>    }), {})<br/>    applications = optional(object({<br/>      defaults = optional(object({<br/>        aws_region          = optional(string, "eu-central-1")<br/>        secret_env          = optional(string, "dev")<br/>        base_ref            = optional(string, "main")<br/>        base_ref_fallbacks  = optional(list(string))<br/>        helm_chart          = optional(string, "dasmeta/base")<br/>        helm_timeout        = optional(string, "40m")<br/>        dynamic_base_domain = optional(string)<br/>        dynamic_env_release = optional(string)<br/>      }), {})<br/>      infra_deployments = optional(any, [])<br/>      deployments = optional(list(object({<br/>        project            = string<br/>        helm_release       = string<br/>        app_component      = string<br/>        helm_version       = string<br/>        db_migration       = optional(bool)<br/>        helm_overrides     = optional(list(string))<br/>        base_ref           = optional(string)<br/>        base_ref_fallbacks = optional(list(string))<br/>        source_environment = optional(string)<br/>        set_build_version  = optional(bool)<br/>      })), [])<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_gitlab_groups"></a> [gitlab\_groups](#input\_gitlab\_groups) | GitLab groups for this module (each entry needs a unique "key"). Each entry must be one of two supported modes:<br/>- managed group: set create = true and provide name + path<br/>- existing group reference: set create = false and provide existing\_group\_id<br/><br/>Projects may resolve their namespace through group\_key, or by the implicit single-group fallback when exactly one<br/>gitlab\_groups entry exists. If this list is empty, every gitlab\_projects item must set namespace\_id directly. | <pre>list(object({<br/>    key               = string                      # Stable id for wiring group_key on projects<br/>    create            = optional(bool, false)       # Create group via API for this entry<br/>    name              = optional(string)            # Display name (required if create is true)<br/>    path              = optional(string)            # URL path (required if create is true)<br/>    description       = optional(string, "")        # Group description<br/>    visibility_level  = optional(string, "private") # private | internal | public<br/>    parent_id         = optional(number)            # Parent namespace id for subgroups<br/>    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true<br/>  }))</pre> | `[]` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | List of GitLab project configurations.<br/><br/>Supported namespace selection paths:<br/>- set namespace\_id directly<br/>- set group\_key to select an entry from var.gitlab\_groups<br/>- omit both namespace\_id and group\_key only when exactly one gitlab\_groups entry exists; that single group is used implicitly<br/><br/>Do not set namespace\_id and group\_key together on the same project.<br/>When gitlab\_groups is empty, set namespace\_id on every project.<br/><br/>Merge behavior (per project; GitLab UI under Settings → Merge requests):<br/><br/>squash\_option — Squash commits when merging:<br/>  - never        → Do not allow (squash disabled; checkbox hidden)<br/>  - default\_off  → Allow (checkbox visible, off by default)<br/>  - default\_on   → Encourage (checkbox visible, on by default)<br/>  - always       → Require (always squash; user cannot disable)<br/><br/>merge\_method — Merge method:<br/>  - merge        → Create a merge commit<br/>  - rebase\_merge → Merge commit with semi-linear history<br/>  - ff           → Fast-forward merge<br/><br/>branch\_protections — Optional list per project: Settings → Repository → Protected branches.<br/>When omitted or set to [], this module creates one default protection for branch "main".<br/>Access is only via merge\_access\_level / push\_access\_level (maintainer, developer, admin, no one).<br/>Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab\_branch\_protection.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>When omitted or set to [], no project approval rule resources are created.<br/>Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>prevent\_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent\_destroy } from this field (dynamic lifecycle is not supported for count/for\_each resources in the same way as static blocks).<br/><br/>ci\_pipeline\_variables\_minimum\_override\_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).<br/>Valid values: no\_one\_allowed, developer, maintainer, owner. Default in type: maintainer.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>If present and non-empty, the module creates one GitLab approval rule resource<br/>per list entry. Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>env\_variables — Per-project CI/CD variables (gitlab\_project\_variable via module ci\_env\_variables), merged with<br/>var.global\_env\_variables; the same key on the project replaces the full global variable definition for that project. | <pre>list(object({<br/>    name                                             = string                         # Project name / slug key used by child resources<br/>    description                                      = optional(string)               # Project description<br/>    visibility_level                                 = optional(string, "private")    # private | internal | public<br/>    default_branch                                   = optional(string, "develop")    # Initial default branch name<br/>    initialize_with_readme                           = optional(bool, true)           # Create repository with README<br/>    request_access_enabled                           = optional(bool, true)           # Allow users to request access<br/>    prevent_destroy                                  = optional(bool, true)           # Contract hint only; not mapped to Terraform lifecycle<br/>    namespace_id                                     = optional(number)               # Explicit GitLab namespace id for the project<br/>    group_key                                        = optional(string)               # Resolve namespace through gitlab_groups[].key<br/>    lfs_enabled                                      = optional(bool, true)           # Enable Git LFS for the project<br/>    packages_enabled                                 = optional(bool, true)           # Enable GitLab package registry<br/>    squash_option                                    = optional(string, "default_on") # never | default_off | default_on | always<br/>    merge_method                                     = optional(string, "merge")      # merge | rebase_merge | ff<br/>    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)           # Require successful pipeline before merge<br/>    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)           # Require resolved discussions before merge<br/>    remove_source_branch_after_merge                 = optional(bool, true)           # Auto-delete source branch after merge<br/>    ci_pipeline_variables_minimum_override_role      = optional(string, "developer")  # no_one_allowed | developer | maintainer | owner<br/>    pages_access_level                               = optional(string, "private")    # GitLab Pages visibility level<br/>    suggestion_commit_message                        = optional(string)               # Suggested squash commit message template<br/>    merge_commit_template                            = optional(string)               # Merge commit message template<br/>    branch_protections = optional(list(object({<br/>      branch                       = string                         # Protected branch name<br/>      merge_access_level           = optional(string, "maintainer") # Merge access role<br/>      push_access_level            = optional(string, "maintainer") # Push access role<br/>      allow_force_push             = optional(bool, false)          # Allow force-push on the branch<br/>      code_owner_approval_required = optional(bool, false)          # Require code-owner approval<br/>      unprotect_access_level       = optional(string, "maintainer") # Unprotect access role<br/>    })), [])<br/>    approval_rule = optional(list(object({<br/>      name                              = optional(string, "Approval rule") # Approval rule display name<br/>      approvals_required                = optional(number, 1)               # Number of approvals required<br/>      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches<br/>      user_ids                          = optional(list(number))            # Explicit approver user ids<br/>      group_ids                         = optional(list(number))            # Explicit approver group ids<br/>    })), [])<br/>    push_rules = optional(list(any), []) # Provider-shaped push rules consumed by gitlab_project.push_rules<br/>    env_variables = optional(list(object({<br/>      key       = string                # CI/CD variable name<br/>      value     = string                # CI/CD variable value<br/>      masked    = optional(bool, false) # Hide value in logs / UI where supported<br/>      protected = optional(bool, false) # Restrict variable to protected refs<br/>    })), [])<br/>    dynamic_environment = optional(object({<br/>      enabled             = optional(bool, false)                                              # Create reusable dynamic environment CI trigger branch/file/MR for this project<br/>      ci_file_path        = optional(string, "ci-pipelines/dynamic-environment.gitlab-ci.yml") # Generated reusable CI file path<br/>      stage               = optional(string, "e2e-test-dynamic")                               # Trigger job stage<br/>      cleanup_stage       = optional(string, "e2e-test-dynamic-clean")                         # Stop job stage<br/>      needs               = optional(list(string), ["build"])                                  # Upstream jobs required before trigger job<br/>      source_environment  = optional(string, "dev")                                            # GitLab deployment source environment for tag lookup<br/>      dynamic_env_release = optional(string)                                                   # Release label for DYNAMIC_ENV_RELEASE; defaults to project name<br/>    }), null)<br/>  }))</pre> | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Environment variables applied to every GitLab project. Use for shared NPM\_TOKEN, GITLAB\_TOKEN, etc. | <pre>list(object({<br/>    key       = string                # CI/CD variable name<br/>    value     = string                # Variable value (use masked for secrets)<br/>    masked    = optional(bool, false) # Hide value in job logs / UI where supported<br/>    protected = optional(bool, false) # Available only on protected branches/tags<br/>  }))</pre> | `[]` | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab\_groups[].create is true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamic_environment_gitlab_agent_cluster_agent_id"></a> [dynamic\_environment\_gitlab\_agent\_cluster\_agent\_id](#output\_dynamic\_environment\_gitlab\_agent\_cluster\_agent\_id) | Registered GitLab Agent ID when registration is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_config_file_path"></a> [dynamic\_environment\_gitlab\_agent\_config\_file\_path](#output\_dynamic\_environment\_gitlab\_agent\_config\_file\_path) | Generated GitLab Agent config file path when agent config generation is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_config_project_id"></a> [dynamic\_environment\_gitlab\_agent\_config\_project\_id](#output\_dynamic\_environment\_gitlab\_agent\_config\_project\_id) | GitLab project ID where the GitLab Agent config is generated when enabled. |
| <a name="output_dynamic_environment_gitlab_agent_helm_release_name"></a> [dynamic\_environment\_gitlab\_agent\_helm\_release\_name](#output\_dynamic\_environment\_gitlab\_agent\_helm\_release\_name) | Helm release name for the installed GitLab Agent when install is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_helm_release_namespace"></a> [dynamic\_environment\_gitlab\_agent\_helm\_release\_namespace](#output\_dynamic\_environment\_gitlab\_agent\_helm\_release\_namespace) | Kubernetes namespace for the installed GitLab Agent when install is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_path"></a> [dynamic\_environment\_gitlab\_agent\_path](#output\_dynamic\_environment\_gitlab\_agent\_path) | GitLab Agent context path referenced by generated dynamic environment CI. |
| <a name="output_dynamic_environment_service_ci_file_paths"></a> [dynamic\_environment\_service\_ci\_file\_paths](#output\_dynamic\_environment\_service\_ci\_file\_paths) | Map of service project name to generated dynamic environment CI trigger file path. |
| <a name="output_dynamic_environments_project_id"></a> [dynamic\_environments\_project\_id](#output\_dynamic\_environments\_project\_id) | GitLab project ID for the central dynamic environments project when enabled. |
| <a name="output_dynamic_environments_project_path"></a> [dynamic\_environments\_project\_path](#output\_dynamic\_environments\_project\_path) | Path with namespace for the central dynamic environments project when enabled. |
| <a name="output_gitlab_group_full_paths"></a> [gitlab\_group\_full\_paths](#output\_gitlab\_group\_full\_paths) | Map of group key to full\_path for groups created by this module (Terraform-managed only; existing groups referenced via existing\_group\_id are not listed here). |
| <a name="output_gitlab_group_ids"></a> [gitlab\_group\_ids](#output\_gitlab\_group\_ids) | Map of group key (from gitlab\_groups) to namespace id for every resolvable configured group — managed groups contribute their created id and existing-group references require existing\_group\_id. |
| <a name="output_gitlab_project_ids"></a> [gitlab\_project\_ids](#output\_gitlab\_project\_ids) | Map of GitLab project name to project ID |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ci_env_variables"></a> [ci\_env\_variables](#module\_ci\_env\_variables) | ./modules/ci_env_variables | n/a |
| <a name="module_dynamic_environment"></a> [dynamic\_environment](#module\_dynamic\_environment) | ./modules/dynamic_environment | n/a |
| <a name="module_gitlab_agent_config"></a> [gitlab\_agent\_config](#module\_gitlab\_agent\_config) | ./modules/gitlab_agent_config | n/a |
| <a name="module_gitlab_group"></a> [gitlab\_group](#module\_gitlab\_group) | ./modules/gitlab_group | n/a |
| <a name="module_project"></a> [project](#module\_project) | ./modules/project | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamic_environments_project"></a> [dynamic\_environments\_project](#input\_dynamic\_environments\_project) | Optional central GitLab project for dynamic environments orchestration.<br/>When enabled, the module creates a project, generates orchestration files on<br/>source\_branch, and opens a merge request to default\_branch. The applications<br/>object renders to config/applications.yaml. | <pre>object({<br/>    enabled                = optional(bool, false)<br/>    name                   = optional(string)<br/>    description            = optional(string, "Dynamic environments orchestration")<br/>    visibility_level       = optional(string, "private")<br/>    default_branch         = optional(string, "main")<br/>    initialize_with_readme = optional(bool, true)<br/>    namespace_id           = optional(number)<br/>    group_key              = optional(string)<br/>    source_branch          = optional(string, "feature/dynamic-environments")<br/>    mr_title               = optional(string, "Add dynamic environments orchestration")<br/>    gitlab_api_url         = optional(string, "https://gitlab.com/api/v4")<br/>    gitlab_agent_path      = optional(string)<br/>    cluster_name           = optional(string, "eks-dev")<br/>    deploy_mode            = optional(string, "aws_eks")<br/>    runner_tags            = optional(list(string), ["k8s-runner"])<br/>    gitlab_agent = optional(object({<br/>      enabled             = optional(bool, false)                              # Generate .gitlab/agents/<agent-name>/config.yaml when true<br/>      name                = optional(string)                                   # GitLab Agent name; defaults to dynamic_environments_project.cluster_name<br/>      config_project_name = optional(string)                                   # Optional managed gitlab_projects[].name that receives config.yaml; omit to use the dynamic environments project<br/>      config_project_id   = optional(string)                                   # Optional external/existing GitLab project ID that receives config.yaml<br/>      config_project_path = optional(string)                                   # Required with config_project_id unless dynamic_environments_project.gitlab_agent_path is set; used for <project-path>:<agent-name><br/>      source_branch       = optional(string, "feature/gitlab-agent-config")    # Branch where Terraform writes generated GitLab Agent config<br/>      target_branch       = optional(string, "main")                           # Merge request target branch for generated GitLab Agent config<br/>      mr_title            = optional(string, "Add GitLab Agent configuration") # Merge request title for generated GitLab Agent config<br/>      config_file_path    = optional(string)                                   # Optional file path; defaults to .gitlab/agents/<agent-name>/config.yaml<br/>      register_agent      = optional(bool, false)                              # Create gitlab_cluster_agent and token when true<br/>      token_name          = optional(string)                                   # Optional GitLab Agent token name; defaults to <agent-name>-token<br/>      token_description   = optional(string)                                   # Optional GitLab Agent token description<br/>      install = optional(object({<br/>        enabled          = optional(bool, false)                        # Install the GitLab Agent Helm chart; requires register_agent = true<br/>        release_name     = optional(string)                             # Helm release name; defaults to agent name<br/>        namespace        = optional(string)                             # Kubernetes namespace; defaults to gitlab-agent-<agent-name><br/>        create_namespace = optional(bool, true)                         # Let Helm create the namespace<br/>        repository       = optional(string, "https://charts.gitlab.io") # Helm repository for the GitLab Agent chart<br/>        chart            = optional(string, "gitlab-agent")             # Helm chart name<br/>        chart_version    = optional(string)                             # Optional Helm chart version pin<br/>        kas_address      = optional(string, "wss://kas.gitlab.com")     # GitLab KAS websocket address passed to chart config.kasAddress<br/>        timeout          = optional(number, 300)                        # Helm operation timeout in seconds<br/>        wait             = optional(bool, true)                         # Wait for Helm resources to become ready<br/>        atomic           = optional(bool, false)                        # Roll back failed Helm install/upgrade<br/>        values           = optional(list(string), [])                   # Raw Helm values YAML strings<br/>        set_values = optional(list(object({<br/>          name  = string           # Helm set name<br/>          value = string           # Helm set value<br/>          type  = optional(string) # Optional Helm set type<br/>        })), [])<br/>      }), {})<br/>      ci_access = optional(object({<br/>        instance = optional(bool, false) # Render ci_access.instance when true<br/>        projects = optional(list(object({<br/>          id                      = string                 # Project path or ID allowed to use this agent from CI<br/>          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions<br/>          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction<br/>          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry<br/>        })), [])<br/>        groups = optional(list(object({<br/>          id                      = string                 # Group path or ID allowed to use this agent from CI<br/>          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions<br/>          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction<br/>          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry<br/>        })), [])<br/>      }), {})<br/>      user_access = optional(object({<br/>        access_as_agent = optional(bool) # Render user_access.access_as.agent; defaults to true when user_access.projects is non-empty<br/>        projects = optional(list(object({<br/>          id = string # Project path or ID allowed to access Kubernetes through this agent as a user<br/>        })), [])<br/>      }), {})<br/>    }), {})<br/>    deploy_config = optional(object({<br/>      aws_region                   = optional(string, "us-east-2")<br/>      namespace_prefix             = optional(string, "e2e-")<br/>      fallback_image_tag           = optional(string, "latest")<br/>      gitlab_api_timeout_seconds   = optional(number, 20)<br/>      gitlab_api_url               = optional(string)<br/>      gitlab_clone_base_url        = optional(string, "https://gitlab.com")<br/>      helm_repo_name               = optional(string, "dasmeta")<br/>      helm_repo_url                = optional(string, "https://dasmeta.github.io/helm")<br/>      work_dir                     = optional(string, "/tmp/dynamic-deploy")<br/>      helm_dir                     = optional(string, "helm")<br/>      image_tag_set_path           = optional(string, "image.tag")<br/>      migration_image_tag_set_path = optional(string, "job.image.tag")<br/>      base_ref_fallbacks           = optional(list(string), ["main", "master"])<br/>      helm_value_files             = optional(list(string), ["values.yaml", "values.dev.yaml"])<br/>      helm_optional_value_files    = optional(list(string), ["values.dev.<APP_COMPONENT>.yaml"])<br/>      helm_required_value_files    = optional(list(string), ["values.e2e.yaml"])<br/>      helm_migration_value_files   = optional(list(string), ["values.e2e.migration.yaml"])<br/>    }), {})<br/>    cleanup_config = optional(object({<br/>      namespace_prefix      = optional(string, "e2e-")<br/>      max_attempts          = optional(number, 3)<br/>      retry_backoff_seconds = optional(number, 5)<br/>    }), {})<br/>    applications = optional(object({<br/>      defaults = optional(object({<br/>        aws_region          = optional(string, "eu-central-1")<br/>        secret_env          = optional(string, "dev")<br/>        base_ref            = optional(string, "main")<br/>        base_ref_fallbacks  = optional(list(string))<br/>        helm_chart          = optional(string, "dasmeta/base")<br/>        helm_timeout        = optional(string, "40m")<br/>        dynamic_base_domain = optional(string)<br/>        dynamic_env_release = optional(string)<br/>      }), {})<br/>      infra_deployments = optional(any, [])<br/>      deployments = optional(list(object({<br/>        project            = string<br/>        helm_release       = string<br/>        app_component      = string<br/>        helm_version       = string<br/>        db_migration       = optional(bool)<br/>        helm_overrides     = optional(list(string))<br/>        base_ref           = optional(string)<br/>        base_ref_fallbacks = optional(list(string))<br/>        source_environment = optional(string)<br/>        set_build_version  = optional(bool)<br/>      })), [])<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_gitlab_groups"></a> [gitlab\_groups](#input\_gitlab\_groups) | GitLab groups for this module (each entry needs a unique "key"). Each entry must be one of two supported modes:<br/>- managed group: set create = true and provide name + path<br/>- existing group reference: set create = false and provide existing\_group\_id<br/><br/>Projects may resolve their namespace through group\_key, or by the implicit single-group fallback when exactly one<br/>gitlab\_groups entry exists. If this list is empty, every gitlab\_projects item must set namespace\_id directly. | <pre>list(object({<br/>    key               = string                      # Stable id for wiring group_key on projects<br/>    create            = optional(bool, false)       # Create group via API for this entry<br/>    name              = optional(string)            # Display name (required if create is true)<br/>    path              = optional(string)            # URL path (required if create is true)<br/>    description       = optional(string, "")        # Group description<br/>    visibility_level  = optional(string, "private") # private | internal | public<br/>    parent_id         = optional(number)            # Parent namespace id for subgroups<br/>    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true<br/>  }))</pre> | `[]` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | List of GitLab project configurations.<br/><br/>Supported namespace selection paths:<br/>- set namespace\_id directly<br/>- set group\_key to select an entry from var.gitlab\_groups<br/>- omit both namespace\_id and group\_key only when exactly one gitlab\_groups entry exists; that single group is used implicitly<br/><br/>Do not set namespace\_id and group\_key together on the same project.<br/>When gitlab\_groups is empty, set namespace\_id on every project.<br/><br/>Merge behavior (per project; GitLab UI under Settings → Merge requests):<br/><br/>squash\_option — Squash commits when merging:<br/>  - never        → Do not allow (squash disabled; checkbox hidden)<br/>  - default\_off  → Allow (checkbox visible, off by default)<br/>  - default\_on   → Encourage (checkbox visible, on by default)<br/>  - always       → Require (always squash; user cannot disable)<br/><br/>merge\_method — Merge method:<br/>  - merge        → Create a merge commit<br/>  - rebase\_merge → Merge commit with semi-linear history<br/>  - ff           → Fast-forward merge<br/><br/>branch\_protections — Optional list per project: Settings → Repository → Protected branches.<br/>When omitted or set to [], this module creates one default protection for branch "main".<br/>Access is only via merge\_access\_level / push\_access\_level (maintainer, developer, admin, no one).<br/>Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab\_branch\_protection.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>When omitted or set to [], no project approval rule resources are created.<br/>Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>prevent\_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent\_destroy } from this field (dynamic lifecycle is not supported for count/for\_each resources in the same way as static blocks).<br/><br/>ci\_pipeline\_variables\_minimum\_override\_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).<br/>Valid values: no\_one\_allowed, developer, maintainer, owner. Default in type: maintainer.<br/><br/>approval\_rule — Optional per project. Accepts a list of approval rule objects.<br/>If present and non-empty, the module creates one GitLab approval rule resource<br/>per list entry. Defaults are name = "Approval rule", approvals\_required = 1,<br/>applies\_to\_all\_protected\_branches = false (user\_ids / group\_ids optional;<br/>omit approver lists to use GitLab default approvers for the rule).<br/><br/>env\_variables — Per-project CI/CD variables (gitlab\_project\_variable via module ci\_env\_variables), merged with<br/>var.global\_env\_variables; the same key on the project replaces the full global variable definition for that project. | <pre>list(object({<br/>    name                                             = string                         # Project name / slug key used by child resources<br/>    description                                      = optional(string)               # Project description<br/>    visibility_level                                 = optional(string, "private")    # private | internal | public<br/>    default_branch                                   = optional(string, "develop")    # Initial default branch name<br/>    initialize_with_readme                           = optional(bool, true)           # Create repository with README<br/>    request_access_enabled                           = optional(bool, true)           # Allow users to request access<br/>    prevent_destroy                                  = optional(bool, true)           # Contract hint only; not mapped to Terraform lifecycle<br/>    namespace_id                                     = optional(number)               # Explicit GitLab namespace id for the project<br/>    group_key                                        = optional(string)               # Resolve namespace through gitlab_groups[].key<br/>    lfs_enabled                                      = optional(bool, true)           # Enable Git LFS for the project<br/>    packages_enabled                                 = optional(bool, true)           # Enable GitLab package registry<br/>    squash_option                                    = optional(string, "default_on") # never | default_off | default_on | always<br/>    merge_method                                     = optional(string, "merge")      # merge | rebase_merge | ff<br/>    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)           # Require successful pipeline before merge<br/>    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)           # Require resolved discussions before merge<br/>    remove_source_branch_after_merge                 = optional(bool, true)           # Auto-delete source branch after merge<br/>    ci_pipeline_variables_minimum_override_role      = optional(string, "developer")  # no_one_allowed | developer | maintainer | owner<br/>    pages_access_level                               = optional(string, "private")    # GitLab Pages visibility level<br/>    suggestion_commit_message                        = optional(string)               # Suggested squash commit message template<br/>    merge_commit_template                            = optional(string)               # Merge commit message template<br/>    branch_protections = optional(list(object({<br/>      branch                       = string                         # Protected branch name<br/>      merge_access_level           = optional(string, "maintainer") # Merge access role<br/>      push_access_level            = optional(string, "maintainer") # Push access role<br/>      allow_force_push             = optional(bool, false)          # Allow force-push on the branch<br/>      code_owner_approval_required = optional(bool, false)          # Require code-owner approval<br/>      unprotect_access_level       = optional(string, "maintainer") # Unprotect access role<br/>    })), [])<br/>    approval_rule = optional(list(object({<br/>      name                              = optional(string, "Approval rule") # Approval rule display name<br/>      approvals_required                = optional(number, 1)               # Number of approvals required<br/>      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches<br/>      user_ids                          = optional(list(number))            # Explicit approver user ids<br/>      group_ids                         = optional(list(number))            # Explicit approver group ids<br/>    })), [])<br/>    push_rules = optional(list(any), []) # Provider-shaped push rules consumed by gitlab_project.push_rules<br/>    env_variables = optional(list(object({<br/>      key       = string                # CI/CD variable name<br/>      value     = string                # CI/CD variable value<br/>      masked    = optional(bool, false) # Hide value in logs / UI where supported<br/>      protected = optional(bool, false) # Restrict variable to protected refs<br/>    })), [])<br/>    dynamic_environment = optional(object({<br/>      enabled             = optional(bool, false)                                              # Create reusable dynamic environment CI trigger branch/file/MR for this project<br/>      ci_file_path        = optional(string, "ci-pipelines/dynamic-environment.gitlab-ci.yml") # Generated reusable CI file path<br/>      stage               = optional(string, "e2e-test-dynamic")                               # Trigger job stage<br/>      cleanup_stage       = optional(string, "e2e-test-dynamic-clean")                         # Stop job stage<br/>      needs               = optional(list(string), ["deploy"])                                 # Upstream jobs required before trigger job<br/>      source_environment  = optional(string, "dev")                                            # GitLab deployment source environment for tag lookup<br/>      dynamic_env_release = optional(string)                                                   # Release label for DYNAMIC_ENV_RELEASE; defaults to project name<br/>    }), null)<br/>  }))</pre> | n/a | yes |
| <a name="input_global_env_variables"></a> [global\_env\_variables](#input\_global\_env\_variables) | Environment variables applied to every GitLab project. Use for shared NPM\_TOKEN, GITLAB\_TOKEN, etc. | <pre>list(object({<br/>    key       = string                # CI/CD variable name<br/>    value     = string                # Variable value (use masked for secrets)<br/>    masked    = optional(bool, false) # Hide value in job logs / UI where supported<br/>    protected = optional(bool, false) # Available only on protected branches/tags<br/>  }))</pre> | `[]` | no |
| <a name="input_projects_enabled"></a> [projects\_enabled](#input\_projects\_enabled) | When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab\_groups[].create is true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamic_environment_gitlab_agent_cluster_agent_id"></a> [dynamic\_environment\_gitlab\_agent\_cluster\_agent\_id](#output\_dynamic\_environment\_gitlab\_agent\_cluster\_agent\_id) | Registered GitLab Agent ID when registration is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_config_file_path"></a> [dynamic\_environment\_gitlab\_agent\_config\_file\_path](#output\_dynamic\_environment\_gitlab\_agent\_config\_file\_path) | Generated GitLab Agent config file path when agent config generation is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_config_project_id"></a> [dynamic\_environment\_gitlab\_agent\_config\_project\_id](#output\_dynamic\_environment\_gitlab\_agent\_config\_project\_id) | GitLab project ID where the GitLab Agent config is generated when enabled. |
| <a name="output_dynamic_environment_gitlab_agent_helm_release_name"></a> [dynamic\_environment\_gitlab\_agent\_helm\_release\_name](#output\_dynamic\_environment\_gitlab\_agent\_helm\_release\_name) | Helm release name for the installed GitLab Agent when install is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_helm_release_namespace"></a> [dynamic\_environment\_gitlab\_agent\_helm\_release\_namespace](#output\_dynamic\_environment\_gitlab\_agent\_helm\_release\_namespace) | Kubernetes namespace for the installed GitLab Agent when install is enabled. |
| <a name="output_dynamic_environment_gitlab_agent_path"></a> [dynamic\_environment\_gitlab\_agent\_path](#output\_dynamic\_environment\_gitlab\_agent\_path) | GitLab Agent context path referenced by generated dynamic environment CI. |
| <a name="output_dynamic_environment_service_ci_file_paths"></a> [dynamic\_environment\_service\_ci\_file\_paths](#output\_dynamic\_environment\_service\_ci\_file\_paths) | Map of service project name to generated dynamic environment CI trigger file path. |
| <a name="output_dynamic_environments_project_id"></a> [dynamic\_environments\_project\_id](#output\_dynamic\_environments\_project\_id) | GitLab project ID for the central dynamic environments project when enabled. |
| <a name="output_dynamic_environments_project_path"></a> [dynamic\_environments\_project\_path](#output\_dynamic\_environments\_project\_path) | Path with namespace for the central dynamic environments project when enabled. |
| <a name="output_gitlab_group_full_paths"></a> [gitlab\_group\_full\_paths](#output\_gitlab\_group\_full\_paths) | Map of group key to full\_path for groups created by this module (Terraform-managed only; existing groups referenced via existing\_group\_id are not listed here). |
| <a name="output_gitlab_group_ids"></a> [gitlab\_group\_ids](#output\_gitlab\_group\_ids) | Map of group key (from gitlab\_groups) to namespace id for every resolvable configured group — managed groups contribute their created id and existing-group references require existing\_group\_id. |
| <a name="output_gitlab_project_ids"></a> [gitlab\_project\_ids](#output\_gitlab\_project\_ids) | Map of GitLab project name to project ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
