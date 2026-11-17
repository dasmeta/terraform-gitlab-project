# Tasks: Shared Renovate

**Input**: [plan.md](plan.md), [spec.md](spec.md), research and contracts.

## Phase 1: Setup

- [x] T001 Capture approved scope and verification in specs/012-renovate/plan.md.
- [x] T002 Verify upstream chart and provider fallback in specs/012-renovate/research.md.

## Phase 2: Foundations

- [x] T003 Define disabled-by-default grouped root input in variables.tf.

## Phase 3: US1 - Standalone worker

**Independent test**: terraform test in modules/renovate; render pinned chart.

- [x] T004 [US1] Add failing contract tests in modules/renovate/tests/renovate.tftest.hcl.
- [x] T005 [US1] Implement Helm-only wrapper and validation in modules/renovate/*.tf.
- [x] T006 [US1] Add standalone usage in examples/renovate and module README.md.

## Phase 4: US2 - Reviewed repository configuration

**Independent test**: Terraform mock tests and fake HTTP MR helper tests.

- [x] T007 [US2] Add failing JSON/branch/MR tests in modules/renovate_repository/tests/.
- [x] T008 [US2] Implement typed config generation and resources in modules/renovate_repository/*.tf.
- [x] T009 [US2] Implement and test modules/renovate_repository/scripts/ensure_merge_request.py.

## Phase 5: US3 - Root composition

**Independent test**: terraform test -filter=tests/renovate.tftest.hcl.

- [x] T010 [US3] Add root opt-out/allowlist tests in tests/renovate.tftest.hcl.
- [x] T011 [US3] Wire projects, deployment and outputs in renovate.tf, variables.tf, outputs.tf.
- [x] T012 [US3] Add integrated usage and YAML examples in examples/renovate_root/.

## Phase 6: Verification and handoff

- [x] T013 Update README.md and .github/workflows/terraform-test.yaml with coverage and checks.
- [x] T014 Run fresh local Terraform, Python, Helm and config validation; record in specs/012-renovate/verification.md.
- [x] T015 Review implementation against specs/012-renovate/spec.md and correct findings.

## Dependencies and Parallel Execution

Setup precedes all stories. US1 and US2 are independent; root integration depends
on both. Documentation/example edits can follow each story independently. Final
verification follows integration. Start with standalone worker, then proposals,
then root composition; live client rollout remains separate.

- [x] T016 Correct two existing null-unsafe defaults in variables.tf exposed by root Terraform 1.9 tests.
