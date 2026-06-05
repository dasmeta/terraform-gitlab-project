# Tasks: Merge Requests Template Support

**Input**: Design documents from `/specs/006-merge-requests-template/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Validation tasks are mandatory because this changes the module
consumer interface and provider resource mapping.

**Organization**: Tasks are grouped by user story so each Terraform workflow can
be implemented and verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Phase 1: Scope and Verification Setup

**Purpose**: Lock scope, affected files, and proof of correctness before making
implementation changes.

- [X] T001 Capture the affected file set in `specs/006-merge-requests-template/plan.md`
- [X] T002 Record the exact verification commands and expected results in `specs/006-merge-requests-template/quickstart.md`
- [X] T003 Confirm no breaking change or broad interface widening approval is required in `specs/006-merge-requests-template/research.md`

---

## Phase 2: Foundational Module Updates

**Purpose**: Shared Terraform changes that user stories depend on.

**Critical**: Complete this phase before story-specific implementation starts.

- [X] T004 Update the root `gitlab_projects` object schema in `variables.tf`
- [X] T005 Confirm no provider or Terraform version constraint change is needed in `versions.tf` and `providers.tf`
- [X] T006 Confirm root project normalization forwards the field without local changes in `locals.tf`

**Checkpoint**: Module foundations updated and ready for story-specific work.

---

## Phase 3: User Story 1 - Configure Merge Request Template (Priority: P1)

**Goal**: Consumers can configure a default merge request description template per GitLab project.

**Independent Test**: `terraform validate` accepts the root module schema and `terraform -chdir=examples/basic validate` accepts an example project with `merge_requests_template`.

### Verification for User Story 1

- [X] T007 [P] [US1] Add `merge_requests_template` usage to one project in `examples/basic/main.tf`
- [X] T008 [US1] Run initial formatting/validation commands from `specs/006-merge-requests-template/quickstart.md` and record any environment blockers

### Implementation for User Story 1

- [X] T009 [P] [US1] Forward `merge_requests_template` to `gitlab_project.this` in `modules/project/main.tf`
- [X] T010 [US1] Re-run root and basic example validation commands after implementation

**Checkpoint**: User Story 1 is independently implemented and verified.

---

## Phase 4: User Story 2 - Preserve Narrow Project Interface (Priority: P2)

**Goal**: The module adds only the requested optional project setting and keeps existing behavior when omitted.

**Independent Test**: Review changed Terraform files and docs to confirm the only new consumer field is optional `merge_requests_template`.

### Implementation for User Story 2

- [X] T011 [P] [US2] Update root input documentation for `merge_requests_template` in `README.md`
- [X] T012 [P] [US2] Update example documentation in `examples/basic/README.md`
- [X] T013 [US2] Review `variables.tf`, `modules/project/main.tf`, `README.md`, and `examples/basic/` for unrelated interface widening

**Checkpoint**: User Story 2 is documented and reviewed for narrow interface preservation.

---

## Final Phase: Cross-Cutting Verification and Release Readiness

**Purpose**: Ensure repository-wide sync before work is reported complete.

- [X] T014 Re-run `terraform fmt -check -recursive` from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`
- [X] T015 Re-run `terraform validate` from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`
- [X] T016 Re-run `terraform -chdir=examples/basic validate` from `/Users/vazgen/work/Dasmeta/modules/terraform-gitlab-project`
- [X] T017 Verify `README.md`, `examples/basic/main.tf`, `examples/basic/README.md`, and affected Terraform files reflect the shipped interface
- [X] T018 Add Jira implementation progress comment for completed Speckit implementation and verification result

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; starts immediately
- **Phase 2**: Depends on Phase 1 and blocks user stories
- **Phase 3**: Depends on Phase 2 completion
- **Phase 4**: Depends on Phase 2 completion and can run after or alongside Phase 3 when file edits do not conflict
- **Final Phase**: Depends on all implemented user stories

### Parallel Opportunities

- T007 and T009 touch separate files and can be prepared independently after T004.
- T011 and T012 touch separate documentation files and can run in parallel.
- Final verification tasks must run sequentially enough to capture clear failure context.

## Implementation Strategy

1. Complete scope and verification setup.
2. Add the optional root input field.
3. Update the example before final validation.
4. Forward the field to the project resource.
5. Update docs.
6. Run all verification commands and record any environment blockers.
