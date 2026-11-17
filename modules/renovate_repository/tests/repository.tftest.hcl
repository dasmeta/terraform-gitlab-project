mock_provider "gitlab" {}
mock_provider "null" {}

run "opt_in_proposes_config" {
  command = plan
  variables {
    project_ids = { platform = "42", ignored = "43" }
    gitlab_projects = [
      {
        name           = "platform"
        default_branch = "master"
        renovate = {
          enabled      = true
          ignore_paths = ["terramate/_terraform/**"]
          custom_managers = [{
            custom_type           = "jsonata"
            file_format           = "yaml"
            manager_file_patterns = ["/terramate/.*\\.ya?ml$/"]
            match_strings         = ["{\"depName\": source, \"currentValue\": version, \"datasource\": \"terraform-module\"}"]
          }]
        }
      },
      { name = "ignored" }
    ]
  }
  assert {
    condition     = length(gitlab_repository_file.this) == 1 && length(null_resource.merge_request) == 1
    error_message = "Only opted-in projects get files and an MR."
  }
  assert {
    condition     = gitlab_branch.this["platform"].name == "terraform/renovate" && gitlab_branch.this["platform"].ref == "master"
    error_message = "Create a dedicated branch from the configured default branch."
  }
  assert {
    condition     = !jsondecode(gitlab_repository_file.this["platform"].content).automerge && !jsondecode(gitlab_repository_file.this["platform"].content).platformAutomerge
    error_message = "Generated configuration must disable automerge."
  }
  assert {
    condition     = jsondecode(gitlab_repository_file.this["platform"].content).ignorePaths[0] == "terramate/_terraform/**" && jsondecode(gitlab_repository_file.this["platform"].content).customManagers[0].fileFormat == "yaml"
    error_message = "Support source YAML extraction while ignoring generated files."
  }
  assert {
    condition     = null_resource.merge_request["platform"].triggers.target_branch == "master"
    error_message = "MR must target configured default branch."
  }
}

run "disabled_has_no_resources" {
  command = plan
  variables {
    gitlab_projects = [{ name = "platform" }]
  }
  assert {
    condition     = length(gitlab_branch.this) == 0 && length(gitlab_repository_file.this) == 0 && length(null_resource.merge_request) == 0
    error_message = "Omitted opt-in must create nothing."
  }
}

run "same_branch_rejected" {
  command = plan
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", default_branch = "main", renovate = { enabled = true, source_branch = "main" } }]
  }
  expect_failures = [var.gitlab_projects]
}

run "invalid_custom_manager_rejected" {
  command = plan
  variables {
    gitlab_projects = [{ name = "platform", renovate = { custom_managers = [{ custom_type = "unknown", manager_file_patterns = ["/a/"], match_strings = ["a"] }] } }]
  }
  expect_failures = [var.gitlab_projects]
}
