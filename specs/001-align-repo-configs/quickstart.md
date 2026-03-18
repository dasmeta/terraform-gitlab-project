# Quickstart: Repository Config Alignment

## Purpose

Use this guide when implementing the repository-config alignment feature on
branch `001-align-repo-configs`.

## Implementation Steps

1. Review the planned scope in `plan.md` and keep all changes inside
   repository setup, hooks, workflows, README content, and example
   documentation.
2. Update the affected repository files so workflow ownership, path references,
   and contributor setup guidance match the current repository layout.
3. Do not change Terraform module behavior, inputs, outputs, or managed GitLab
   resources as part of this feature.

## Verification Commands

Run these from the repository root after implementation:

```bash
pre-commit run --all-files
terraform fmt -check -recursive
rg -n 'modules/\$\{\{ matrix.path \}\}' .github/workflows
rg -n 'semantic-release-action@v3|Semantic-Release|Publish' .github/workflows
```

If any example `.tf` files are changed, also run in each touched example
directory:

```bash
terraform init -backend=false
terraform validate
```

## Expected Outcomes

- All workflow path references point to real repository paths.
- Release, commit-policy, and validation responsibilities are not duplicated.
- README and example guidance describe the same contributor workflow.
- Verification commands either pass or any failure is documented explicitly.
