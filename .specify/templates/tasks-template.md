---
description: "Task list template for Terraform module feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required), research.md when
needed, data-model.md when needed, contracts/ when needed

**Tests**: Validation tasks are mandatory for any behavior, interface, provider,
example, or documentation change that can regress consumers. Documentation-only
changes still require verification against the live module interface.

**Organization**: Tasks are grouped by user story so each Terraform workflow can
be implemented and verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Path Conventions

- **Root module files**: `gitlab_project.tf`, `gitlab_branch.tf`,
  `gitlab_pipline.tf`, `gitlab_project_variable.tf`,
  `gitlab_repository_files.tf`, `variables.tf`, `output.tf`, `version.tf`
- **Documentation**: `README.md`, `examples/<name>/README.md`
- **Examples**: `examples/<name>/main.tf`
- **Tests**: `tests/` or example-based verification files defined in `plan.md`
- **Automation**: `githooks/`, `package.json`, or other repository automation
  files listed in `plan.md`

## Phase 1: Scope and Verification Setup

**Purpose**: Lock scope, affected files, and proof of correctness before making
implementation changes.

- [ ] T001 Capture the affected file set from `plan.md`
- [ ] T002 Record the exact verification commands and expected results
- [ ] T003 Flag any breaking change or interface widening approval required

---

## Phase 2: Foundational Module Updates

**Purpose**: Shared Terraform changes that user stories depend on

**Critical**: Complete this phase before story-specific implementation starts.

- [ ] T004 Update shared variable or object schema definitions in `variables.tf`
- [ ] T005 Update provider or version constraints in `version.tf` if required
- [ ] T006 Update shared locals or resource wiring in the exact `*.tf` files
- [ ] T007 Update shared outputs in `output.tf` when consumer-visible behavior
  changes

**Checkpoint**: Module foundations updated and ready for story-specific work

---

## Phase 3: User Story 1 - [Title] (Priority: P1)

**Goal**: [Brief description of the Terraform consumer outcome]

**Independent Test**: [Exact validation or example execution proving this story]

### Verification for User Story 1

> **Note**: Write or update the verification assets before finalizing the
> implementation, and run them after the code changes.

- [ ] T008 [P] [US1] Add or update the relevant test or example verification
  files in `tests/` or `examples/<name>/`
- [ ] T009 [US1] Run the US1 verification command and confirm the expected
  result

### Implementation for User Story 1

- [ ] T010 [P] [US1] Update the exact resource or data wiring file in
  `[path/to/file.tf]`
- [ ] T011 [P] [US1] Update related input definitions in `variables.tf`
- [ ] T012 [P] [US1] Update related outputs in `output.tf` if needed
- [ ] T013 [US1] Update `README.md` usage and any affected `examples/<name>/`
- [ ] T014 [US1] Re-run the US1 verification command after implementation

**Checkpoint**: User Story 1 is independently documented and verified

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of the Terraform consumer outcome]

**Independent Test**: [Exact validation or example execution proving this story]

### Verification for User Story 2

- [ ] T015 [P] [US2] Add or update the relevant verification files in `tests/`
  or `examples/<name>/`
- [ ] T016 [US2] Run the US2 verification command and confirm the expected
  result

### Implementation for User Story 2

- [ ] T017 [P] [US2] Update the exact `*.tf` file for the story behavior
- [ ] T018 [P] [US2] Update `variables.tf` or `output.tf` as needed
- [ ] T019 [US2] Update `README.md` and affected examples
- [ ] T020 [US2] Re-run the US2 verification command after implementation

**Checkpoint**: User Story 2 is independently documented and verified

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of the Terraform consumer outcome]

**Independent Test**: [Exact validation or example execution proving this story]

### Verification for User Story 3

- [ ] T021 [P] [US3] Add or update the relevant verification files in `tests/`
  or `examples/<name>/`
- [ ] T022 [US3] Run the US3 verification command and confirm the expected
  result

### Implementation for User Story 3

- [ ] T023 [P] [US3] Update the exact `*.tf` file for the story behavior
- [ ] T024 [P] [US3] Update `variables.tf` or `output.tf` as needed
- [ ] T025 [US3] Update `README.md` and affected examples
- [ ] T026 [US3] Re-run the US3 verification command after implementation

**Checkpoint**: User Story 3 is independently documented and verified

---

[Add more user story phases as needed, following the same pattern]

---

## Final Phase: Cross-Cutting Verification and Release Readiness

**Purpose**: Ensure repository-wide sync before work is reported complete

- [ ] T027 Re-run all affected validation and test commands from `plan.md`
- [ ] T028 Verify `README.md`, affected `examples/`, and affected `tests/`
  reflect the shipped interface
- [ ] T029 Verify approvals are recorded for any breaking change or interface
  widening
- [ ] T030 Update automation files if the changed workflow depends on them

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; starts immediately
- **Phase 2**: Depends on Phase 1 and blocks all user stories
- **Phase 3 and later**: Depend on Phase 2 completion
- **Final Phase**: Depends on all implemented user stories

### Within Each User Story

- Verification assets before final verification run
- Terraform changes before README and example sync is considered complete
- README and example updates before the story can be marked complete
- Verification command re-run after implementation before completion is claimed

### Parallel Opportunities

- Tasks marked **[P]** may run in parallel when they do not touch the same file
- Different user stories may proceed in parallel only after Phase 2 completes
- Documentation and example updates may run in parallel with independent test
  fixture updates when file ownership is disjoint

---

## Notes

- Every task list MUST keep the module interface narrow and validated
- README, examples, and tests are part of the contract and are not optional when
  behavior changes
- Do not mark work complete without citing fresh verification commands
- Stop for approval before implementing breaking changes or interface widening
