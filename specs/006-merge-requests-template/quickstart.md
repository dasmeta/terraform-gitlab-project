# Quickstart: Merge Requests Template Support

## Review Scope

1. Read [spec.md](spec.md), [plan.md](plan.md), and [research.md](research.md).
2. Confirm the feature stays limited to optional
   `gitlab_projects[].merge_requests_template` support.
3. Confirm the root object schema, project resource mapping, README, and basic
   example all describe the same input contract.

## Verification Commands

Run from the repository root:

```sh
terraform fmt -check -recursive
terraform init
terraform validate
terraform -chdir=examples/basic init
terraform -chdir=examples/basic validate
```

If provider installation is unavailable in the local environment, record the
exact failure and run all commands that do not require network access.

## Expected Evidence

- Terraform formatting reports no required changes.
- Root module validation accepts the updated `gitlab_projects` object type.
- The basic example validates with at least one project using
  `merge_requests_template`.
- README and example docs match the implemented interface.

## Actual Verification - 2026-06-05

- `terraform fmt -check -recursive`: passed.
- `terraform validate`: blocked by cached `gitlabhq/gitlab` provider startup
  failure before HCL schema checking.
- `terraform -chdir=examples/basic validate`: blocked by cached
  `gitlabhq/gitlab` provider startup failure before HCL schema checking.
- Static interface review with `rg merge_requests_template`: passed; the field
  is present in `variables.tf`, `modules/project/main.tf`, `README.md`, and
  `examples/basic`.
