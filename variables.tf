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
      enabled             = optional(bool, false)
      name                = optional(string)
      config_project_name = optional(string)
      config_project_id   = optional(string)
      config_project_path = optional(string)
      source_branch       = optional(string, "feature/gitlab-agent-config")
      target_branch       = optional(string, "main")
      mr_title            = optional(string, "Add GitLab Agent configuration")
      config_file_path    = optional(string)
      register_agent      = optional(bool, false)
      token_name          = optional(string)
      token_description   = optional(string)
      install = optional(object({
        enabled          = optional(bool, false)
        release_name     = optional(string)
        namespace        = optional(string)
        create_namespace = optional(bool, true)
        repository       = optional(string, "https://charts.gitlab.io")
        chart            = optional(string, "gitlab-agent")
        chart_version    = optional(string)
        kas_address      = optional(string, "wss://kas.gitlab.com")
        timeout          = optional(number, 300)
        wait             = optional(bool, true)
        atomic           = optional(bool, false)
        values           = optional(list(string), [])
        set_values = optional(list(object({
          name  = string
          value = string
          type  = optional(string)
        })), [])
      }), {})
      ci_access = optional(object({
        instance = optional(bool, false)
        projects = optional(list(object({
          id                      = string
          environments            = optional(list(string))
          protected_branches_only = optional(bool)
          access_as_ci_job        = optional(bool, false)
        })), [])
        groups = optional(list(object({
          id                      = string
          environments            = optional(list(string))
          protected_branches_only = optional(bool)
          access_as_ci_job        = optional(bool, false)
        })), [])
      }), {})
      user_access = optional(object({
        access_as_agent = optional(bool)
        projects = optional(list(object({
          id = string
        })), [])
      }), {})
    }), {})
    deploy_config = optional(object({
      aws_region                   = optional(string, "eu-central-1")
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
    squash_commit_template                           = optional(string)               # Squash commit message template
    merge_requests_template                          = optional(string)               # Default merge request description template
    resolve_outdated_diff_discussions                = optional(bool)                 # Automatically resolve outdated diff discussions
    branch_protections_enabled                       = optional(bool, true)           # Create branch protection resources for this project
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
      enabled             = optional(bool, false)
      ci_file_path        = optional(string, "ci-pipelines/dynamic-environment.gitlab-ci.yml")
      stage               = optional(string, "e2e-test-dynamic")
      cleanup_stage       = optional(string, "e2e-test-dynamic-clean")
      needs               = optional(list(string), ["deploy"])
      source_environment  = optional(string, "dev")
      dynamic_env_release = optional(string)
    }), null)
    gitlab_ci_pipelines = optional(list(object({
      type                 = string                                           # Supported types: build_ecr, deploy_agent
      create_merge_request = optional(bool, true)                             # Open a merge request instead of committing directly to the target branch
      merge_request_title  = optional(string)                                 # Merge request title; defaults to the pipeline commit message
      remove_source_branch = optional(bool, true)                             # Remove source branch after merge
      commit_message       = optional(string)                                 # Commit message for the repository file change
      file_path            = optional(string)                                 # Defaults according to pipeline type
      job_name             = optional(string)                                 # Defaults according to pipeline type
      template_project     = optional(string, "das-meta/gitlab-ci-templates") # Project containing reusable templates
      template_ref         = optional(string, "DMVP-1150")                    # Template branch/tag/sha to include
      template_file        = optional(string)                                 # Defaults according to pipeline type
      variables            = optional(map(string), {})                        # Pipeline-type-specific variables in snake_case
    })), [])
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
    Access is only via merge_access_level / push_access_level / unprotect_access_level (maintainer, developer, admin, no one).
    Granular "specific users/groups" rows from the GitLab UI are not supported by provider resource gitlab_branch_protection.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    When omitted or set to [], no project approval rule resources are created.
    Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    prevent_destroy — Contract hint for operators and downstream tooling only; this module does not set Terraform lifecycle { prevent_destroy } from this field (dynamic lifecycle is not supported for count/for_each resources in the same way as static blocks).

    ci_pipeline_variables_minimum_override_role — CI/CD → Variables: minimum role that may run a new pipeline with pipeline variables (GitLab 17.1+).
    Valid values: no_one_allowed, developer, maintainer, owner. Default in type: maintainer.

    merge_requests_template — Merge requests: default description template for new merge requests in the project.
    Omit this field to leave the project setting unmanaged by this module.

    approval_rule — Optional per project. Accepts a list of approval rule objects.
    If present and non-empty, the module creates one GitLab approval rule resource
    per list entry. Defaults are name = "Approval rule", approvals_required = 1,
    applies_to_all_protected_branches = false (user_ids / group_ids optional;
    omit approver lists to use GitLab default approvers for the rule).

    env_variables — Per-project CI/CD variables (gitlab_project_variable via module ci_env_variables), merged with
    var.global_env_variables; the same key on the project replaces the full global variable definition for that project.

    dynamic_environment — Per-project dynamic environment CI trigger generation. When enabled,
    dynamic_environments_project.enabled must also be true.

    gitlab_ci_pipelines — Optional per-project generated repository files under ci-pipelines/.
    For type = "build_ecr", the module writes ci-pipelines/build-gitlab.ci.yaml with an include of
    das-meta/gitlab-ci-templates and a concrete job that extends the reusable .build template while passing
    ECR/buildx variables. build_ecr requires variables.aws_region and variables.image_repository.

    For type = "deploy_agent", the module writes ci-pipelines/deploy-gitlab.ci.yaml with an include of
    the reusable GitLab Agent deploy template and a concrete job that extends .deploy. deploy_agent requires
    environment, agent, namespace, release, and chart variables.
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
      try(p.group_key, null) == null || contains([for g in var.gitlab_groups : g.key], coalesce(try(p.group_key, null), "__UNRESOLVED_GROUP_KEY__"))
    ])
    error_message = "gitlab_projects[].group_key must match a declared gitlab_groups[].key."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        contains(["build_ecr", "deploy_agent"], pipeline.type)
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[].type must be one of: build_ecr, deploy_agent."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        pipeline.type != "build_ecr" || (
          contains(keys(try(pipeline.variables, {})), "aws_region") &&
          contains(keys(try(pipeline.variables, {})), "image_repository")
        )
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[] with type build_ecr must set variables.aws_region and variables.image_repository."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        pipeline.type != "deploy_agent" || alltrue([
          for variable_name in [
            "deploy_environment_name",
            "deploy_environment_kubernetes_agent",
            "deploy_environment_dashboard_namespace",
            "kube_namespace",
            "helm_release",
            "helm_chart",
            ] : (
            contains(keys(try(pipeline.variables, {})), variable_name) &&
            length(trimspace(try(pipeline.variables[variable_name], ""))) > 0
          )
        ])
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[] with type deploy_agent must set variables.deploy_environment_name, deploy_environment_kubernetes_agent, deploy_environment_dashboard_namespace, kube_namespace, helm_release, and helm_chart."
  }

  validation {
    condition = alltrue([
      for p in var.gitlab_projects :
      try(p.dynamic_environment.enabled, false) == false || length(trimspace(try(p.dynamic_environment.ci_file_path, ""))) > 0
    ])
    error_message = "gitlab_projects[].dynamic_environment.ci_file_path must be non-empty when dynamic_environment.enabled is true."
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
