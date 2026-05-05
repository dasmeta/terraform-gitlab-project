# Tasks: Improve Module Quality

**Input**: Design documents from `/specs/004-improve-module/`
**Prerequisites**: plan.md (required), spec.md (required), research.md,
data-model.md, contracts/README.md, quickstart.md

**Tests**: Validation tasks are mandatory for this feature because interface,
example, and documentation behavior can regress consumers.

**Organization**: Tasks are grouped by user story so each Terraform workflow
can be implemented and verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Phase 1: Scope and Verification Setup

**Purpose**: Lock scope, affected files, and proof of correctness before making
implementation changes.

- [X] T001 Capture the affected implementation, example, and verification file set in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/plan.md`
- [X] T002 Record the baseline verification commands, offline Terraform init expectation, and expected evidence in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/quickstart.md`
- [X] T003 Confirm in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/research.md` that no breaking-change or interface-widening approval is required before implementation

---

## Phase 2: Foundational Module Updates

**Purpose**: Shared Terraform changes that all user stories depend on

**Critical**: Complete this phase before story-specific implementation starts.

- [X] T004 Update root variable definitions and validation ownership for default project settings in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/variables.tf`
- [X] T005 Update root normalization so `locals.tf` no longer owns default project-setting declarations in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/locals.tf`
- [X] T006 Update root module wiring and child-module expectations in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/main.tf`
- [X] T007 Update consumer-visible output wording for the clarified contract in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/outputs.tf`

**Checkpoint**: Shared default ownership, validation, and resolution rules are ready for story-specific work

---

## Phase 3: User Story 1 - Clarify Consumer Configuration (Priority: P1)

**Goal**: Make the supported project, group, variable, and default-setting
paths explicit and validated so consumers can define repositories without trial
and error.

**Independent Test**: Run `terraform validate` at the repository root and
validate targeted fixtures so the valid flow passes while unsupported
namespace-selection and group-reference combinations fail with clear messages.

### Verification for User Story 1

- [X] T008 [P] [US1] Add a valid root-module verification fixture in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/validation-valid/main.tf`
- [X] T009 [P] [US1] Add an invalid namespace-selection fixture in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/validation-invalid-namespace/main.tf`
- [X] T010 [P] [US1] Add an invalid existing-group fixture in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/validation-invalid-group/main.tf`
- [X] T011 [US1] Run root and fixture validation from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project` and `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/validation-*`

### Implementation for User Story 1

- [X] T012 [P] [US1] Tighten root input validation and supported-path descriptions in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/variables.tf`
- [X] T013 [P] [US1] Enforce deterministic namespace resolution without local-owned defaults in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/locals.tf`
- [X] T014 [P] [US1] Align managed-group versus existing-group validation in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/modules/gitlab_group/variables.tf`
- [X] T015 [P] [US1] Align child project expectations with the normalized root contract in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/modules/project/variables.tf`
- [X] T016 [US1] Re-run repository and fixture validation after the US1 code changes from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`

**Checkpoint**: User Story 1 is independently validated and the supported configuration paths are explicit

---

## Phase 4: User Story 2 - Keep Docs and Examples Trustworthy (Priority: P2)

**Goal**: Keep README and example usage aligned with the real module behavior
so maintainers and consumers can trust the documentation.

**Independent Test**: Compare the updated README and example fixtures against
the implemented namespace, group-mode, variable-precedence, and default-setting
behavior, then run `terraform -chdir=examples/basic validate` successfully.

### Verification for User Story 2

- [X] T017 [P] [US2] Update the example verification scenario and expected checks in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/quickstart.md`
- [X] T018 [US2] Run `terraform -chdir=/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/basic validate` after the documentation and example updates

### Implementation for User Story 2

- [X] T019 [P] [US2] Update the primary consumer guidance, supported-path rules, and default-setting ownership notes in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/README.md`
- [X] T020 [P] [US2] Update the main happy-path example to reflect the clarified contract in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/basic/main.tf`
- [X] T021 [P] [US2] Update the example explanation and usage notes in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/basic/README.md`
- [X] T022 [US2] Review `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/README.md` and `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/basic/` against the implemented interface and resolve any contradictions

