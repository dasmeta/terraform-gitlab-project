provider "helm" {
  kubernetes = { config_path = "~/.kube/config" }
}

module "renovate" {
  source = "../../modules/renovate"

  repositories = ["example/platform", "example/charts"]
  install = {
    enabled         = true
    namespace       = "renovate"
    existing_secret = "renovate-credentials"
    schedule        = "0 */6 * * *"
    dry_run         = true
  }
}

output "installation" {
  description = "Shared worker installation coordinates."
  value       = module.renovate.installation
}
