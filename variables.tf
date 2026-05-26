variable "projects_enabled" {
  type        = bool                                                                                                                                                                             # Whether project resources (repos, CI vars, etc.) are created
  default     = true                                                                                                                                                                             # When false, only groups run; project submodule is a no-op
  description = "When false, skips creating GitLab projects and project-scoped child resources (for example CI variables). GitLab groups are still created when gitlab_groups[].create is true." # registry / docs
}

variable "gitlab_groups" {
  type = list(object({
    key               = string                      # Stable id for wiring group_key on projects
    create            = optional(bool, false)       # Create group via API for this entry
    name              = optional(string)            # Display name (required if create is true)
    path              = optional(string)            # URL path (required if create is true)
    description       = optional(string, "")        # Group description
    visibility_level  = optional(string, "private") # private | internal | public
    parent_id         = optional(number)            # Parent namespace id for subgroups
    existing_group_id = optional(number)            # Existing GitLab group id (namespace id) when create is false; ignored when create is true
  }))
  default     = []
  description = <<-EOT
    GitLab groups for this module (each entry needs a unique "key"). Each entry must be one of two supported modes:
    - managed group: set create = true and provide name + path
    - existing group reference: set create = false and provide existing_group_id

    Projects may resolve their namespace through group_key, or by the implicit single-group fallback when exactly one
    gitlab_groups entry exists. If this list is empty, every gitlab_projects item must set namespace_id directly.
  EOT

  validation {
    condition     = length(var.gitlab_groups) == 0 || length(distinct([for g in var.gitlab_groups : g.key])) == length(var.gitlab_groups) # Unique keys
    error_message = "gitlab_groups: each entry must have a unique \"key\"."                                                               # Shown when keys collide
  }

  validation {
    condition = alltrue([
      for g in var.gitlab_groups :
      !g.create || (try(g.name, null) != null && try(g.path, null) != null)
    ])
    error_message = "When gitlab_groups[].create is true, name and path are required."
  }

  validation {
    condition = alltrue([
      for g in var.gitlab_groups :
      g.create || try(g.existing_group_id, null) != null
    ])
    error_message = "When gitlab_groups[].create is false, existing_group_id is required."
  }
}

# -----------------------------------------------------------------------------
# Global settings applied to all projects (e.g. shared CI tokens)
# -----------------------------------------------------------------------------

variable "global_env_variables" {
  type = list(object({
    key       = string                # CI/CD variable name
    value     = string                # Variable value (use masked for secrets)
    masked    = optional(bool, false) # Hide value in job logs / UI where supported
    protected = optional(bool, false) # Available only on protected branches/tags
  }))
  default     = []
  description = "Environment variables applied to every GitLab project. Use for shared NPM_TOKEN, GITLAB_TOKEN, etc."
}

