mock_provider "helm" {}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = length(helm_release.this) == 0
    error_message = "Default installation must create no release."
  }
}

run "shared_worker_contract" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install = {
      enabled         = true
      existing_secret = "renovate-credentials"
    }
  }
  assert {
    condition     = helm_release.this["renovate"].version == "46.440.2"
    error_message = "Use the pinned upstream chart."
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).existingSecret == "renovate-credentials"
    error_message = "Reference the existing Secret instead of passing credentials."
  }
  assert {
    condition     = !contains(keys(yamldecode(helm_release.this["renovate"].values[0])), "secrets") && output.installation.secret_name == "renovate-credentials"
    error_message = "Existing Secret mode must not create or populate a chart Secret."
  }
  assert {
    condition     = !contains(keys(jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config)), "dryRun") && !contains(keys(output.global_config), "dryRun") && !contains(keys(output.installation), "dry_run") && !contains(keys(var.install), "dry_run")
    error_message = "The retired dry-run setting must be absent from inputs, worker configuration and outputs."
  }
  assert {
    condition     = jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).requireConfig == "required" && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).onboarding
    error_message = "Wait for the merged config without a duplicate onboarding MR."
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).cronjob.concurrencyPolicy == "Forbid" && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).force.automerge
    error_message = "Prevent overlapping runs and automatic merging."
  }
  assert {
    condition     = try(jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).prHourlyLimit == 0, false) && !contains(keys(output.global_config.force), "prHourlyLimit") && !contains(keys(output.global_config), "prConcurrentLimit") && !contains(keys(output.global_config), "branchConcurrentLimit")
    error_message = "Disable only the default hourly MR cap; keep repository overrides and existing concurrent limits."
  }
}

run "missing_secret_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true }
  }
  expect_failures = [helm_release.this]
}

run "empty_allowlist_suspends_installed_worker" {
  command = plan
  variables {
    install = { enabled = true, existing_secret = "renovate-credentials", suspend = false }
  }
  assert {
    condition     = length(helm_release.this) == 1 && output.installation != null
    error_message = "An enabled worker must remain installed when its allowlist becomes empty."
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend
    error_message = "An empty allowlist must force suspension even when suspend=false is requested."
  }
  assert {
    condition     = length(jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).repositories) == 0 && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).autodiscover
    error_message = "An empty worker must publish an empty explicit allowlist with discovery disabled."
  }
}

run "invalid_cron_ranges_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true, existing_secret = "renovate-credentials", schedule = "99 99 99 99 99" }
  }
  expect_failures = [helm_release.this]
}

run "custom_schedule_and_suspend" {
  command = plan
  variables {
    repositories = ["example/services"]
    install      = { enabled = true, existing_secret = "renovate-credentials", suspend = true, schedule = "5,15-30/5 0-23/2 * * 1-5" }
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend && yamldecode(helm_release.this["renovate"].values[0]).cronjob.schedule == "5,15-30/5 0-23/2 * * 1-5"
    error_message = "Preserve suspend and custom cron settings in normal operation."
  }
}

run "invalid_fractional_step_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true, existing_secret = "renovate-credentials", schedule = "*/2.0 * * * *" }
  }
  expect_failures = [helm_release.this]
}

run "invalid_weekday_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true, existing_secret = "renovate-credentials", schedule = "0 1 * * 7" }
  }
  expect_failures = [helm_release.this]
}
