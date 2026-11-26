output "installation" {
  description = "Nonsecret installation coordinates and effective suspension state, or null when disabled."
  value = var.install.enabled ? {
    release_name = var.install.release_name
    namespace    = var.install.namespace
    secret_name  = trimspace(var.install.existing_secret) != "" ? trimspace(var.install.existing_secret) : "${var.install.release_name}-secret"
    schedule     = var.install.schedule
    suspend      = local.effective_suspend
  } : null
}

output "global_config" {
  description = "Nonsecret worker configuration, also usable for validation."
  value       = local.global_config
}
