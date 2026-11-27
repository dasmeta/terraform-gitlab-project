output "configurations" {
  description = "Generated nonsecret Renovate repository configurations indexed by project name."
  value       = local.configs
}

output "source_branches" {
  description = "Snapshot-revision proposal branches derived from desired content, original source hash, file path and target branch, created from the captured target commit."
  value       = local.source_branches
}
