mock_provider "gitlab" {}
mock_provider "null" {}
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
