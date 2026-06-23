# Tasks: Parameterize Dynamic Environment CI

**Input**: Design documents from `/specs/011-parameterize-dynamic-ci/`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, contract

## Phase 1: Scope and Verification Setup

- [x] T001 Record approved scope and compatibility in `specs/011-parameterize-dynamic-ci/plan.md`
- [x] T002 Add failing default and custom rendering tests in `modules/dynamic_environment/tests/central_ci.tftest.hcl`

## Phase 2: User Story 1 - Configurable CI Runtime

- [x] T003 [US1] Add optional `ci_config` fields and validation in `variables.tf`
- [x] T004 [US1] Build deploy, placeholder, and cleanup jobs in `modules/dynamic_environment/locals.tf`
- [x] T005 [US1] Verify custom runtime values with `terraform -chdir=modules/dynamic_environment test`

## Phase 3: User Story 2 - Optional E2E Trigger

- [x] T006 [US2] Add optional `e2e_config` fields and enabled-project validation in `variables.tf`
- [x] T007 [US2] Conditionally merge the E2E job in `modules/dynamic_environment/locals.tf`
- [x] T008 [US2] Verify default omission and customized E2E rendering with `terraform -chdir=modules/dynamic_environment test`

## Phase 4: User Story 3 - Terraform-Owned Pipeline

- [x] T009 [US3] Encode the complete CI map with `yamlencode` in `modules/dynamic_environment/locals.tf`
- [x] T010 [US3] Remove `modules/dynamic_environment/templates/central.gitlab-ci.yml.tftpl`

## Final Phase: Documentation and Verification

- [x] T011 Update `examples/basic/main.tf` with `ci_config` and `e2e_config`
- [x] T012 Regenerate root and child module README input documentation
- [x] T013 Run recursive formatting, targeted tests, root validation, and basic example validation
