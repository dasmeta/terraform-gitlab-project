output "configurations" {
  description = "Generated nonsecret Renovate repository configurations indexed by project name."
  value       = local.configs
}

output "source_branches" {
  description = "Content-revision branches holding configuration proposals, created from the captured target commit for each policy revision."
  value       = local.source_branches
}
