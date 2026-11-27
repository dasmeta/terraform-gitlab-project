mock_provider "helm" {}

run "token_creates_chart_secret_in_default_namespace" {
  command = plan
  variables {
    repositories   = ["example/platform"]
    renovate_token = "example-test-token"
    install        = { enabled = true }
  }
  assert {
    condition     = one(helm_release.this["renovate"].set_sensitive).value == var.renovate_token && one(helm_release.this["renovate"].set_sensitive).name == "secrets.RENOVATE_TOKEN" && one(helm_release.this["renovate"].set_sensitive).type == "string"
    error_message = "Pass the token through set_sensitive so the provider also redacts Helm metadata."
  }
  assert {
    condition     = !strcontains(helm_release.this["renovate"].values[0], "example-test-token") && yamldecode(helm_release.this["renovate"].values[0]).existingSecret == ""
    error_message = "Ordinary Helm values must not contain the token."
  }
  assert {
    condition     = helm_release.this["renovate"].namespace == "renovate" && helm_release.this["renovate"].create_namespace && output.installation.secret_name == "renovate-secret"
    error_message = "Default installation must create the renovate namespace and reference renovate-secret."
  }
  assert {
    condition     = !strcontains(jsonencode(output.global_config), "example-test-token") && !strcontains(jsonencode(output.installation), "example-test-token")
    error_message = "Nonsecret outputs and bot config must not contain credentials."
  }
}

run "custom_release_and_namespace" {
  command = plan
  variables {
    repositories   = ["example/platform"]
    renovate_token = "example-test-token"
    install        = { enabled = true, release_name = "dependency-bot", namespace = "automation" }
  }
  assert {
    condition     = helm_release.this["renovate"].namespace == "automation" && output.installation.secret_name == "dependency-bot-secret"
    error_message = "Managed credentials must follow the requested release and namespace."
  }
}

run "token_does_not_enable_installation" {
  command = plan
  variables { renovate_token = "example-test-token" }
  assert {
    condition     = length(helm_release.this) == 0 && output.installation == null
    error_message = "Supplying a token must not enable an installation or create a Secret."
  }
}

run "credential_sources_are_exclusive" {
  command = plan
  variables {
    repositories   = ["example/platform"]
    renovate_token = "example-test-token"
    install        = { enabled = true, existing_secret = "external-credentials" }
  }
  expect_failures = [helm_release.this]
}

run "empty_token_rejected" {
  command = plan
  variables { renovate_token = "   " }
  expect_failures = [var.renovate_token]
}