variable "dynamic_environments_project" {
  type = object({
    enabled                = optional(bool, false)
    name                   = optional(string)
    description            = optional(string, "Dynamic environments orchestration")
    visibility_level       = optional(string, "private")
    default_branch         = optional(string, "main")
    initialize_with_readme = optional(bool, true)
    namespace_id           = optional(number)
    group_key              = optional(string)
    source_branch          = optional(string, "feature/dynamic-environments")
    mr_title               = optional(string, "Add dynamic environments orchestration")
    gitlab_api_url         = optional(string, "https://gitlab.com/api/v4")
    gitlab_agent_path      = optional(string)
    cluster_name           = optional(string, "eks-dev")
    deploy_mode            = optional(string, "aws_eks")
    runner_tags            = optional(list(string), ["k8s-runner"])
    gitlab_agent = optional(object({
      enabled             = optional(bool, false)                              # Generate .gitlab/agents/<agent-name>/config.yaml when true
      name                = optional(string)                                   # GitLab Agent name; defaults to dynamic_environments_project.cluster_name
      config_project_name = optional(string)                                   # Optional managed gitlab_projects[].name that receives config.yaml; omit to use the dynamic environments project
      config_project_id   = optional(string)                                   # Optional external/existing GitLab project ID that receives config.yaml
      config_project_path = optional(string)                                   # Required with config_project_id unless dynamic_environments_project.gitlab_agent_path is set; used for <project-path>:<agent-name>
      source_branch       = optional(string, "feature/gitlab-agent-config")    # Branch where Terraform writes generated GitLab Agent config
      target_branch       = optional(string, "main")                           # Merge request target branch for generated GitLab Agent config
      mr_title            = optional(string, "Add GitLab Agent configuration") # Merge request title for generated GitLab Agent config
      config_file_path    = optional(string)                                   # Optional file path; defaults to .gitlab/agents/<agent-name>/config.yaml
      register_agent      = optional(bool, false)                              # Create gitlab_cluster_agent and token when true
      token_name          = optional(string)                                   # Optional GitLab Agent token name; defaults to <agent-name>-token
      token_description   = optional(string)                                   # Optional GitLab Agent token description
      install = optional(object({
        enabled          = optional(bool, false)                        # Install the GitLab Agent Helm chart; requires register_agent = true
        release_name     = optional(string)                             # Helm release name; defaults to agent name
        namespace        = optional(string)                             # Kubernetes namespace; defaults to gitlab-agent-<agent-name>
        create_namespace = optional(bool, true)                         # Let Helm create the namespace
        repository       = optional(string, "https://charts.gitlab.io") # Helm repository for the GitLab Agent chart
        chart            = optional(string, "gitlab-agent")             # Helm chart name
        chart_version    = optional(string)                             # Optional Helm chart version pin
        kas_address      = optional(string, "wss://kas.gitlab.com")     # GitLab KAS websocket address passed to chart config.kasAddress
        timeout          = optional(number, 300)                        # Helm operation timeout in seconds
        wait             = optional(bool, true)                         # Wait for Helm resources to become ready
        atomic           = optional(bool, false)                        # Roll back failed Helm install/upgrade
        values           = optional(list(string), [])                   # Raw Helm values YAML strings
        set_values = optional(list(object({
          name  = string           # Helm set name
          value = string           # Helm set value
          type  = optional(string) # Optional Helm set type
        })), [])
      }), {})
      ci_access = optional(object({
        instance = optional(bool, false) # Render ci_access.instance when true
        projects = optional(list(object({
          id                      = string                 # Project path or ID allowed to use this agent from CI
          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions
          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction
          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry
        })), [])
        groups = optional(list(object({
          id                      = string                 # Group path or ID allowed to use this agent from CI
          environments            = optional(list(string)) # Optional GitLab Agent environment restrictions
          protected_branches_only = optional(bool)         # Optional GitLab protected-branch restriction
          access_as_ci_job        = optional(bool, false)  # Render access_as.ci_job for this CI access entry
        })), [])
      }), {})
      user_access = optional(object({
        access_as_agent = optional(bool) # Render user_access.access_as.agent; defaults to true when user_access.projects is non-empty
        projects = optional(list(object({
          id = string # Project path or ID allowed to access Kubernetes through this agent as a user
        })), [])
      }), {})
    }), {})
    deploy_config = optional(object({
      aws_region                   = optional(string, "us-east-2")
      namespace_prefix             = optional(string, "e2e-")
      fallback_image_tag           = optional(string, "latest")
      gitlab_api_timeout_seconds   = optional(number, 20)
      gitlab_api_url               = optional(string)
      gitlab_clone_base_url        = optional(string, "https://gitlab.com")
      helm_repo_name               = optional(string, "dasmeta")
      helm_repo_url                = optional(string, "https://dasmeta.github.io/helm")
      work_dir                     = optional(string, "/tmp/dynamic-deploy")
      helm_dir                     = optional(string, "helm")
      image_tag_set_path           = optional(string, "image.tag")
      migration_image_tag_set_path = optional(string, "job.image.tag")
      base_ref_fallbacks           = optional(list(string), ["main", "master"])
      helm_value_files             = optional(list(string), ["values.yaml", "values.dev.yaml"])
      helm_optional_value_files    = optional(list(string), ["values.dev.<APP_COMPONENT>.yaml"])
      helm_required_value_files    = optional(list(string), ["values.e2e.yaml"])
      helm_migration_value_files   = optional(list(string), ["values.e2e.migration.yaml"])
    }), {})
    cleanup_config = optional(object({
      namespace_prefix      = optional(string, "e2e-")
      max_attempts          = optional(number, 3)
      retry_backoff_seconds = optional(number, 5)
    }), {})
    applications = optional(object({
      defaults = optional(object({
        aws_region          = optional(string, "eu-central-1")
        secret_env          = optional(string, "dev")
        base_ref            = optional(string, "main")
        base_ref_fallbacks  = optional(list(string))
        helm_chart          = optional(string, "dasmeta/base")
        helm_timeout        = optional(string, "40m")
        dynamic_base_domain = optional(string)
        dynamic_env_release = optional(string)
      }), {})
      infra_deployments = optional(any, [])
      deployments = optional(list(object({
        project            = string
        helm_release       = string
        app_component      = string
        helm_version       = string
        db_migration       = optional(bool)
        helm_overrides     = optional(list(string))
        base_ref           = optional(string)
        base_ref_fallbacks = optional(list(string))
        source_environment = optional(string)
        set_build_version  = optional(bool)
      })), [])
    }), null)
  })
  default     = {}
  description = <<-EOT
    Optional central GitLab project for dynamic environments orchestration.
    When enabled, the module creates a project, generates orchestration files on
    source_branch, and opens a merge request to default_branch. The applications
    object renders to config/applications.yaml.
  EOT

  validation {
    condition     = !var.dynamic_environments_project.enabled || try(var.dynamic_environments_project.name, null) != null
    error_message = "dynamic_environments_project.name is required when dynamic_environments_project.enabled is true."
  }

  validation {
    condition = !(
      try(var.dynamic_environments_project.namespace_id, null) != null &&
      try(var.dynamic_environments_project.group_key, null) != null
    )
    error_message = "Set either dynamic_environments_project.namespace_id or dynamic_environments_project.group_key, but not both."
  }

  validation {
    condition     = !var.dynamic_environments_project.enabled || try(var.dynamic_environments_project.applications, null) != null
    error_message = "dynamic_environments_project.applications is required when dynamic_environments_project.enabled is true."
  }

  validation {
    condition = try(alltrue([
      for deployment in try(var.dynamic_environments_project.applications.infra_deployments, []) : (
        can(tostring(deployment.release)) &&
        trimspace(tostring(deployment.release)) != "" &&
        can(tostring(deployment.chart)) &&
        trimspace(tostring(deployment.chart)) != "" &&
        can(tostring(deployment.version)) &&
        trimspace(tostring(deployment.version)) != "" &&
        (try(deployment.repo_name, null) == null || can(tostring(deployment.repo_name))) &&
        (try(deployment.repo_url, null) == null || can(tostring(deployment.repo_url)))
      )
    ]), false)
    error_message = "dynamic_environments_project.applications.infra_deployments must be a list of objects with non-empty release, chart, and version strings; repo_name and repo_url must be strings when set."
  }

  validation {
    condition = contains(
      ["aws_eks", "gitlab_agent"],
      try(var.dynamic_environments_project.deploy_mode, "aws_eks")
    )
    error_message = "dynamic_environments_project.deploy_mode must be one of: aws_eks, gitlab_agent."
  }

  validation {
    condition = !(
      try(var.dynamic_environments_project.gitlab_agent.enabled, false) &&
      try(var.dynamic_environments_project.gitlab_agent.config_project_id, null) != null &&
      try(var.dynamic_environments_project.gitlab_agent.config_project_name, null) != null
    )
    error_message = "Set either dynamic_environments_project.gitlab_agent.config_project_id or config_project_name, but not both."
  }

  validation {
    condition = !try(var.dynamic_environments_project.gitlab_agent.enabled, false) || (
      length(trimspace(coalesce(try(var.dynamic_environments_project.gitlab_agent.name, null), try(var.dynamic_environments_project.cluster_name, "eks-dev")))) > 0 &&
      length(trimspace(try(var.dynamic_environments_project.gitlab_agent.source_branch, "feature/gitlab-agent-config"))) > 0 &&
      length(trimspace(try(var.dynamic_environments_project.gitlab_agent.target_branch, "main"))) > 0
    )
    error_message = "When dynamic_environments_project.gitlab_agent.enabled is true, agent name, source_branch, and target_branch must be non-empty."
  }

  validation {
    condition = !(
      try(var.dynamic_environments_project.gitlab_agent.enabled, false) &&
      try(var.dynamic_environments_project.gitlab_agent.install.enabled, false) &&
      !try(var.dynamic_environments_project.gitlab_agent.register_agent, false)
    )
    error_message = "dynamic_environments_project.gitlab_agent.register_agent must be true when gitlab_agent.install.enabled is true."
  }

  validation {
    condition = !(
      try(var.dynamic_environments_project.gitlab_agent.enabled, false) &&
      try(var.dynamic_environments_project.gitlab_agent.config_project_id, null) != null &&
      try(var.dynamic_environments_project.gitlab_agent.config_project_path, null) == null &&
      try(var.dynamic_environments_project.gitlab_agent_path, null) == null
    )
    error_message = "When gitlab_agent.config_project_id is used, set gitlab_agent.config_project_path or dynamic_environments_project.gitlab_agent_path so the generated CI can reference the agent context."
  }
}

