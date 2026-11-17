locals {
  projects = { for project in var.gitlab_projects : project.name => project if project.renovate.enabled }
  configs = {
    for name, project in local.projects : name => merge({
      "$schema"         = "https://docs.renovatebot.com/renovate-schema.json"
      extends           = project.renovate.extends
      automerge         = false
      platformAutomerge = false
      "helm-values"     = { managerFilePatterns = ["/(^|/)values([.-][^/]*)?\\.ya?ml$/"] }
      kubernetes        = { managerFilePatterns = ["/\\.ya?ml$/"] }
      }, length(project.renovate.include_paths) > 0 ? { includePaths = project.renovate.include_paths } : {},
      length(project.renovate.ignore_paths) > 0 ? { ignorePaths = project.renovate.ignore_paths } : {},
      length(project.renovate.custom_managers) > 0 ? {
        customManagers = [for manager in project.renovate.custom_managers : {
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
        }]
      } : {}
    )
  }
}
