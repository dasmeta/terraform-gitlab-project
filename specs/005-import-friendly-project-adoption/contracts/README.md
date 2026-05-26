# Contracts: Import-Friendly Project Adoption

No separate API or file-format contract is introduced by this feature.

The consumer-facing contract is the typed Terraform module interface in
`variables.tf`, with implementation forwarding through `modules/project/main.tf`
and derived branch-protection behavior in `modules/project/locals.tf`.

PR reviewers should verify that the added fields remain explicit optional
attributes and that no generic provider pass-through or unrelated GitLab
management area is introduced.
