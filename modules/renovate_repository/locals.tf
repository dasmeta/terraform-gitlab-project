locals {
  projects = { for project in var.gitlab_projects : project.name => project if project.renovate.enabled }
  existing_configs = {
    for name in keys(local.projects) : name => jsondecode(data.external.existing[name].result.config)
  }
  # These are upstream's default exclusions. Extending ignorePaths must not
  # accidentally turn dependency/vendor directories into managed sources.
  dependency_directories = ["**/node_modules/**", "**/bower_components/**"]
  manual_merge_rule      = { matchJsonata = ["true"], automerge = false }
  manager_group_rule = {
    matchJsonata = ["$exists(manager) and $not(updateType in ['lockFileMaintenance', 'replacement'])"]
    groupName    = "{{manager}} dependencies"
    # Resolve after groupName so inherited preset slugs cannot collapse managers.
    groupSlug             = "{{groupName}}"
    groupSingleUpdates    = true
    separateMajorMinor    = true
    separateMinorPatch    = true
    separateMultipleMajor = false
    separateMultipleMinor = false
  }
  # ignorePaths also performs substring matching. Protect generated files with
  # anchored literal file rules so manually owned lookalikes remain updatable.
  regex_metacharacters = ["\\", "/", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
  managed_file_rules = {
    for name in keys(local.projects) : name => length(lookup(var.managed_file_paths, name, [])) == 0 ? [] : [{
      matchFileNames = [for path in distinct(var.managed_file_paths[name]) : "/^${join("", [for character in split("", path) : contains(local.regex_metacharacters, character) ? "\\${character}" : character])}$/"]
      enabled        = false
    }]
  }
  ignored_paths = {
    for name, project in local.projects : name => distinct(concat(
      local.dependency_directories,
      try(local.existing_configs[name].ignorePaths, []),
      var.repository_defaults.ignore_paths,
      project.renovate.ignore_paths
    ))
  }
  included_paths = {
    for name, project in local.projects : name => length(project.renovate.include_paths) > 0 ? project.renovate.include_paths : try(
      local.existing_configs[name].includePaths,
      var.repository_defaults.include_paths
    )
  }
  # JSON strings permit heterogeneous manager objects and stable deduplication
  # when the already-merged configuration is read on a subsequent plan.
  custom_manager_json = {
    for name, project in local.projects : name => distinct(concat(
      [for manager in try(local.existing_configs[name].customManagers, []) : jsonencode(manager)],
      [for manager in concat(var.repository_defaults.custom_managers, project.renovate.custom_managers) : jsonencode({
        for key, value in {
          customType          = manager.custom_type
          managerFilePatterns = manager.manager_file_patterns
          matchStrings        = manager.match_strings
          fileFormat          = manager.file_format
          datasourceTemplate  = manager.datasource_template
          depNameTemplate     = manager.dep_name_template
          packageNameTemplate = manager.package_name_template
          versioningTemplate  = manager.versioning_template
          registryUrlTemplate = manager.registry_url_template
        } : key => value if value != null
      })]
    ))
  }
  generated_configs = {
    for name, project in local.projects : name => merge(
      local.existing_configs[name],
      {
        "$schema" = "https://docs.renovatebot.com/renovate-schema.json"
        extends = reverse(distinct(reverse(concat(
          # The recommended base precedes defaults; explicit existing/project
          # presets follow shared defaults so repository policy takes priority.
          contains(project.renovate.extends, "config:recommended") ? ["config:recommended"] : [],
          var.repository_defaults.extends,
          try(local.existing_configs[name].extends, []),
          [for preset in project.renovate.extends : preset if preset != "config:recommended"]
        ))))
        automerge         = false
        platformAutomerge = false
        ignorePaths       = local.ignored_paths[name]
        packageRules = concat(
          [local.manager_group_rule],
          [for rule in try(local.existing_configs[name].packageRules, []) : rule if !contains([jsonencode(local.manual_merge_rule), jsonencode(local.manager_group_rule)], jsonencode(rule))],
          local.managed_file_rules[name],
          [local.manual_merge_rule]
        )
      },
      length(local.included_paths[name]) > 0 ? { includePaths = local.included_paths[name] } : {},
      length(local.custom_manager_json[name]) > 0 ? { customManagers = [for encoded in local.custom_manager_json[name] : jsondecode(encoded)] } : {}
    )
  }
  # A valid description entry records only fields changed by Terraform. This
  # permits removing old defaults/owned paths without erasing manual policy.
  ownership_fields = ["extends", "includePaths", "ignorePaths", "customManagers", "packageRules"]
  configs = {
    for name, generated in local.generated_configs : name => merge(generated, {
      description = concat(flatten([try(local.existing_configs[name].description, [])]), [
        "Managed by terraform-gitlab-project: ${jsonencode({
          version     = 1
          description = try(local.existing_configs[name].description, null)
          fields = {
            for field in local.ownership_fields : field => {
              before = try(local.existing_configs[name][field], null)
              after  = try(generated[field], null)
            } if jsonencode(try(local.existing_configs[name][field], null)) != jsonencode(try(generated[field], null))
          }
        })}"
      ])
    })
  }
  source_branches = {
    for name, project in local.projects : name => "${project.renovate.source_branch}-${substr(sha256(local.file_contents[name]), 0, 16)}"
  }
  documents = {
    for name, config in local.configs : name => jsondecode(data.external.existing[name].result.embedded == "true" ? jsonencode(merge(
      jsondecode(data.external.existing[name].result.document), { renovate = config }
    )) : jsonencode(config))
  }
  file_contents = { for name in keys(local.projects) : name => data.external.formatted[name].result.content }
}
