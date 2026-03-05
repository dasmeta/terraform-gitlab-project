
locals {
  create_variable = var.create_variable
  create_webhook  = var.create_webhook
}
resource "gitlab_project_variable" "project_variable" {
  count = local.create_variable ? 1 : 0

  project = values(gitlab_project.this)[0].id

  key       = var.project_variable_key
  value     = var.project_variable_value
  protected = var.protected
  masked    = var.masked
}

resource "gitlab_project_hook" "project_webhook" {
  count = local.create_webhook ? 1 : 0

  project = values(gitlab_project.this)[0].id

  url                        = var.url
  confidential_issues_events = var.confidential_issues_events
  confidential_note_events   = var.confidential_note_events
  deployment_events          = var.deployment_events
  enable_ssl_verification    = var.enable_ssl_verification
  issues_events              = var.issues_events
  job_events                 = var.job_events
  merge_requests_events      = var.merge_requests_events
  pipeline_events            = var.pipeline_events
  push_events                = var.push_events
  push_events_branch_filter  = var.push_events_branch_filter
  releases_events            = var.releases_events
  tag_push_events            = var.tag_push_events
  token                      = var.token
}

# Merge global env variables with per-project env_variables (per-project overrides same key)
locals {
  project_env_variables = {
    for item in flatten([
      for p in var.gitlab_projects : [
        for key, env in merge(
          { for e in var.global_env_variables : e.key => e },
          { for e in lookup(p, "env_variables", []) : e.key => e }
          ) : {
          project_name = p.name
          key          = key
          env          = env
        }
      ]
    ]) : "${item.project_name}:${item.key}" => item
  }
}

resource "gitlab_project_variable" "env" {
  for_each = local.project_env_variables

  project = gitlab_project.this[each.value.project_name].id

  key       = each.value.env.key
  value     = each.value.env.value
  protected = try(each.value.env.protected, false)
  masked    = try(each.value.env.masked, false)
}
