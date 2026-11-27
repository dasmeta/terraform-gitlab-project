override_data {
  target = data.external.existing
  values = {
    result = { config = "{}", file_path = "renovate.json", document = "{}", embedded = "false", commit_sha = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", source_sha256 = "" }
  }
}

mock_provider "gitlab" {
  mock_data "gitlab_project" {
    defaults = { web_url = "https://gitlab.com/example/platform" }
  }
}
mock_provider "null" {}
mock_provider "local" {}

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
    condition     = length(gitlab_branch.this) == 1 && length(null_resource.merge_request) == 1 && length(local_file.proposal) == 1
    error_message = "Only opted-in projects get files and an MR."
  }
  assert {
    condition     = startswith(gitlab_branch.this["platform"].name, "terraform/renovate-") && gitlab_branch.this["platform"].ref == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "Create a dedicated branch from the commit captured while reading the default branch."
  }
  assert {
    condition     = !jsondecode(local_file.proposal["platform"].content).automerge && !jsondecode(local_file.proposal["platform"].content).platformAutomerge
    error_message = "Generated configuration must disable automerge."
  }
  assert {
    condition     = contains(jsondecode(local_file.proposal["platform"].content).ignorePaths, "terramate/_terraform/**") && jsondecode(local_file.proposal["platform"].content).customManagers[0].fileFormat == "yaml"
    error_message = "Support source YAML extraction while ignoring generated files."
  }
  assert {
    condition     = null_resource.merge_request["platform"].triggers.target_branch == "master"
    error_message = "MR must target configured default branch."
  }
  assert {
    condition     = startswith(local_file.proposal["platform"].content, "{\n  ") && endswith(local_file.proposal["platform"].content, "\n}\n") && strcontains(local_file.proposal["platform"].content, "\n    {\n      ")
    error_message = "Render JSON with two-space nested indentation and a trailing newline."
  }
  assert {
    condition     = jsonencode(jsondecode(local_file.proposal["platform"].content)) == jsonencode(output.configurations["platform"]) && output.source_branches["platform"] == "terraform/renovate-${substr(sha256(jsonencode({ content_sha256 = sha256(local_file.proposal["platform"].content), source_sha256 = data.external.existing["platform"].result.source_sha256, file_path = data.external.existing["platform"].result.file_path, target_branch = "master" })), 0, 16)}"
    error_message = "Formatting must preserve JSON meaning and use the snapshot revision scheme."
  }
}

