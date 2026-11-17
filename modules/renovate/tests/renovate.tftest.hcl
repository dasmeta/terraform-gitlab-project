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
      dry_run         = true
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
    condition     = jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).dryRun == "full"
    error_message = "Use a full read-only dry run."
  }
  assert {
    condition     = jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).requireConfig == "required" && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).onboarding
    error_message = "Wait for the merged config without a duplicate onboarding MR."
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).cronjob.concurrencyPolicy == "Forbid" && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).force.automerge
    error_message = "Prevent overlapping runs and automatic merging."
  }
}

run "missing_secret_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true }
  }
  expect_failures = [var.install]
}

run "empty_allowlist_rejected" {
  command = plan
  variables {
    install = { enabled = true, existing_secret = "renovate-credentials" }
  }
  expect_failures = [helm_release.this]
}

run "invalid_cron_ranges_rejected" {
  command = plan
  variables {
    repositories = ["example/platform"]
    install      = { enabled = true, existing_secret = "renovate-credentials", schedule = "99 99 99 99 99" }
  }
  expect_failures = [helm_release.this]
}

run "write_mode_and_custom_schedule" {
  command = plan
  variables {
    repositories = ["example/services"]
    install      = { enabled = true, existing_secret = "renovate-credentials", dry_run = false, suspend = true, schedule = "5,15-30/5 0-23/2 * * 1-5" }
  }
  assert {
    condition     = !contains(keys(jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config)), "dryRun") && yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend
    error_message = "Write mode must omit dryRun and preserve suspend/custom cron settings."
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
