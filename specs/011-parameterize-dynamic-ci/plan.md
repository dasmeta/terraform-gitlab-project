# Implementation Plan: Parameterize Dynamic Environment CI

**Branch**: `006-merge-requests-template` | **Date**: 2026-06-23 | **Spec**:
[spec.md](spec.md)
**Input**: Feature specification from
`/specs/011-parameterize-dynamic-ci/spec.md`

## Summary

Replace the central GitLab CI template with a Terraform map encoded through
`yamlencode`. Extend the existing grouped project object with narrow
`ci_config` and `e2e_config` objects, validate enabled E2E configuration, and
verify rendered repository-file content with Terraform tests.

## Technical Context

**Terraform Runtime**: `>= 1.3` from `versions.tf`
**Primary Provider Constraints**: `gitlabhq/gitlab ~> 19.0`
**Module Scope**: root input contract plus `modules/dynamic_environment`
**Testing Strategy**: Terraform tests with mocked providers, recursive format
check, root validation, and basic example validation
**Target Platform**: GitLab CI and GitLab API through the Terraform provider
**Project Type**: Terraform module repository
**Constraints**: preserve an opinionated grouped interface; no arbitrary raw CI
pass-through; do not change the active git branch
**Scale/Scope**: input schema, CI locals, one obsolete template, module tests,
basic example, README generation, and feature artifacts

## Constitution Check

- Scope check: Pass. The change remains inside dynamic-environment orchestration.
- Wrapper check: Pass. Two bounded grouped objects replace embedded values; raw
  job definitions are not exposed.
- Approval check: Pass. The user approved `yamlencode` and the grouped contract.
- File coverage check: Pass. Terraform, tests, example, and docs are included.
- Provider/version check: Pass. No provider or Terraform constraint change.
- Verification check: `terraform fmt -check -recursive`, targeted
  `terraform test`, root `terraform validate`, and basic example validation.
- Speckit evidence: this package contains `spec.md`, `plan.md`, and `tasks.md`.
- Module-change gate: Expected to pass with this package.
- Modern capabilities: Not applicable; this refactors established CI generation
  and adds provider-independent configuration fields.

## Project Structure

### Documentation (this feature)

```text
specs/011-parameterize-dynamic-ci/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── dynamic-environments-project.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code

```text
variables.tf
README.md
examples/basic/main.tf
modules/dynamic_environment/
├── locals.tf
├── README.md
├── templates/
│   └── central.gitlab-ci.yml.tftpl  # removed
└── tests/
    └── central_ci.tftest.hcl
```

**Structure Decision**: Keep the public object schema at the root, because the
child module intentionally accepts the normalized object as `any`. Keep CI map
construction in the child module's `locals.tf`, next to other generated central
files. Test the observable repository-file content.

## Compatibility and Interface Assessment

- `ci_config` fields are optional and retain current values as defaults.
- `e2e_config.enabled` defaults to `false`; this removes only the unusable
  placeholder trigger.
- The database URL default references `$DYNAMIC_DATABASE_URL`; credentials are
  no longer embedded.
- No upstream provider capability or version change is involved.
