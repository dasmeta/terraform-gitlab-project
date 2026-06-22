# Selectable Container Build Target Implementation Plan

**Branch**: `006-merge-requests-template` | **Date**: 2026-06-22 | **Spec**: `specs/010-registry-build/spec.md`

## Summary

Add a registry-neutral Docker build template and map the public `build` pipeline family plus `target` selector to target-specific internal pipeline definitions. Preserve the legacy ECR type.

## Technical Context

**Terraform Runtime**: repository-managed Terraform
**Primary Provider Constraints**: unchanged
**Module Scope**: `modules/gitlab_ci_pipelines`, root variable schema, examples, tests, and shared CI template
**Testing Strategy**: Terraform native tests, formatting, validation, and static YAML assertions
**Target Platform**: GitLab CI with Docker Buildx
**Constraints**: no branch change, no commits, preserve dirty worktree, credentials only in GitLab CI/CD variables

## Constitution Check

- Scope remains within reusable GitLab pipeline generation.
- The interface remains narrow: one build family and two supported targets.
- Existing `build_ecr` consumers remain compatible.
- README, example, tests, root schema, module locals, and shared template change together.
- No provider or version constraint change is required.
- Verification: `terraform test`, `terraform fmt -check`, `terraform validate`, and static template checks.

## Project Structure

```text
gitlab-ci-templates/
└── ci-templates/templates/build/onprem-build.gitlab-ci.yml

terraform-gitlab-project/
├── modules/gitlab_ci_pipelines/main.tf
├── modules/gitlab_ci_pipelines/README.md
├── modules/gitlab_ci_pipelines/tests/multi_job.tftest.hcl
├── examples/basic/main.tf
├── variables.tf
└── specs/010-registry-build/
```

## Design Decisions

- Public selector: `type = "build"` and required pipeline-level `target = "ecr" | "onprem"`.
- Every job in one generated build pipeline uses the same selected `.build` template.
- Compatibility selector: `type = "build_ecr"` remains supported without `target`.
- On-premises credentials: `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` come from project `env_variables`.
- On-premises non-secret variables: `registry_host`, `image_repository`, and standard buildx options.
- Image tags: `variables.image_tags` accepts list(string), rendered as newline-delimited `IMAGE_TAGS`.
- Modern capability classification: supported; standard Docker login/buildx behavior requires no provider feature or provider version change.
