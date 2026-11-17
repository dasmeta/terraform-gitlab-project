output "configurations" {
  description = "Generated nonsecret Renovate repository configurations indexed by project name."
  value       = local.configs
}

output "source_branches" {
  description = "Branches holding configuration proposals; retained after merge for Terraform ownership."
  value       = { for name, project in local.projects : name => project.renovate.source_branch }
}
