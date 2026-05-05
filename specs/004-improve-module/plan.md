# Implementation Plan: Improve Module Quality

**Branch**: `004-improve-module` | **Date**: 2026-05-05 | **Spec**: [spec.md](/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/spec.md)
**Input**: Feature specification from `/specs/004-improve-module/spec.md`

## Summary

Improve the existing Terraform GitLab wrapper module without widening scope.
The change set keeps the consumer contract bounded to the current root module,
clarifies supported group and namespace resolution paths, moves default project
setting ownership out of `locals.tf` into variable definitions, and requires
variable descriptions to live next to each individual variable instead of in a
separate shared description block. Verification remains non-live and centered
on `pre-commit`, `terraform validate`, example validation, and docs-to-code
consistency review.

## Technical Context

**Terraform Runtime**: Repository-managed Terraform CLI; no `required_version` declared in `version.tf`  
**Primary Provider Constraints**: `gitlabhq/gitlab >= 18.8.2`  
**Module Scope**: Root module, child wrapper modules, README, examples, validation fixtures, planning artifacts, and agent context  
**Testing Strategy**: `pre-commit run --all-files`, root `terraform validate`, `terraform -chdir=examples/basic validate`, targeted valid and invalid example fixtures, and rendered interface/documentation review  
**Target Platform**: GitLab API via Terraform provider  
**Project Type**: Terraform module repository  
**Constraints**: Preserve opinionated wrapper interface; no unapproved interface widening; no unapproved breaking changes; keep defaults owned by variable definitions; keep variable descriptions adjacent to each variable block  
**Scale/Scope**: `variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `README.md`, `examples/basic/`, validation fixture examples, `modules/project/`, `modules/gitlab_group/`, `modules/ci_env_variables/`, `specs/004-improve-module/`, and `AGENTS.md`

## Constitution Check

*GATE: Passes before Phase 0 research. Re-checked after Phase 1 design.*

- Scope check: Pass. The feature stays inside the existing GitLab project,
  group, and CI/CD variable wrapper responsibility.
- Wrapper check: Pass. The plan narrows and clarifies the supported consumer
  surface instead of exposing more upstream provider fields.
- Approval check: Pass. The spec records `Breaking Change: No` and `Interface
  Widening: No`; no approval gate is triggered.
- File coverage check: Pass. Planned file coverage includes root Terraform
  files, child modules, README, examples, validation fixtures, planning docs,
  and agent context updates.
- Provider/version check: Pass. Provider-dependent behavior is reviewed, but
  this feature does not require changes to provider constraints or `version.tf`.
- Verification check: Pass. The plan names the required validation commands
  and documentation review steps before completion can be claimed.

## Project Structure

### Documentation (this feature)

```text
specs/004-improve-module/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (repository root)

```text
.
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── README.md
├── examples/
│   ├── basic/
│   ├── validation-valid/
│   ├── validation-invalid-namespace/
│   └── validation-invalid-group/
├── modules/
│   ├── project/
│   ├── gitlab_group/
│   └── ci_env_variables/
└── AGENTS.md
```

**Structure Decision**:
- Root interface and validation changes live in
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/variables.tf`,
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/locals.tf`,
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/main.tf`, and
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/outputs.tf`.
- Consumer-facing contract updates live in
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/README.md` and
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/`.
- Child-module expectation and precedence alignment lives under
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/modules/`.
- Planning and verification artifacts remain under
  `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/`.

## Phase 0: Research Outcomes

- Root consumer contract remains documentation-driven; no standalone machine
  contract file is added.
- Supported namespace resolution paths are limited to direct `namespace_id`,
  explicit `group_key`, or the single-group fallback.
- `gitlab_groups` behavior is treated as two explicit modes: managed create or
  existing-group reference.
- Default project settings are owned by variable definitions, not `locals.tf`.
- Variable descriptions are part of each variable block and must not be kept in
  one detached shared prose block.

## Phase 1: Design Outputs

- `research.md` captures decisions about wrapper scope, validation strategy,
  contract boundary, default ownership, and per-variable description placement.
- `data-model.md` records clarified project, group, and variable-definition
  entities plus the rule that field-level descriptions stay co-located with the
  variable they document.
- `contracts/README.md` confirms there is no separate contract artifact beyond
  the spec, research, README, and example files.
- `quickstart.md` defines the implementation path and verification sequence for
  the bounded wrapper-quality change.

## Post-Design Constitution Check

- Scope check: Still passes; design remains inside existing module ownership.
- Wrapper check: Still passes; explicit typing, validation, defaults, and
  inline descriptions strengthen the wrapper contract.
- Approval check: Still passes; no breaking change or interface widening was
  introduced during design.
- File coverage check: Still passes; per-variable description placement expands
  documentation work inside already-affected variable files.
- Provider/version check: Still passes; no provider or version contract change
  is required.
- Verification check: Still passes; current plan still relies on validation and
  docs review rather than live provider execution.

## Complexity Tracking

No constitution exceptions are required for this feature.
