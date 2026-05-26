resource "gitlab_branch" "build_pipeline" {
  for_each = local.build_pipeline_projects

  project = var.project_ids[each.key]
  name    = local.build_pipeline_source_branch
  ref     = each.value.default_branch
}

resource "gitlab_repository_file" "build_pipeline" {
  for_each = local.build_pipeline_projects

  project             = var.project_ids[each.key]
  branch              = gitlab_branch.build_pipeline[each.key].name
  file_path           = local.build_pipeline_file_path
  content             = local.build_pipeline_content[each.key]
  encoding            = "text"
  commit_message      = "chore: add reusable build-only GitLab CI template"
  overwrite_on_create = true

  depends_on = [gitlab_branch.build_pipeline]
}

resource "null_resource" "build_pipeline_mr" {
  for_each = local.build_pipeline_projects

  triggers = {
    api_url       = trimsuffix(var.gitlab_api_url, "/")
    project       = var.project_ids[each.key]
    source_branch = local.build_pipeline_source_branch
    target_branch = each.value.default_branch
    title         = local.build_pipeline_mr_title
    description   = local.build_pipeline_mr_descriptions[each.key]
    file_checksum = sha1(local.build_pipeline_content[each.key])
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

  depends_on = [gitlab_repository_file.build_pipeline]
}

resource "gitlab_branch" "deploy_pipeline" {
  for_each = local.deploy_pipeline_projects

  project = var.project_ids[each.key]
  name    = local.deploy_pipeline_source_branch
  ref     = each.value.default_branch
}

resource "gitlab_repository_file" "deploy_pipeline" {
  for_each = local.deploy_pipeline_projects

  project             = var.project_ids[each.key]
  branch              = gitlab_branch.deploy_pipeline[each.key].name
  file_path           = local.deploy_pipeline_file_path
  content             = local.deploy_pipeline_content[each.key]
  encoding            = "text"
  commit_message      = "chore: add reusable Helm deploy GitLab CI template"
  overwrite_on_create = true

  depends_on = [gitlab_branch.deploy_pipeline]
}

resource "null_resource" "deploy_pipeline_mr" {
  for_each = local.deploy_pipeline_projects

  triggers = {
    api_url       = trimsuffix(var.gitlab_api_url, "/")
    project       = var.project_ids[each.key]
    source_branch = local.deploy_pipeline_source_branch
    target_branch = each.value.default_branch
    title         = local.deploy_pipeline_mr_title
    description   = local.deploy_pipeline_mr_descriptions[each.key]
    file_checksum = sha1(local.deploy_pipeline_content[each.key])
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

  depends_on = [gitlab_repository_file.deploy_pipeline]
}