**Checkpoint**: User Story 2 is independently documented and the example usage matches the shipped behavior

---

## Phase 5: User Story 3 - Improve Safely for Existing Consumers (Priority: P3)

**Goal**: Preserve compatibility for documented baseline workflows while making
validation, precedence behavior, and default-setting ownership safer and easier
to reason about.

**Independent Test**: Review the final change set and rerun the planned
validation commands to confirm the single-group fallback, shared-variable
override path, and baseline workflow compatibility remain intact while defaults
are no longer hidden in `locals.tf`.

### Verification for User Story 3

- [X] T023 [P] [US3] Update the compatibility-oriented implementation note for baseline consumers in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/research.md`
- [X] T024 [US3] Re-run the full planned validation set from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project` to confirm compatibility-sensitive flows still behave as intended

### Implementation for User Story 3

- [X] T025 [P] [US3] Preserve and document the single-group fallback and baseline namespace behavior in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/locals.tf`
- [X] T026 [P] [US3] Clarify full-replacement CI variable precedence in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/modules/ci_env_variables/main.tf`
- [X] T027 [P] [US3] Align child-module variable descriptions with the preserved baseline contract in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/modules/ci_env_variables/variables.tf`
- [X] T028 [US3] Update compatibility and non-goal notes for existing consumers in `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/README.md`

**Checkpoint**: User Story 3 is independently verified and baseline consumers remain within the approved wrapper scope

---

## Final Phase: Cross-Cutting Verification and Release Readiness

**Purpose**: Ensure repository-wide sync before work is reported complete

- [X] T029 Re-run `pre-commit run --all-files` from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`
- [X] T030 Re-run `terraform validate` and `terraform -chdir=examples/basic validate` from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`
- [X] T031 Verify `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/README.md`, `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/examples/`, and the validation fixtures reflect the shipped interface and default-setting ownership
- [X] T032 Verify no unapproved breaking change or interface widening was introduced by reviewing `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/spec.md` and `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project/specs/004-improve-module/plan.md`

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; starts immediately
- **Phase 2**: Depends on Phase 1 and blocks all user stories
- **Phase 3**: Depends on Phase 2; this is the MVP slice
- **Phase 4**: Depends on Phase 3 because docs and examples must describe the clarified interface
- **Phase 5**: Depends on Phase 3 and Phase 4 because compatibility review relies on the implemented and documented behavior
- **Final Phase**: Depends on all user stories

### User Story Dependencies

- **US1**: Starts after foundational default ownership, validation, and resolution updates are ready
- **US2**: Starts after US1 establishes the intended contract to document
- **US3**: Starts after US1 and overlaps the final documentation alignment from US2

### Parallel Opportunities

- **US1**: T008, T009, and T010 can run in parallel because they create separate fixture directories; T012, T014, and T015 can run in parallel because they touch different files
- **US2**: T019, T020, and T021 can run in parallel after US1 because they touch separate documentation/example files
- **US3**: T025, T026, and T027 can run in parallel because they touch separate Terraform files

---

## Implementation Strategy

### MVP First

Deliver **Phase 3 / US1** first. That slice gives the highest-value outcome by
making the consumer contract explicit and validated, including the new
requirement that default project settings move out of `locals.tf`.

### Incremental Delivery

1. Complete Phase 1 and Phase 2 to lock the shared default ownership, validation, and resolution foundation.
2. Deliver US1 and prove the supported configuration paths with validation fixtures.
3. Deliver US2 so README and examples match the clarified behavior.
4. Deliver US3 to confirm compatibility-sensitive behavior and precedence rules remain safe for existing consumers.
5. Finish with the cross-cutting verification phase before reporting completion.

### Task Count Summary

- **Total tasks**: 32
- **US1 tasks**: 9
- **US2 tasks**: 6
- **US3 tasks**: 6
- **Setup / Foundational / Final tasks**: 11
