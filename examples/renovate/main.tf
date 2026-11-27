provider "helm" {
  kubernetes = { config_path = "~/.kube/config" }
}

module "renovate" {
  source = "../../modules/renovate"

  repositories   = ["example/platform", "example/charts"]
  renovate_token = var.renovate_token
  install = {
    enabled  = true
    schedule = "0 */6 * * *"
  }
}

output "installation" {
  description = "Shared worker installation coordinates."
  value       = module.renovate.installation
}
