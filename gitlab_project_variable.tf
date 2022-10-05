
locals {
  create_variable = var.create_variable
  create_webhook  = var.create_webhook
}
resource "gitlab_project_variable" "project_variable" {
  count = local.create_variable ? 1 : 0

  project = gitlab_project.this[0].id

  key       = var.project_variable_key
  value     = var.project_variable_value
  protected = var.protected
  masked    = var.masked
}

resource "gitlab_project_hook" "project_webhook" {
  count = local.create_webhook ? 1 : 0

  project = gitlab_project.this[0].id

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
