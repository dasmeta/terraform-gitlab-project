locals {
  # Numeric five-field cron: lists, ranges, wildcards and positive steps.
  cron_fields = [for field in regexall("[^\\s]+", var.install.schedule) : [
    for part in split(",", field) : {
      bounds     = split("-", split("/", part)[0])
      step       = length(split("/", part)) == 1 ? 1 : try(tonumber(split("/", part)[1]), 0)
      parts      = length(split("/", part))
      step_valid = length(split("/", part)) == 1 || can(regex("^[0-9]+$", try(split("/", part)[1], "")))
    }
  ]]
  cron_valid = length(local.cron_fields) == 5 && alltrue([
    for index, field in local.cron_fields : alltrue([
      for part in field : part.parts <= 2 && part.step_valid && part.step > 0 && floor(part.step) == part.step && (
        part.bounds == tolist(["*"]) || try(
          length(part.bounds) <= 2 &&
          tonumber(part.bounds[0]) >= [0, 0, 1, 1, 0][index] &&
          tonumber(reverse(part.bounds)[0]) <= [59, 23, 31, 12, 6][index] &&
          tonumber(part.bounds[0]) <= tonumber(reverse(part.bounds)[0]) &&
          alltrue([for bound in part.bounds : can(regex("^[0-9]+$", bound))]),
          false
        )
      )
    ])
  ])

  global_config = {
    platform      = "gitlab"
    endpoint      = var.endpoint
    autodiscover  = false
    repositories  = sort(distinct(var.repositories))
    onboarding    = false
    requireConfig = "required"
    prHourlyLimit = 0
    force = {
      automerge         = false
      platformAutomerge = false
    }
  }

  helm_values = {
    fullnameOverride = var.install.release_name
    existingSecret   = trimspace(var.install.existing_secret)
    cronjob = {
      schedule                   = var.install.schedule
      timeZone                   = var.install.time_zone
      concurrencyPolicy          = "Forbid"
      suspend                    = var.install.suspend
      successfulJobsHistoryLimit = 1
      failedJobsHistoryLimit     = 3
    }
    renovate  = { config = jsonencode(local.global_config) }
    resources = var.install.resources
  }
}
