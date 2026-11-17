resource "helm_release" "this" {
  for_each = var.install.enabled ? { renovate = true } : {}

  name             = var.install.release_name
  namespace        = var.install.namespace
  create_namespace = var.install.create_namespace
  repository       = "oci://ghcr.io/renovatebot/charts"
  chart            = "renovate"
  version          = var.install.chart_version
  timeout          = 300
  wait             = true
  atomic           = true
  values           = [yamlencode(local.helm_values)]

  lifecycle {
    precondition {
      condition     = local.cron_valid
      error_message = "install.schedule must be numeric five-field cron with valid ranges, lists and positive steps."
    }
    precondition {
      condition     = length(var.repositories) > 0
      error_message = "Enabled installation requires at least one explicit repository path."
    }
  }
}
