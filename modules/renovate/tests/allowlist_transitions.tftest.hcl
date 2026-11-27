mock_provider "helm" {}

variables {
  install = {
    enabled         = true
    existing_secret = "renovate-credentials"
    namespace       = "automation"
    release_name    = "dependency-bot"
    schedule        = "15 */4 * * *"
    suspend         = false
  }
}

run "empty_worker_is_installed_suspended" {
  command = apply
  assert {
    condition     = length(helm_release.this) == 1 && yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend && output.installation.suspend
    error_message = "Apply must keep the empty worker installed and suspended."
  }
  assert {
    condition     = length(output.global_config.repositories) == 0 && !output.global_config.autodiscover
    error_message = "The empty worker must never enable repository discovery."
  }
}

run "first_repository_resumes_worker" {
  command = apply
  variables {
    repositories = ["example/platform"]
  }
  assert {
    condition     = !yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend && !output.installation.suspend
    error_message = "Adding the first repository must honor the requested suspend=false."
  }
  assert {
    condition     = jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).repositories == ["example/platform"] && !output.global_config.autodiscover
    error_message = "The resumed worker must use only the newly allowed repository."
  }
}

run "last_repository_removed_updates_and_suspends_worker" {
  command = apply
  variables {
    repositories = []
  }
  assert {
    condition     = length(helm_release.this) == 1 && yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend && output.installation.suspend
    error_message = "Removing the last repository must update the installed worker and force suspension."
  }
  assert {
    condition     = length(jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).repositories) == 0 && !jsondecode(yamldecode(helm_release.this["renovate"].values[0]).renovate.config).autodiscover
    error_message = "The worker must clear its previous repository list while discovery remains disabled."
  }
  assert {
    condition     = output.installation.release_name == run.first_repository_resumes_worker.installation.release_name && output.installation.namespace == "automation" && output.installation.secret_name == "renovate-credentials" && output.installation.schedule == "15 */4 * * *"
    error_message = "Allowlist transitions must preserve the installation, namespace, credentials and schedule."
  }
  assert {
    condition     = !output.global_config.force.automerge && !output.global_config.force.platformAutomerge
    error_message = "Allowlist transitions must preserve manual merging."
  }
}

run "nonempty_worker_honors_requested_suspension" {
  command = apply
  variables {
    repositories = ["example/platform"]
    install = {
      enabled         = true
      existing_secret = "renovate-credentials"
      namespace       = "automation"
      release_name    = "dependency-bot"
      schedule        = "15 */4 * * *"
      suspend         = true
    }
  }
  assert {
    condition     = yamldecode(helm_release.this["renovate"].values[0]).cronjob.suspend && output.installation.suspend
    error_message = "A nonempty allowlist must honor an explicit suspend=true."
  }
}
