# Implementation Plan: Merge Requests Template Support

**Branch**: `006-merge-requests-template` | **Date**: 2026-06-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-merge-requests-template/spec.md`

## Summary

Add a narrow optional `merge_requests_template` string attribute to each
`gitlab_projects` entry, keep omission backward compatible, and forward the
value from the root module's normalized project object into
`modules/project` where `gitlab_project.this` is declared. Update the
consumer-facing README and basic example, then verify with Terraform
formatting and validation commands.

## Technical Context

**Terraform Runtime**: `>= 1.3` from `versions.tf`  
**Primary Provider Constraints**: `gitlabhq/gitlab ~> 19.0` from `versions.tf`
**Module Scope**: root module input contract plus `modules/project` resource mapping and examples/docs  
**Testing Strategy**: `terraform fmt -check -recursive`, `terraform validate`, and `terraform -chdir=examples/basic validate` after init is available  
**Target Platform**: GitLab API via Terraform provider  
**Project Type**: Terraform module repository  
**Constraints**: preserve opinionated wrapper interface, no unapproved breaking change, no broad provider pass-through, update docs/examples with interface change  
**Scale/Scope**: `variables.tf`, `modules/project/main.tf`, `README.md`, `examples/basic/main.tf`, `examples/basic/README.md`, and this feature's Speckit artifacts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Scope check: Pass. The change stays inside GitLab project lifecycle management and only adds one project setting.
- Wrapper check: Pass. `merge_requests_template` is a narrow optional field aligned with existing merge request and commit template settings rather than a broad upstream pass-through.
- Approval check: Pass. No breaking change and no broad interface widening are planned.
- File coverage check: Pass. Affected Terraform files, README, basic example, and Speckit evidence are listed.
- Provider/version check: Pass. Existing `gitlabhq/gitlab ~> 19.0` is expected to support the project argument and allow future 19.x minor/patch releases without crossing into 20.x.
- Verification check: Pass. Planned commands are `terraform fmt -check -recursive`, `terraform init`, `terraform validate`, `terraform -chdir=examples/basic init`, and `terraform -chdir=examples/basic validate`.

## Project Structure

### Documentation (this feature)

```text
specs/006-merge-requests-template/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── README.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
.
├── variables.tf
├── main.tf
├── modules/
│   └── project/
│       ├── main.tf
│       └── variables.tf
├── README.md
└── examples/
    └── basic/
        ├── main.tf
        └── README.md
```

**Structure Decision**: Add the new field to the root module project object
schema in `variables.tf`; no root `locals.tf` change is expected because the
project object is merged and forwarded as-is. Add the provider resource mapping
in `modules/project/main.tf`. Keep the child `modules/project/variables.tf`
`any` contract unchanged because it intentionally mirrors the root input
without duplicating the full object type. Update docs and the basic example so
consumers can see the supported field.

## Complexity Tracking

> **Fill only if the Constitution Check reveals a justified exception**

| Exception | Why Needed | Approval or Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------------------|
| None | Not applicable | Not applicable |

## Phase 0: Research

See [research.md](research.md).

## Phase 1: Design & Contracts

See [data-model.md](data-model.md), [contracts/README.md](contracts/README.md),
and [quickstart.md](quickstart.md).

## Constitution Check - Post Design

- Scope check: Pass. Design remains limited to project input schema and project resource mapping.
- Wrapper check: Pass. The new field is optional and does not expose unrelated provider options.
- Approval check: Pass. No breaking change or broad interface widening was introduced during design.
- File coverage check: Pass. Planned implementation tasks cover Terraform source, docs, examples, and Speckit evidence.
- Provider/version check: Pass. Provider constraint is pinned to the 19.x major range.
- Verification check: Pass. Quickstart records the commands needed before completion.
