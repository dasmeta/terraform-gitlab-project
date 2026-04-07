# Child module outputs are not printed by `terraform output` unless the root re-exports them.
# `module.gitlab` is an object of every output declared in the called module.
output "gitlab" {
  description = "All outputs from the terraform-gitlab-project module (gitlab_group_ids, gitlab_project_ids, …)."
  value       = module.gitlab
}
