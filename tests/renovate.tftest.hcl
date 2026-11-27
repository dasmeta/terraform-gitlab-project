override_data {
  target = module.renovate_repository.data.external.existing
  values = {
    result = { config = "{}", file_path = "renovate.json", document = "{}", embedded = "false", commit_sha = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", source_sha256 = "" }
  }
}

mock_provider "gitlab" {}
mock_provider "null" {}
mock_provider "local" {}
mock_provider "helm" {}

override_module {
  target = module.project
  outputs = {
    project_ids         = { platform = "42", ignored = "43" }
    path_with_namespace = { platform = "example/platform", ignored = "example/ignored" }
  }
}

variables {
  gitlab_projects = [{ name = "platform", namespace_id = 1, default_branch = "master", renovate = { enabled = true } }, { name = "ignored", namespace_id = 1 }]
}

run "config_only_without_installation" {
  command = plan
  assert {
    condition     = output.renovate_installation == null && output.renovate_repositories == tolist(["example/platform"])
    error_message = "Project opt-in must derive paths without requiring installation."
  }
  assert {
    condition     = length(module.renovate_repository.configurations) == 1
    error_message = "Root must forward project opt-in to the repository submodule."
  }
}

run "root_installation" {
  command = plan
  variables {
    renovate = { repositories = ["example/extra", "example/platform"], install = { enabled = true, existing_secret = "renovate-credentials" } }
  }
  assert {
    condition     = output.renovate_installation.namespace == "renovate" && output.renovate_repositories == tolist(["example/extra", "example/platform"])
    error_message = "Root installation must deduplicate explicit and managed repository paths."
  }
  assert {
    condition     = !contains(keys(var.renovate.install), "dry_run") && !contains(keys(output.renovate_installation), "dry_run") && !contains(keys(module.renovate.global_config), "dryRun")
    error_message = "Root usage must not retain the removed dry-run interface or configure a dry-run worker."
  }
  assert {
    condition     = try(module.renovate.global_config.prHourlyLimit == 0, false)
    error_message = "Root installation must inherit the unlimited hourly MR default."
  }
}

run "root_forwards_managed_credentials" {
  command = plan
  variables {
    renovate_token = "example-test-token"
    renovate       = { install = { enabled = true } }
  }
  assert {
    condition     = output.renovate_installation.namespace == "renovate" && output.renovate_installation.secret_name == "renovate-secret"
    error_message = "Root must forward the token and preserve the default namespace."
  }
}

run "projects_disabled" {
  command = plan
  variables { projects_enabled = false }
  assert {
    condition     = length(output.renovate_repositories) == 0 && length(module.renovate_repository.configurations) == 0
    error_message = "Disabled project management must suppress project config and derived allowlist entries."
  }
}

run "existing_consumers_opt_out" {
  command = plan
  variables { gitlab_projects = [{ name = "platform", namespace_id = 1 }] }
  assert {
    condition     = output.renovate_installation == null && length(module.renovate_repository.configurations) == 0
    error_message = "Existing consumers must create no Renovate resources."
  }
}

run "derive_owned_paths_from_pipeline_generator" {
  command = plan
  variables {
    gitlab_projects = [{
      name                = "platform"
      namespace_id        = 1
      renovate            = { enabled = true }
      gitlab_ci_pipelines = [{ type = "build", target = "ecr", file_path = "automation/custom-build.yml", variables = { aws_region = "eu-central-1", image_repository = "example/service", image_tags = ["$CI_COMMIT_SHORT_SHA"] } }]
    }]
    renovate = { defaults = { extends = ["local>example/shared-config"], ignore_paths = ["output/**"] } }
  }
  assert {
    condition     = anytrue([for rule in module.renovate_repository.configurations["platform"].packageRules : try(contains(rule.matchFileNames, "/^automation\\/custom-build\\.yml$/"), false)]) && !contains(module.renovate_repository.configurations["platform"].ignorePaths, "ci-pipelines/**")
    error_message = "Root must derive actual owned file paths, including custom paths, without excluding manually owned CI."
  }
  assert {
    condition     = contains(module.renovate_repository.configurations["platform"].extends, "local>example/shared-config")
    error_message = "Fleet defaults must be forwarded from root."
  }
}

run "derive_dynamic_and_agent_paths_for_their_owner" {
  command = plan
  variables {
    gitlab_projects = [
      { name = "platform", namespace_id = 1, renovate = { enabled = true }, dynamic_environment = { enabled = true, ci_file_path = "automation/dynamic.yml" } },
      { name = "ignored", namespace_id = 1, renovate = { enabled = true } }
    ]
    dynamic_environments_project = {
      enabled      = true
      name         = "dynamic-environments"
      namespace_id = 1
      applications = { defaults = {}, infra_deployments = [], deployments = [] }
      gitlab_agent = {
        enabled             = true
        config_project_name = "platform"
        config_file_path    = "automation/agent.yml"
      }
    }
  }
  assert {
    condition     = alltrue([for pattern in ["/^automation\\/dynamic\\.yml$/", "/^automation\\/agent\\.yml$/"] : anytrue([for rule in module.renovate_repository.configurations["platform"].packageRules : try(contains(rule.matchFileNames, pattern), false)])])
    error_message = "Opted-in projects must exclude the exact generated dynamic CI and Agent paths."
  }
  assert {
    condition     = alltrue([for rule in module.renovate_repository.configurations["ignored"].packageRules : !contains(keys(rule), "matchFileNames")])
    error_message = "Files generated in another project must not restrict this project's native detection."
  }
}

run "worker_with_last_derived_repository_is_running" {
  command = plan
  variables {
    gitlab_projects = [{ name = "platform", namespace_id = 1, renovate = { enabled = true } }]
    renovate        = { install = { enabled = true, existing_secret = "renovate-credentials", suspend = false } }
  }
  assert {
    condition     = output.renovate_repositories == tolist(["example/platform"]) && !output.renovate_installation.suspend
    error_message = "The installed worker must run when the last root-managed repository is opted in."
  }
}

run "last_root_opt_in_disabled_keeps_worker_safely_suspended" {
  command = plan
  variables {
    gitlab_projects = [{ name = "platform", namespace_id = 1, renovate = { enabled = false } }]
    renovate        = { install = { enabled = true, existing_secret = "renovate-credentials", suspend = false } }
  }
  assert {
    condition     = output.renovate_installation != null && output.renovate_installation.suspend && output.renovate_installation.secret_name == "renovate-credentials"
    error_message = "Disabling the last root opt-in must retain the installed worker and force suspension."
  }
  assert {
    condition     = length(output.renovate_repositories) == 0 && length(module.renovate.global_config.repositories) == 0 && !module.renovate.global_config.autodiscover && length(module.renovate_repository.configurations) == 0
    error_message = "Last opt-out must clear explicit repositories without enabling discovery or retaining repository proposals."
  }
}