variable "gitlab_projects" {
  type = list(object({
    name                                             = string                         # Project name / slug key used by child resources
    description                                      = optional(string)               # Project description
    visibility_level                                 = optional(string, "private")    # private | internal | public
    default_branch                                   = optional(string, "develop")    # Initial default branch name
    initialize_with_readme                           = optional(bool, true)           # Create repository with README
    request_access_enabled                           = optional(bool, true)           # Allow users to request access
    prevent_destroy                                  = optional(bool, true)           # Contract hint only; not mapped to Terraform lifecycle
    namespace_id                                     = optional(number)               # Explicit GitLab namespace id for the project
    group_key                                        = optional(string)               # Resolve namespace through gitlab_groups[].key
    lfs_enabled                                      = optional(bool, true)           # Enable Git LFS for the project
    packages_enabled                                 = optional(bool, true)           # Enable GitLab package registry
    squash_option                                    = optional(string, "default_on") # never | default_off | default_on | always
    merge_method                                     = optional(string, "merge")      # merge | rebase_merge | ff
    only_allow_merge_if_pipeline_succeeds            = optional(bool, true)           # Require successful pipeline before merge
    only_allow_merge_if_all_discussions_are_resolved = optional(bool, true)           # Require resolved discussions before merge
    remove_source_branch_after_merge                 = optional(bool, true)           # Auto-delete source branch after merge
    ci_pipeline_variables_minimum_override_role      = optional(string, "developer")  # no_one_allowed | developer | maintainer | owner
    pages_access_level                               = optional(string, "private")    # GitLab Pages visibility level
    suggestion_commit_message                        = optional(string)               # Suggested squash commit message template
    merge_commit_template                            = optional(string)               # Merge commit message template
    branch_protections = optional(list(object({
      branch                       = string                         # Protected branch name
      merge_access_level           = optional(string, "maintainer") # Merge access role
      push_access_level            = optional(string, "maintainer") # Push access role
      allow_force_push             = optional(bool, false)          # Allow force-push on the branch
      code_owner_approval_required = optional(bool, false)          # Require code-owner approval
      unprotect_access_level       = optional(string, "maintainer") # Unprotect access role
    })), [])
    approval_rule = optional(list(object({
      name                              = optional(string, "Approval rule") # Approval rule display name
      approvals_required                = optional(number, 1)               # Number of approvals required
      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches
      user_ids                          = optional(list(number))            # Explicit approver user ids
      group_ids                         = optional(list(number))            # Explicit approver group ids
    })), [])
    push_rules = optional(list(any), []) # Provider-shaped push rules consumed by gitlab_project.push_rules
    env_variables = optional(list(object({
      key       = string                # CI/CD variable name
      value     = string                # CI/CD variable value
      masked    = optional(bool, false) # Hide value in logs / UI where supported
      protected = optional(bool, false) # Restrict variable to protected refs
    })), [])
    dynamic_environment = optional(object({
      enabled             = optional(bool, false)                                              # Create reusable dynamic environment CI trigger branch/file/MR for this project
      ci_file_path        = optional(string, "ci-pipelines/dynamic-environment.gitlab-ci.yml") # Generated reusable CI file path
      stage               = optional(string, "e2e-test-dynamic")                               # Trigger job stage
      cleanup_stage       = optional(string, "e2e-test-dynamic-clean")                         # Stop job stage
      needs               = optional(list(string), ["deploy"])                                 # Upstream jobs required before trigger job
      source_environment  = optional(string, "dev")                                            # GitLab deployment source environment for tag lookup
      dynamic_env_release = optional(string)                                                   # Release label for DYNAMIC_ENV_RELEASE; defaults to project name
    }), null)
    build_pipeline = optional(object({
      tags = optional(list(string), []) # Optional runner tags for the hidden .build template
      build_image = optional(object({
        name       = optional(string, "amazon/aws-cli:2.28.8")
        entrypoint = optional(list(string), [""])
      }), {})
      build_services = optional(list(object({
        name       = string
        entrypoint = optional(list(string))
        command    = optional(list(string))
        })), [
        {
          name       = "docker:dind"
          entrypoint = ["env", "-u", "DOCKER_HOST"]
          command    = ["dockerd-entrypoint.sh", "--tls=false"]
        }
      ])
    }), {}) # Reusable CI pipeline config; generated by default unless explicitly set to null
    deploy_pipeline = optional(object({
      tags = optional(list(string), []) # Optional runner tags for the hidden .deploy template
      deploy_image = optional(object({
        name       = optional(string, "alpine/k8s:1.20.15")
        entrypoint = optional(list(string), ["/bin/sh", "-c"])
      }), {})
    }), {}) # Reusable CI pipeline config; generated by default unless explicitly set to null
  }))
  description = <<-EOT
    List of GitLab project configurations.

    Supported namespace selection paths:
    - set namespace_id directly
    - set group_key to select an entry from var.gitlab_groups
    - omit both namespace_id and group_key only when exactly one gitlab_groups entry exists; that single group is used implicitly

    Do not set namespace_id and group_key together on the same project.
    When gitlab_groups is empty, set namespace_id on every project.

    Merge behavior (per project; GitLab UI under Settings → Merge requests):

    squash_option — Squash commits when merging:
      - never        → Do not allow (squash disabled; checkbox hidden)
      - default_off  → Allow (checkbox visible, off by default)
      - default_on   → Encourage (checkbox visible, on by default)
      - always       → Require (always squash; user cannot disable)

    merge_method — Merge method:
      - merge        → Create a merge commit
      - rebase_merge → Merge commit with semi-linear history
      - ff           → Fast-forward merge

    branch_protections — Optional list per project: Settings → Repository → Protected branches.
    When omitted or set to [], this module creates one default protection for branch "main".
    Access is only via merge_access_level / push_access_level (maintainer, developer, admin, no one).
    Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab_branch_protection.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    When omitted or set to [], no project approval rule resources are created.
    Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    ci_pipeline_variables_minimum_override_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).
    Valid values: no_one_allowed, developer, maintainer, owner. Default in type: maintainer.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    If present and non-empty, the module creates one GitLab approval rule resource
    per list entry. Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project replaces the full global variable definition for that project.

    build_pipeline — Per-project reusable CI pipeline config. When omitted, the module uses
    defaults and still generates ci-pipelines/build.gitlab-ci.yml through the
    gitlab_ci_pipelines submodule. Set this field to null to disable generated build CI for a project.
    The generated file contains one hidden .build template. Concrete jobs stay
    consumer-managed in root CI config through include + extends, while build
    behavior is configured through variables such as BUILD_MODE,
    REGISTRY_PROVIDER, IMAGE_REPOSITORY, IMAGE_TAG, DOCKERFILE_PATH,
    BUILD_CONTEXT, BUILD_PRE_SCRIPT, BUILD_SETUP_SCRIPT, and BUILD_COMMAND.

    deploy_pipeline — Per-project reusable CI pipeline config. When omitted, the module uses
    defaults and still generates ci-pipelines/deploy.gitlab-ci.yml through the
    gitlab_ci_pipelines submodule. Set this field to null to disable generated deploy CI for a project.
    The generated file contains one hidden .deploy template. Concrete deploy jobs
    stay consumer-managed in root CI config through include + extends, while
    deploy behavior is configured through variables such as KUBE_CONTEXT,
    AWS_EKS_CLUSTER_NAME, AWS_REGION, KUBE_NAMESPACE, HELM_RELEASE,
    HELM_CHART, HELM_CHART_VERSION, HELM_VALUES_ARGS, HELM_SET_ARGS,
    HELM_EXTRA_ARGS, DEPLOY_IMAGE_REPOSITORY, and DEPLOY_IMAGE_TAG.
    When gitlab_projects[].dynamic_environment.enabled = true, the hidden
    .deploy template also renders a GitLab environment block. Set
    DEPLOY_ENVIRONMENT_NAME, DEPLOY_ENVIRONMENT_KUBERNETES_AGENT, and
    DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE in the concrete deploy job from the
    root .gitlab-ci.yml.
  EOT

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      contains(["no_one_allowed", "developer", "maintainer", "owner"], p.ci_pipeline_variables_minimum_override_role)
    ])
    error_message = "gitlab_projects[].ci_pipeline_variables_minimum_override_role must be one of: no_one_allowed, developer, maintainer, owner."
  }

  validation {
    condition = length(var.gitlab_projects) == 0 || length(var.gitlab_groups) > 0 || alltrue([
      for p in var.gitlab_projects : try(p.namespace_id, null) != null
    ])
    error_message = "When gitlab_groups is empty, set namespace_id on every gitlab_projects entry."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      !(try(p.namespace_id, null) != null && try(p.group_key, null) != null)
    ])
    error_message = "Set either namespace_id or group_key for a project, but not both."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.group_key, null) == null || contains([for g in var.gitlab_groups : g.key], p.group_key)
    ])
    error_message = "gitlab_projects[].group_key must match a declared gitlab_groups[].key."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.namespace_id, null) != null ? true : (
        length(var.gitlab_groups) == 0 ? false : length([
          for g in var.gitlab_groups : g.key
          if g.key == coalesce(
            try(p.group_key, null),
            length(var.gitlab_groups) == 1 ? var.gitlab_groups[0].key : "__UNRESOLVED_GROUP_KEY__"
          ) && (g.create || try(g.existing_group_id, null) != null)
        ]) == 1
      )
    ])
    error_message = "Each project must resolve deterministically through namespace_id, a valid group_key, or the implicit single-group fallback backed by a creatable or existing group id."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.dynamic_environment.enabled, false) == false || length(trimspace(try(p.dynamic_environment.ci_file_path, ""))) > 0
    ])
    error_message = "gitlab_projects[].dynamic_environment.ci_file_path must be non-empty when dynamic_environment.enabled is true."
  }

}

locals {
  dynamic_environment_service_enabled = anytrue([
    for p in var.gitlab_projects : try(p.dynamic_environment.enabled, false)
  ])
}

check "dynamic_environment_central_project_required" {
  assert {
    condition     = !local.dynamic_environment_service_enabled || var.dynamic_environments_project.enabled
    error_message = "dynamic_environments_project.enabled must be true when any gitlab_projects[].dynamic_environment.enabled is true."
  }
}