run "disabled_has_no_resources" {
  command = plan
  variables {
    gitlab_projects = [{ name = "platform" }]
  }
  assert {
    condition     = length(gitlab_branch.this) == 0 && length(null_resource.merge_request) == 0 && length(local_file.proposal) == 0 && length(data.external.formatted) == 0
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

run "generic_defaults_keep_native_detection" {
  command = plan
  variables {
    project_ids     = { arbitrary-service = "10", another-name = "11" }
    gitlab_projects = [{ name = "arbitrary-service", renovate = { enabled = true } }, { name = "another-name", renovate = { enabled = true } }]
  }
  assert {
    condition     = output.configurations["arbitrary-service"] == output.configurations["another-name"] && !contains(keys(output.configurations["arbitrary-service"]), "enabledManagers") && !contains(keys(output.configurations["arbitrary-service"]), "kubernetes")
    error_message = "Default policy must be independent of names and leave native detection unconstrained."
  }
}

run "groups_updates_by_manager" {
  command = plan
  variables {
    project_ids     = { arbitrary-service = "10" }
    gitlab_projects = [{ name = "arbitrary-service", renovate = { enabled = true } }]
  }
  assert {
    condition = length([for rule in output.configurations["arbitrary-service"].packageRules : rule if try(
      rule.groupName == "{{manager}} dependencies" && rule.groupSlug == "{{groupName}}" && rule.groupSingleUpdates &&
      length(rule.matchJsonata) == 1 &&
      rule.separateMajorMinor && rule.separateMinorPatch && !rule.separateMultipleMajor && !rule.separateMultipleMinor,
      false
    )]) == 1
    error_message = "Use one generic manager-templated rule rather than a manager/repository list or dependency count."
  }
}

run "explicit_repository_grouping_overrides_default" {
  command = plan
  override_data {
    target = data.external.existing["platform"]
    values = { result = {
      config        = "{\"packageRules\":[{\"matchManagers\":[\"npm\"],\"groupName\":\"manual JavaScript group\",\"separateMajorMinor\":false,\"separateMinorPatch\":false}]}"
      file_path     = "renovate.json"
      document      = "{}"
      embedded      = "false"
      commit_sha    = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      source_sha256 = ""
    } }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition = try(
      index([for rule in output.configurations["platform"].packageRules : try(rule.groupName, "")], "{{manager}} dependencies") <
      index([for rule in output.configurations["platform"].packageRules : try(rule.groupName, "")], "manual JavaScript group"),
      false
    )
    error_message = "Preserve explicit repository grouping after the generic default so manual policy takes priority."
  }
}

run "shared_defaults_and_exact_owned_paths" {
  command = plan
  variables {
    project_ids        = { platform = "42" }
    gitlab_projects    = [{ name = "platform", renovate = { enabled = true } }]
    managed_file_paths = { platform = ["generated/deploy.yml"] }
    repository_defaults = {
      extends         = ["local>example/presets"]
      ignore_paths    = ["generated-output/**"]
      custom_managers = [{ custom_type = "jsonata", file_format = "yaml", manager_file_patterns = ["/\\.yaml$/"], match_strings = ["{\"depName\":source,\"currentValue\":version,\"datasource\":\"terraform-module\"}"] }]
    }
  }
  assert {
    condition     = anytrue([for rule in output.configurations["platform"].packageRules : try(rule.matchFileNames[0] == "/^generated\\/deploy\\.yml$/", false)]) && contains(output.configurations["platform"].ignorePaths, "**/node_modules/**") && !contains(output.configurations["platform"].ignorePaths, "generated/deploy.yml")
    error_message = "Ignore exact Terraform-owned paths without replacing native dependency-directory exclusions."
  }
  assert {
    condition     = contains(output.configurations["platform"].extends, "local>example/presets") && length(output.configurations["platform"].customManagers) == 1
    error_message = "Shared presets/extractors must apply without per-project duplication."
  }
}

run "owned_paths_escape_regex_metacharacters" {
  command = plan
  variables {
    project_ids        = { platform = "42" }
    gitlab_projects    = [{ name = "platform", renovate = { enabled = true } }]
    managed_file_paths = { platform = ["generated/(deploy)[dev]+.yml"] }
  }
  assert {
    condition     = anytrue([for rule in output.configurations["platform"].packageRules : try(rule.matchFileNames[0] == "/^generated\\/\\(deploy\\)\\[dev\\]\\+\\.yml$/", false)])
    error_message = "Generated paths must be anchored literal matches, including regex metacharacters."
  }
}

run "fleet_of_125_projects" {
  command = plan
  variables {
    project_ids     = { for i in range(125) : "service-${i}" => tostring(i + 1) }
    gitlab_projects = [for i in range(125) : { name = "service-${i}", renovate = { enabled = true } }]
    repository_defaults = {
      custom_managers = [{ custom_type = "jsonata", file_format = "yaml", manager_file_patterns = ["/terramate/.*\\.ya?ml$/"], match_strings = ["{\"depName\":source,\"currentValue\":version,\"datasource\":\"terraform-module\"}"] }]
    }
  }
  assert {
    condition     = length(output.configurations) == 125 && alltrue([for config in values(output.configurations) : !contains(keys(config), "enabledManagers") && !config.automerge && length(config.customManagers) == 1])
    error_message = "One opt-in must work for a large fleet without naming branches in implementation."
  }
}

run "preserve_existing_policy_and_alternate_path" {
  command = plan
  override_data {
    target = data.external.existing["platform"]
    values = { result = {
      config        = <<-JSON
        {
          "schedule": ["before 5am"],
          "labels": ["existing"],
          "enabledManagers": ["npm"],
          "ignorePaths": ["manual/**"],
          "includePaths": ["src/**"],
          "packageRules": [{"matchPackageNames": ["*"], "automerge": true}],
          "customManagers": [{
            "customType": "jsonata",
            "fileFormat": "yaml",
            "managerFilePatterns": ["/example/"],
            "matchStrings": ["{\"depName\": source, \"currentValue\": version, \"datasource\": \"terraform-module\"}"]
          }]
        }
      JSON
      file_path     = ".gitlab/renovate.json"
      document      = "{}"
      embedded      = "false"
      commit_sha    = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      source_sha256 = ""
    } }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = null_resource.merge_request["platform"].triggers.file_path == ".gitlab/renovate.json" && output.configurations["platform"].schedule[0] == "before 5am" && output.configurations["platform"].labels[0] == "existing"
    error_message = "Adoption must retain the existing location, schedule and labels."
  }
  assert {
    condition     = !reverse(output.configurations["platform"].packageRules)[0].automerge && length(output.configurations["platform"].customManagers) == 1
    error_message = "Retain custom managers while overriding existing package-level automerge."
  }
  assert {
    condition     = output.configurations["platform"].enabledManagers[0] == "npm" && output.configurations["platform"].includePaths[0] == "src/**" && contains(output.configurations["platform"].ignorePaths, "manual/**")
    error_message = "Adoption must retain explicit existing manager and path restrictions."
  }
}

run "preserve_embedded_package_manifest" {
  command = plan
  override_data {
    target = data.external.existing["platform"]
    values = { result = {
      config        = "{\"labels\":[\"existing\"]}"
      document      = "{\"name\":\"example\",\"dependencies\":{\"example\":\"1.0.0\"},\"renovate\":{\"labels\":[\"existing\"]}}"
      file_path     = "package.json"
      embedded      = "true"
      commit_sha    = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      source_sha256 = ""
    } }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = jsondecode(local_file.proposal["platform"].content).dependencies.example == "1.0.0" && !jsondecode(local_file.proposal["platform"].content).renovate.automerge
    error_message = "Embedded config adoption must preserve unrelated package.json fields."
  }
  assert {
    condition     = startswith(local_file.proposal["platform"].content, "{\n  ") && endswith(local_file.proposal["platform"].content, "\n}\n") && strcontains(local_file.proposal["platform"].content, "\n  \"renovate\": {\n")
    error_message = "An embedded package.json config must also be human-readable JSON."
  }
}

run "same_policy_has_stable_revision_branch" {
  command = plan
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = output.source_branches["platform"] == run.generic_defaults_keep_native_detection.source_branches["arbitrary-service"]
    error_message = "Equal effective policies must have stable branch revisions independent of project names."
  }
}

run "new_policy_gets_fresh_target_branch" {
  command = plan
  variables {
    project_ids         = { platform = "42" }
    gitlab_projects     = [{ name = "platform", default_branch = "master", renovate = { enabled = true } }]
    repository_defaults = { ignore_paths = ["new-generated-output/**"] }
  }
  assert {
    condition     = output.source_branches["platform"] != run.same_policy_has_stable_revision_branch.source_branches["platform"] && gitlab_branch.this["platform"].ref == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && null_resource.merge_request["platform"].triggers.source_branch == output.source_branches["platform"]
    error_message = "New policy content must create a fresh branch from the captured target commit and use it for the MR."
  }
}

run "project_presets_override_shared_defaults" {
  command = plan
  variables {
    project_ids         = { platform = "42" }
    gitlab_projects     = [{ name = "platform", renovate = { enabled = true, extends = [":disableDependencyDashboard"] } }]
    repository_defaults = { extends = [":dependencyDashboard"] }
  }
  assert {
    condition     = output.configurations["platform"].extends == tolist([":dependencyDashboard", ":disableDependencyDashboard"])
    error_message = "Shared defaults must precede project presets so explicit project policy wins."
  }
}

run "existing_preset_order_survives_shared_duplicates" {
  command = plan
  override_data {
    target = data.external.existing["platform"]
    values = { result = {
      config        = "{\"extends\":[\":disableDependencyDashboard\",\":dependencyDashboard\"]}"
      file_path     = "renovate.json"
      document      = "{}"
      embedded      = "false"
      commit_sha    = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      source_sha256 = ""
    } }
  }
  variables {
    project_ids         = { platform = "42" }
    gitlab_projects     = [{ name = "platform", renovate = { enabled = true } }]
    repository_defaults = { extends = [":dependencyDashboard"] }
  }
  assert {
    condition     = output.configurations["platform"].extends == tolist(["config:recommended", ":disableDependencyDashboard", ":dependencyDashboard"])
    error_message = "Deduplication must preserve the order of the higher-priority existing preset sequence."
  }
}

run "proposal_uses_captured_snapshot_and_authoritative_project_url" {
  command = plan
  override_data {
    target = data.external.existing["platform"]
    values = { result = {
      config        = "{}"
      file_path     = "renovate.json"
      document      = "{}"
      embedded      = "false"
      commit_sha    = "cccccccccccccccccccccccccccccccccccccccc"
      source_sha256 = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
    } }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = gitlab_branch.this["platform"].ref == "cccccccccccccccccccccccccccccccccccccccc" && null_resource.merge_request["platform"].triggers.source_content_sha256 == "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
    error_message = "Proposal publication must retain the exact commit and source-file digest captured by discovery."
  }
  assert {
    condition     = null_resource.merge_request["platform"].triggers.project_url == "https://gitlab.com/example/platform" && data.external.existing["platform"].query.project_url == "https://gitlab.com/example/platform"
    error_message = "Both authenticated helpers must receive the project URL from the GitLab provider."
  }
}

run "formatting_only_replan_gets_fresh_snapshot_branch" {
  command = plan
  override_data {
    target = data.external.existing
    values = {
      result = { config = "{}", file_path = "renovate.json", document = "{}", embedded = "false", commit_sha = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", source_sha256 = "formatting-only-snapshot-digest" }
    }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = jsonencode(output.configurations["platform"]) == jsonencode(run.same_policy_has_stable_revision_branch.configurations["platform"]) && output.source_branches["platform"] != run.same_policy_has_stable_revision_branch.source_branches["platform"] && gitlab_branch.this["platform"].ref == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    error_message = "Replanning a formatting-only edit must retain desired JSON but choose a new branch at the fresh snapshot."
  }
}

run "unrelated_commit_keeps_snapshot_revision" {
  command = plan
  override_data {
    target = data.external.existing
    values = {
      result = { config = "{}", file_path = "renovate.json", document = "{}", embedded = "false", commit_sha = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", source_sha256 = "" }
    }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = output.source_branches["platform"] == run.same_policy_has_stable_revision_branch.source_branches["platform"]
    error_message = "An unrelated target commit must not change a proposal revision when source bytes/path are unchanged."
  }
}

run "moved_active_config_gets_fresh_snapshot_revision" {
  command = plan
  override_data {
    target = data.external.existing
    values = {
      result = { config = "{}", file_path = ".gitlab/renovate.json", document = "{}", embedded = "false", commit_sha = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", source_sha256 = "" }
    }
  }
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", renovate = { enabled = true } }]
  }
  assert {
    condition     = output.source_branches["platform"] != run.same_policy_has_stable_revision_branch.source_branches["platform"]
    error_message = "Moving the active config must create a branch with a fresh snapshot baseline."
  }
}

run "target_branch_switch_gets_fresh_snapshot_revision" {
  command = plan
  variables {
    project_ids     = { platform = "42" }
    gitlab_projects = [{ name = "platform", default_branch = "release", renovate = { enabled = true } }]
  }
  assert {
    condition     = output.source_branches["platform"] != run.same_policy_has_stable_revision_branch.source_branches["platform"]
    error_message = "Switching target branches must create a fresh proposal baseline even when config bytes match."
  }
}
