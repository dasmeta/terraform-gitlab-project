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
    enabled                = optional(bool, false)                                      # Create and configure the central dynamic environments project
    name                   = optional(string)                                           # Central project name; required when enabled
    description            = optional(string, "Dynamic environments orchestration")     # Central project description
    visibility_level       = optional(string, "private")                                # private | internal | public
    default_branch         = optional(string, "main")                                   # Target and default branch for generated configuration
    initialize_with_readme = optional(bool, true)                                       # Initialize the central project with a README
    namespace_id           = optional(number)                                           # Explicit GitLab namespace id for the central project
    group_key              = optional(string)                                           # Resolve namespace through gitlab_groups[].key
    source_branch          = optional(string, "feature/dynamic-environments")           # Source branch used for generated orchestration files
    mr_title               = optional(string, "Add dynamic environments orchestration") # Merge request title for orchestration changes
    gitlab_api_url         = optional(string, "https://gitlab.com/api/v4")              # GitLab API base URL used by generated jobs
    gitlab_agent_path      = optional(string)                                           # GitLab Agent context path used by generated CI
    cluster_name           = optional(string, "eks-dev")                                # Kubernetes cluster name used by deployment jobs
    deploy_mode            = optional(string, "aws_eks")                                # Deployment integration mode: aws_eks | gitlab_agent
    runner_tags            = optional(list(string), ["k8s-runner"])                     # GitLab runner tags assigned to generated jobs
    gitlab_agent = optional(object({                                                    # GitLab Agent configuration, registration, installation, and access settings
      enabled             = optional(bool, false)                                       # Generate and optionally register GitLab Agent configuration
      name                = optional(string)                                            # Agent name; falls back to cluster_name when omitted
      config_project_name = optional(string)                                            # Managed project name that stores the agent configuration
      config_project_id   = optional(string)                                            # Existing project id that stores the agent configuration
      config_project_path = optional(string)                                            # Full namespace/project path for an existing config project
      source_branch       = optional(string, "feature/gitlab-agent-config")             # Source branch for generated agent configuration
      target_branch       = optional(string, "main")                                    # Merge request target branch for agent configuration
      mr_title            = optional(string, "Add GitLab Agent configuration")          # Merge request title for agent configuration changes
      config_file_path    = optional(string)                                            # Repository path for the generated agent config.yaml
      register_agent      = optional(bool, false)                                       # Register the agent and create an authentication token
      token_name          = optional(string)                                            # Name assigned to the generated agent token
      token_description   = optional(string)                                            # Description assigned to the generated agent token
      install = optional(object({                                                       # Helm installation settings for the GitLab Agent
        enabled          = optional(bool, false)                                        # Install the GitLab Agent Helm chart
        release_name     = optional(string)                                             # Helm release name for the agent installation
        namespace        = optional(string)                                             # Kubernetes namespace for the Helm release
        create_namespace = optional(bool, true)                                         # Create the Kubernetes namespace when missing
        repository       = optional(string, "https://charts.gitlab.io")                 # Helm repository containing the agent chart
        chart            = optional(string, "gitlab-agent")                             # Helm chart name
        chart_version    = optional(string)                                             # Helm chart version; provider default when omitted
        kas_address      = optional(string, "wss://kas.gitlab.com")                     # GitLab Kubernetes Agent Server WebSocket address
        timeout          = optional(number, 300)                                        # Helm operation timeout in seconds
        wait             = optional(bool, true)                                         # Wait for Helm resources to become ready
        atomic           = optional(bool, false)                                        # Roll back the Helm release when installation fails
        values           = optional(list(string), [])                                   # Additional YAML values passed to the Helm release
        set_values = optional(list(object({                                             # Additional individual Helm values
          name  = string                                                                # Helm value key passed through a set block
          value = string                                                                # Helm value assigned to the key
          type  = optional(string)                                                      # Helm set value type, such as string or auto
        })), [])
      }), {})
      ci_access = optional(object({                        # CI/CD identities allowed to use the agent
        instance = optional(bool, false)                   # Allow CI jobs from all projects in the GitLab instance
        projects = optional(list(object({                  # Project-specific CI access entries
          id                      = string                 # Project id or full path allowed to access the agent
          environments            = optional(list(string)) # Restrict access to the listed GitLab environments
          protected_branches_only = optional(bool)         # Restrict access to jobs running on protected branches
          access_as_ci_job        = optional(bool, false)  # Authenticate access as the CI job identity
        })), [])
        groups = optional(list(object({                    # Group-specific CI access entries
          id                      = string                 # Group id or full path allowed to access the agent
          environments            = optional(list(string)) # Restrict access to the listed GitLab environments
          protected_branches_only = optional(bool)         # Restrict access to jobs running on protected branches
          access_as_ci_job        = optional(bool, false)  # Authenticate access as the CI job identity
        })), [])
      }), {})
      user_access = optional(object({     # Interactive user access configuration
        access_as_agent = optional(bool)  # Authenticate users through the agent identity
        projects = optional(list(object({ # Projects whose users may access the agent
          id = string                     # Project id or full path whose users may access the agent
        })), [])
      }), {})
    }), {})
    deploy_config = optional(object({                                                            # Defaults used by generated dynamic deployment jobs
      aws_region                   = optional(string, "eu-central-1")                            # AWS region used by generated deployment jobs
      namespace_prefix             = optional(string, "e2e-")                                    # Prefix for dynamic Kubernetes namespaces
      fallback_image_tag           = optional(string, "latest")                                  # Image tag used when no build version is available
      gitlab_api_timeout_seconds   = optional(number, 20)                                        # Timeout for GitLab API requests in generated scripts
      gitlab_api_url               = optional(string)                                            # Override GitLab API URL for deployment jobs
      gitlab_clone_base_url        = optional(string, "https://gitlab.com")                      # Base URL used to clone GitLab repositories
      helm_repo_name               = optional(string, "dasmeta")                                 # Helm repository alias used by generated jobs
      helm_repo_url                = optional(string, "https://dasmeta.github.io/helm")          # Helm repository URL used by generated jobs
      work_dir                     = optional(string, "/tmp/dynamic-deploy")                     # Temporary working directory in deployment jobs
      helm_dir                     = optional(string, "helm")                                    # Repository directory containing Helm values
      image_tag_set_path           = optional(string, "image.tag")                               # Helm value path for the application image tag
      migration_image_tag_set_path = optional(string, "job.image.tag")                           # Helm value path for the migration image tag
      base_ref_fallbacks           = optional(list(string), ["main", "master"])                  # Fallback Git refs used when the requested ref is unavailable
      helm_value_files             = optional(list(string), ["values.yaml", "values.dev.yaml"])  # Default Helm values files loaded for deployments
      helm_optional_value_files    = optional(list(string), ["values.dev.<APP_COMPONENT>.yaml"]) # Component-specific values files loaded when present
      helm_required_value_files    = optional(list(string), ["values.e2e.yaml"])                 # Values files that must exist for dynamic deployments
      helm_migration_value_files   = optional(list(string), ["values.e2e.migration.yaml"])       # Additional values files used for migration jobs
    }), {})
    cleanup_config = optional(object({                 # Dynamic environment cleanup behavior
      namespace_prefix      = optional(string, "e2e-") # Prefix identifying dynamic namespaces eligible for cleanup
      max_attempts          = optional(number, 3)      # Maximum cleanup attempts before failing the job
      retry_backoff_seconds = optional(number, 5)      # Delay in seconds between cleanup attempts
    }), {})
    applications = optional(object({                           # Application and infrastructure deployment catalog
      defaults = optional(object({                             # Shared defaults applied to application deployment entries
        aws_region          = optional(string, "eu-central-1") # Default AWS region for application deployments
        secret_env          = optional(string, "dev")          # Default environment name used to resolve application secrets
        base_ref            = optional(string, "main")         # Default Git ref used for application repositories
        base_ref_fallbacks  = optional(list(string))           # Fallback Git refs for application repositories
        helm_chart          = optional(string, "dasmeta/base") # Default Helm chart used by application deployments
        helm_timeout        = optional(string, "40m")          # Default Helm operation timeout
        dynamic_base_domain = optional(string)                 # Base DNS domain for generated dynamic environments
        dynamic_env_release = optional(string)                 # Default release identifier for dynamic environments
      }), {})
      infra_deployments = optional(any, [])         # Infrastructure deployment definitions rendered without schema transformation
      deployments = optional(list(object({          # Application deployments rendered into applications.yaml
        project            = string                 # GitLab project path containing the application
        helm_release       = string                 # Helm release name for the application
        app_component      = string                 # Application component identifier used in generated values paths
        helm_version       = string                 # Helm chart version for the application
        db_migration       = optional(bool)         # Enable the database migration deployment path
        helm_overrides     = optional(list(string)) # Additional Helm command-line overrides
        base_ref           = optional(string)       # Application-specific Git ref override
        base_ref_fallbacks = optional(list(string)) # Application-specific fallback Git refs
        source_environment = optional(string)       # Environment from which configuration and secrets are sourced
        set_build_version  = optional(bool)         # Set the resolved build version in Helm values
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
    branch_protections = optional(list(object({                                       # Protected branch rules created for this project
      branch                       = string                                           # Protected branch name
      merge_access_level           = optional(string, "maintainer")                   # Merge access role
      push_access_level            = optional(string, "maintainer")                   # Push access role
      allow_force_push             = optional(bool, false)                            # Allow force-push on the branch
      code_owner_approval_required = optional(bool, false)                            # Require code-owner approval
      unprotect_access_level       = optional(string, "maintainer")                   # Unprotect access role
    })), [])
    approval_rule = optional(list(object({                                  # Project approval rules
      name                              = optional(string, "Approval rule") # Approval rule display name
      approvals_required                = optional(number, 1)               # Number of approvals required
      applies_to_all_protected_branches = optional(bool, false)             # Apply rule to all protected branches
      user_ids                          = optional(list(number))            # Explicit approver user ids
      group_ids                         = optional(list(number))            # Explicit approver group ids
    })), [])
    push_rules = optional(list(any), [])   # Provider-shaped push rules consumed by gitlab_project.push_rules
    env_variables = optional(list(object({ # Project-specific CI/CD variables
      key       = string                   # CI/CD variable name
      value     = string                   # CI/CD variable value
      masked    = optional(bool, false)    # Hide value in logs / UI where supported
      protected = optional(bool, false)    # Restrict variable to protected refs
    })), [])
    dynamic_environment = optional(object({                                                    # Per-project dynamic environment pipeline configuration
      enabled             = optional(bool, false)                                              # Enable generated dynamic environment CI jobs for this project
      ci_file_path        = optional(string, "ci-pipelines/dynamic-environment.gitlab-ci.yml") # Repository path for the generated CI configuration
      stage               = optional(string, "e2e-test-dynamic")                               # GitLab CI stage used for dynamic environment deployment
      cleanup_stage       = optional(string, "e2e-test-dynamic-clean")                         # GitLab CI stage used for dynamic environment cleanup
      needs               = optional(list(string), ["deploy"])                                 # Upstream GitLab CI jobs required before deployment
      source_environment  = optional(string, "dev")                                            # Environment from which configuration and secrets are sourced
      dynamic_env_release = optional(string)                                                   # Release identifier used by generated dynamic environment jobs
    }), null)
    gitlab_ci_pipelines = optional(list(object({                              # Reusable GitLab CI pipeline files managed for this project
      type                 = string                                           # Pipeline family: build, deploy_agent; build_ecr remains a compatibility alias
      target               = optional(string)                                 # Required for type build: ecr or onprem
      create_merge_request = optional(bool, true)                             # Open a merge request instead of committing directly to the target branch
      merge_request_title  = optional(string)                                 # Merge request title; defaults to the pipeline commit message
      remove_source_branch = optional(bool, true)                             # Remove source branch after merge
      commit_message       = optional(string)                                 # Commit message for the repository file change
      file_path            = optional(string)                                 # Defaults according to pipeline type
      job_name             = optional(string)                                 # Defaults according to pipeline type
      template_project     = optional(string, "das-meta/gitlab-ci-templates") # Project containing reusable templates
      template_ref         = optional(string, "DMVP-1150")                    # Template branch/tag/sha to include
      template_file        = optional(string)                                 # Defaults according to pipeline type
      variables = optional(object({                                           # Pipeline-type-specific variables
        aws_region                             = optional(string)                             # AWS region for ECR build jobs
        registry_host                          = optional(string)                             # Container registry hostname for on-premises build jobs
        image_repository                       = optional(string)                             # Image repository path without tag
        image_tags                             = optional(list(string))                     # Tags to push; each list entry becomes a separate tag
        dockerfile_path                        = optional(string)                             # Dockerfile path relative to build context
        build_context                          = optional(string)                             # Docker build context directory
        build_args                             = optional(string)                             # Additional docker buildx build --build-arg values
        buildx_create_args                     = optional(string)                             # Extra arguments passed to docker buildx create
        deploy_environment_name                = optional(string)                             # GitLab environment name created for the deployment
        deploy_environment_kubernetes_agent    = optional(string)                             # GitLab Agent path for the deployment environment
        deploy_environment_dashboard_namespace = optional(string)                             # Kubernetes namespace shown in the GitLab deploy board
        kube_namespace                         = optional(string)                             # Target Kubernetes namespace for the Helm release
        kube_namespace_create                  = optional(bool)                               # Create the Kubernetes namespace when it does not exist
        helm_release                           = optional(string)                             # Helm release name
        helm_chart                             = optional(string)                             # Helm chart name or path
        helm_chart_version                     = optional(string)                             # Helm chart version to deploy
        helm_repository_name                   = optional(string)                             # Helm repository alias added before install
        helm_repository_url                    = optional(string)                             # Helm repository URL added before install
        helm_values_args                       = optional(string)                             # Additional Helm --values arguments
        helm_set_args                          = optional(string)                             # Additional Helm --set arguments
        helm_extra_args                        = optional(string)                             # Extra arguments passed to helm upgrade/install
        deploy_image_repository                = optional(string)                             # Container image repository passed to Helm
        helm_image_repository_set_path         = optional(string)                             # Helm value path for the image repository
        deploy_image_tag                       = optional(string)                             # Container image tag passed to Helm
        helm_image_tag_set_path                = optional(string)                             # Helm value path for the image tag
        helm_wait                              = optional(bool)                               # Wait for Helm resources to become ready
        helm_timeout                           = optional(string)                             # Helm operation timeout (for example 40m)
      }), {})
      jobs = optional(list(object({   # Multiple jobs rendered into the same generated pipeline file
        name = string                 # Generated GitLab CI job name
        variables = optional(object({ # Job-specific variables
          aws_region                             = optional(string)                             # AWS region for ECR build jobs
          registry_host                          = optional(string)                             # Container registry hostname for on-premises build jobs
          image_repository                       = optional(string)                             # Image repository path without tag
          image_tags                             = optional(list(string))                     # Tags to push; each list entry becomes a separate tag
          dockerfile_path                        = optional(string)                             # Dockerfile path relative to build context
          build_context                          = optional(string)                             # Docker build context directory
          build_args                             = optional(string)                             # Additional docker buildx build --build-arg values
          buildx_create_args                     = optional(string)                             # Extra arguments passed to docker buildx create
          deploy_environment_name                = optional(string)                             # GitLab environment name created for the deployment
          deploy_environment_kubernetes_agent    = optional(string)                             # GitLab Agent path for the deployment environment
          deploy_environment_dashboard_namespace = optional(string)                             # Kubernetes namespace shown in the GitLab deploy board
          kube_namespace                         = optional(string)                             # Target Kubernetes namespace for the Helm release
          kube_namespace_create                  = optional(bool)                               # Create the Kubernetes namespace when it does not exist
          helm_release                           = optional(string)                             # Helm release name
          helm_chart                             = optional(string)                             # Helm chart name or path
          helm_chart_version                     = optional(string)                             # Helm chart version to deploy
          helm_repository_name                   = optional(string)                             # Helm repository alias added before install
          helm_repository_url                    = optional(string)                             # Helm repository URL added before install
          helm_values_args                       = optional(string)                             # Additional Helm --values arguments
          helm_set_args                          = optional(string)                             # Additional Helm --set arguments
          helm_extra_args                        = optional(string)                             # Extra arguments passed to helm upgrade/install
          deploy_image_repository                = optional(string)                             # Container image repository passed to Helm
          helm_image_repository_set_path         = optional(string)                             # Helm value path for the image repository
          deploy_image_tag                       = optional(string)                             # Container image tag passed to Helm
          helm_image_tag_set_path                = optional(string)                             # Helm value path for the image tag
          helm_wait                              = optional(bool)                               # Wait for Helm resources to become ready
          helm_timeout                           = optional(string)                             # Helm operation timeout (for example 40m)
        }), {})
        rules = optional(list(object({           # Ordered GitLab CI rules for this generated job; null when omitted
          if            = optional(string)       # GitLab CI expression evaluated for the rule
          when          = optional(string)       # Job scheduling behavior such as on_success, manual, or never
          allow_failure = optional(bool)         # Allow this rule's job execution to fail
          changes       = optional(list(string)) # Run when matching files change
          exists        = optional(list(string)) # Run when matching repository paths exist
          start_in      = optional(string)       # Delay used with when = delayed
        })))
      })), [])
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
    For type = "build", set pipeline target to "ecr" or "onprem". The module writes
    ci-pipelines/build-gitlab.ci.yaml and all jobs in that pipeline use the selected template.
    ECR jobs require aws_region and image_repository. On-premises jobs require registry_host and
    image_repository; REGISTRY_USERNAME and REGISTRY_PASSWORD must be supplied through env_variables.
    Legacy type = "build_ecr" remains supported without target.

    For type = "deploy_agent", the module writes ci-pipelines/deploy.gitlab-ci.yml with one include of
    the reusable GitLab Agent deploy template. Set jobs to generate multiple jobs in that file; each job
    extends .deploy-agent and owns its variables. When jobs is omitted or empty, legacy job_name + variables
    generates one deploy job. jobs[].rules supports if, when, allow_failure, changes, exists, and start_in.
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
        !contains(["build", "build_ecr"], pipeline.type) || alltrue([
          for build_variables in concat(
            [try(pipeline.variables, {})],
            [for job in try(pipeline.jobs, []) : try(job.variables, {})]
            ) : (
            try(build_variables.image_tags, null) == null ||
            can(tolist(build_variables.image_tags)) &&
            alltrue([for tag in tolist(build_variables.image_tags) : can(tostring(tag)) && length(trimspace(tostring(tag))) > 0])
          )
        ])
      ]
    ]))
    error_message = "Build variables must use image_tags as a non-empty list of non-empty strings when set."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        contains(["build", "build_ecr", "deploy_agent"], pipeline.type)
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[].type must be one of: build, build_ecr, deploy_agent."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        pipeline.type == "build"
        ? try(pipeline.target, null) != null && contains(["ecr", "onprem"], pipeline.target)
        : try(pipeline.target, null) == null
      ]
    ]))
    error_message = "Build pipelines must set target to ecr or onprem; other pipeline types must omit target."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        !(
          pipeline.type == "build_ecr" ||
          (pipeline.type == "build" && try(pipeline.target, null) == "ecr")
          ) || alltrue([
            for required_values in concat(
              [
                for job in try(pipeline.jobs, []) : {
                  aws_region       = try(job.variables.aws_region, null) == null ? "" : job.variables.aws_region
                  image_repository = try(job.variables.image_repository, null) == null ? "" : job.variables.image_repository
                }
              ],
              length(try(pipeline.jobs, [])) == 0 ? [{
                aws_region       = try(pipeline.variables.aws_region, null) == null ? "" : pipeline.variables.aws_region
                image_repository = try(pipeline.variables.image_repository, null) == null ? "" : pipeline.variables.image_repository
              }] : []
              ) : (
              length(trimspace(required_values.aws_region)) > 0 &&
              length(trimspace(required_values.image_repository)) > 0
            )
        ])
      ]
    ]))
    error_message = "Each ECR build job must set aws_region and image_repository in its variables."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        !(pipeline.type == "build" && try(pipeline.target, null) == "onprem") || alltrue([
          for required_values in concat(
            [
              for job in try(pipeline.jobs, []) : {
                registry_host    = try(job.variables.registry_host, null) == null ? "" : job.variables.registry_host
                image_repository = try(job.variables.image_repository, null) == null ? "" : job.variables.image_repository
              }
            ],
            length(try(pipeline.jobs, [])) == 0 ? [{
              registry_host    = try(pipeline.variables.registry_host, null) == null ? "" : pipeline.variables.registry_host
              image_repository = try(pipeline.variables.image_repository, null) == null ? "" : pipeline.variables.image_repository
            }] : []
            ) : (
            length(trimspace(required_values.registry_host)) > 0 &&
            length(trimspace(required_values.image_repository)) > 0
          )
        ])
      ]
    ]))
    error_message = "Each on-premises build job must set registry_host and image_repository in its variables."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        pipeline.type != "deploy_agent" || alltrue([
          for required_values in concat(
            [
              for job in try(pipeline.jobs, []) : {
                deploy_environment_name                = try(job.variables.deploy_environment_name, null) == null ? "" : job.variables.deploy_environment_name
                deploy_environment_kubernetes_agent    = try(job.variables.deploy_environment_kubernetes_agent, null) == null ? "" : job.variables.deploy_environment_kubernetes_agent
                deploy_environment_dashboard_namespace = try(job.variables.deploy_environment_dashboard_namespace, null) == null ? "" : job.variables.deploy_environment_dashboard_namespace
                kube_namespace                         = try(job.variables.kube_namespace, null) == null ? "" : job.variables.kube_namespace
                helm_release                           = try(job.variables.helm_release, null) == null ? "" : job.variables.helm_release
                helm_chart                             = try(job.variables.helm_chart, null) == null ? "" : job.variables.helm_chart
              }
            ],
            length(try(pipeline.jobs, [])) == 0 ? [{
              deploy_environment_name                = try(pipeline.variables.deploy_environment_name, null) == null ? "" : pipeline.variables.deploy_environment_name
              deploy_environment_kubernetes_agent    = try(pipeline.variables.deploy_environment_kubernetes_agent, null) == null ? "" : pipeline.variables.deploy_environment_kubernetes_agent
              deploy_environment_dashboard_namespace = try(pipeline.variables.deploy_environment_dashboard_namespace, null) == null ? "" : pipeline.variables.deploy_environment_dashboard_namespace
              kube_namespace                         = try(pipeline.variables.kube_namespace, null) == null ? "" : pipeline.variables.kube_namespace
              helm_release                           = try(pipeline.variables.helm_release, null) == null ? "" : pipeline.variables.helm_release
              helm_chart                             = try(pipeline.variables.helm_chart, null) == null ? "" : pipeline.variables.helm_chart
            }] : []
            ) : alltrue([
              for value in values(required_values) : length(trimspace(value)) > 0
          ])
        ])
      ]
    ]))
    error_message = "Each deploy_agent job must set deploy_environment_name, deploy_environment_kubernetes_agent, deploy_environment_dashboard_namespace, kube_namespace, helm_release, and helm_chart in its variables."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        length(try(pipeline.jobs, [])) == length(distinct([
          for job in try(pipeline.jobs, []) : job.name
        ]))
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[].jobs must use unique names within each pipeline entry."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : [
        for pipeline in try(p.gitlab_ci_pipelines, []) :
        alltrue([
          for job in try(pipeline.jobs, []) : length(trimspace(job.name)) > 0
        ])
      ]
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[].jobs[].name must be non-empty."
  }

  validation {
    condition = alltrue(flatten([
      for p in var.gitlab_projects : flatten([
        for pipeline in try(p.gitlab_ci_pipelines, []) : [
          for job in try(pipeline.jobs, []) : alltrue([
            for rule in coalesce(try(job.rules, null), []) :
            try(rule.if, null) != null ||
            try(rule.when, null) != null ||
            try(rule.allow_failure, null) != null ||
            length(coalesce(try(rule.changes, null), [])) > 0 ||
            length(coalesce(try(rule.exists, null), [])) > 0 ||
            try(rule.start_in, null) != null
          ])
        ]
      ])
    ]))
    error_message = "gitlab_projects[].gitlab_ci_pipelines[].jobs[].rules[] must set at least one supported rule field."
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
