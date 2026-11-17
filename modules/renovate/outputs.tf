output "installation" {
  description = "Nonsecret installation coordinates, or null when disabled."
  value = var.install.enabled ? {
    release_name = var.install.release_name
    namespace    = var.install.namespace
    schedule     = var.install.schedule
    dry_run      = var.install.dry_run
  } : null
}

output "global_config" {
  description = "Nonsecret worker configuration, also usable for validation."
  value       = local.global_config
}
