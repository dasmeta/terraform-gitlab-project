resource "gitlab_project" "dynamic_environment" {
  for_each = local.dynamic_environments_project_enabled ? {
    central = var.dynamic_environments_project
  } : {}

  name         = each.value.name
  description  = try(each.value.description, null)
  namespace_id = try(each.value.namespace_id, null)

  visibility_level       = try(each.value.visibility_level, "private")
  default_branch         = try(each.value.default_branch, "main")
  initialize_with_readme = try(each.value.initialize_with_readme, true)
}

resource "gitlab_branch" "dynamic_environment_central" {
  for_each = local.dynamic_environments_project_enabled ? {
    central = var.dynamic_environments_project
  } : {}

  project = gitlab_project.dynamic_environment[each.key].id
  name    = local.dynamic_environments_source_branch
  ref     = try(each.value.default_branch, "main")
}

resource "gitlab_repository_file" "dynamic_environment_central" {
  for_each = local.dynamic_environments_central_files

  project             = local.dynamic_environments_project_id
  branch              = gitlab_branch.dynamic_environment_central["central"].name
  file_path           = each.key
  content             = each.value
  encoding            = "text"
  commit_message      = "chore: add dynamic environments orchestration"
  overwrite_on_create = true

  depends_on = [gitlab_branch.dynamic_environment_central]
}

resource "null_resource" "dynamic_environment_central_mr" {
  for_each = local.dynamic_environments_project_enabled ? {
    central = var.dynamic_environments_project
  } : {}

  triggers = {
    api_url        = local.dynamic_environments_api_url
    project        = local.dynamic_environments_project_id
    source_branch  = local.dynamic_environments_source_branch
    target_branch  = try(each.value.default_branch, "main")
    title          = try(each.value.mr_title, "Add dynamic environments orchestration")
    description    = "Adds generated dynamic environments orchestration files. The branch and files are managed by Terraform."
    files_checksum = sha1(join("\n", [for path, content in local.dynamic_environments_central_files : "${path}:${sha1(content)}"]))
  }

  provisioner "local-exec" {
    command = local.gitlab_merge_request_command
    environment = {
      GITLAB_API_URL        = self.triggers.api_url
      GITLAB_PROJECT        = self.triggers.project
      GITLAB_SOURCE_BRANCH  = self.triggers.source_branch
      GITLAB_TARGET_BRANCH  = self.triggers.target_branch
      GITLAB_MR_TITLE       = self.triggers.title
      GITLAB_MR_DESCRIPTION = self.triggers.description
    }
  }

  depends_on = [gitlab_repository_file.dynamic_environment_central]
}

resource "gitlab_branch" "dynamic_environment_service" {
  for_each = local.dynamic_environment_enabled_services

  project = var.project_ids[each.key]
  name    = local.dynamic_environments_source_branch
  ref     = each.value.default_branch

  lifecycle {
    precondition {
      condition     = local.dynamic_environments_project_enabled
      error_message = "dynamic_environments_project.enabled must be true when any gitlab_projects[].dynamic_environment.enabled is true."
    }
  }
}

resource "gitlab_repository_file" "dynamic_environment_service" {
  for_each = local.dynamic_environment_enabled_services

  project             = var.project_ids[each.key]
  branch              = gitlab_branch.dynamic_environment_service[each.key].name
  file_path           = try(each.value.dynamic_environment.ci_file_path, "ci-pipelines/dynamic-environment.gitlab-ci.yml")
  content             = local.dynamic_environment_service_file_content[each.key]
  encoding            = "text"
  commit_message      = "chore: add dynamic environment CI trigger"
  overwrite_on_create = true

  depends_on = [gitlab_branch.dynamic_environment_service]
}

resource "null_resource" "dynamic_environment_service_mr" {
  for_each = local.dynamic_environment_enabled_services

  triggers = {
    api_url       = local.dynamic_environments_api_url
    project       = var.project_ids[each.key]
    source_branch = local.dynamic_environments_source_branch
    target_branch = each.value.default_branch
    title         = "Add dynamic environment CI trigger"
    description   = local.dynamic_environment_service_mr_descriptions[each.key]
    file_checksum = sha1(local.dynamic_environment_service_file_content[each.key])
  }

  provisioner "local-exec" {
    command = local.gitlab_merge_request_command
    environment = {
      GITLAB_API_URL        = self.triggers.api_url
      GITLAB_PROJECT        = self.triggers.project
      GITLAB_SOURCE_BRANCH  = self.triggers.source_branch
      GITLAB_TARGET_BRANCH  = self.triggers.target_branch
      GITLAB_MR_TITLE       = self.triggers.title
      GITLAB_MR_DESCRIPTION = self.triggers.description
    }
  }

  depends_on = [gitlab_repository_file.dynamic_environment_service]
}
