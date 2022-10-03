
locals {
  create_pipline = var.create_pipline
}
resource "gitlab_pipeline_schedule" "pipline_schedule" {
  count = local.create_pipline ? 1 : 0

  project = gitlab_project.this[0].id

  description = var.description
  ref         = var.ref
  cron        = var.cron
  active      = var.active
}

resource "gitlab_pipeline_schedule_variable" "pipline_schedule_variable" {
  count = local.create_pipline ? 1 : 0

  project              = gitlab_project.this[0].id
  pipeline_schedule_id = gitlab_pipeline_schedule.pipline_schedule[0].id
  key                  = var.pipline_schedule_key
  value                = var.pipline_schedule_value
}

resource "gitlab_pipeline_trigger" "pipline_trigger" {
  count = local.create_pipline ? 1 : 0

  project     = gitlab_project.this[0].id
  description = var.pipline_trigger_description
}
