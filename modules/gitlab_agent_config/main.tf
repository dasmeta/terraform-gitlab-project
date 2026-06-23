resource "gitlab_branch" "this" {
  for_each = var.enabled ? {
    agent = var.gitlab_agent
  } : {}

  project = local.config_project_id
  name    = local.source_branch
  ref     = local.target_branch

  lifecycle {
    precondition {
      condition     = local.config_project_id != null
      error_message = "gitlab_agent.config_project_name must match a managed gitlab_projects[].name, or gitlab_agent.config_project_id must be set."
    }
  }
}

resource "gitlab_repository_file" "this" {
  for_each = var.enabled ? {
    agent = var.gitlab_agent
  } : {}

  project             = local.config_project_id
  branch              = gitlab_branch.this[each.key].name
  file_path           = local.config_file_path
  content             = local.config_yaml
  encoding            = "text"
  commit_message      = "chore: add GitLab Agent configuration"
  overwrite_on_create = true

  depends_on = [gitlab_branch.this]
}

resource "null_resource" "merge_request" {
  for_each = var.enabled ? {
    agent = var.gitlab_agent
  } : {}

  triggers = {
    api_url       = local.gitlab_api_url
    project       = local.config_project_id
    source_branch = local.source_branch
    target_branch = local.target_branch
    title         = local.mr_title
    description   = "Adds generated GitLab Agent configuration for dynamic environments. The branch and file are managed by Terraform."
    file_checksum = sha1(local.config_yaml)
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

  depends_on = [gitlab_repository_file.this]
}

resource "gitlab_cluster_agent" "this" {
  for_each = local.register_agent ? {
    agent = var.gitlab_agent
  } : {}

  project = local.config_project_id
  name    = local.agent_name

  lifecycle {
    precondition {
      condition     = local.config_project_id != null
      error_message = "gitlab_agent.config_project_name must match a managed gitlab_projects[].name, or gitlab_agent.config_project_id must be set."
    }
  }

  depends_on = [gitlab_repository_file.this]
}

resource "gitlab_cluster_agent_token" "this" {
  for_each = local.register_agent ? {
    agent = var.gitlab_agent
  } : {}

  project     = local.config_project_id
  agent_id    = gitlab_cluster_agent.this[each.key].agent_id
  name        = local.token_name
  description = local.token_description
}

resource "helm_release" "gitlab_agent" {
  for_each = local.install_enabled ? {
    agent = var.gitlab_agent
  } : {}

  name             = local.helm_release_name
  namespace        = local.helm_namespace
  create_namespace = local.helm_create_namespace
  repository       = local.helm_repository
  chart            = local.helm_chart
  version          = local.helm_chart_version
  timeout          = local.helm_timeout
  wait             = local.helm_wait
  atomic           = local.helm_atomic
  values           = local.helm_values
  set = concat(
    [
      {
        name  = "config.kasAddress"
        value = local.helm_kas_address
      }
    ],
    local.helm_set_values
  )
  set_sensitive = [
    {
      name  = "config.token"
      value = gitlab_cluster_agent_token.this[each.key].token
    }
  ]
}
