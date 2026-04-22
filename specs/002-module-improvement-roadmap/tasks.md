# Tasks: Deduplicated Module Improvement Roadmap

**Input**: Design documents from `/specs/002-module-improvement-roadmap/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/roadmap-classification.md`, `quickstart.md`

**Tests**: Validation tasks are required for this documentation and planning
feature because regressions in `TODO.md`, scope alignment, or story ordering
would mislead later implementation work.

**Organization**: Tasks are grouped by user story so each roadmap outcome can
be written and reviewed independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Path Conventions

- **Primary backlog artifact**: `TODO.md`
- **Feature docs**:
  `specs/002-module-improvement-roadmap/spec.md`,
  `specs/002-module-improvement-roadmap/plan.md`,
  `specs/002-module-improvement-roadmap/research.md`,
  `specs/002-module-improvement-roadmap/data-model.md`,
  `specs/002-module-improvement-roadmap/quickstart.md`,
  `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md`,
  `specs/002-module-improvement-roadmap/checklists/requirements.md`,
  `specs/002-module-improvement-roadmap/tasks.md`
- **Source input**: DMVP-38 Jira epic child-ticket inventory
- **Agent context**: `AGENTS.md`

## Phase 1: Scope and Verification Setup

**Purpose**: Lock the clarified scope, affected files, and proof of correctness
before writing the refreshed backlog artifacts.

- [x] T001 Capture the clarified affected file set including `TODO.md` and `specs/002-module-improvement-roadmap/` in `specs/002-module-improvement-roadmap/plan.md`
- [x] T002 Record the exact verification commands for `TODO.md` and the supporting roadmap docs in `specs/002-module-improvement-roadmap/plan.md`
- [x] T003 Record the roadmap ownership widening and likely rename approval requirement in `specs/002-module-improvement-roadmap/plan.md`

---

## Phase 2: Foundational Planning Updates

**Purpose**: Refresh the shared design artifacts so they match the clarified
GitLab-management scope and repo-root backlog output.

**Critical**: Complete this phase before user-story-specific backlog writing
starts.

- [x] T004 Update the planning summary, module scope, and structure decision for repo-root `TODO.md` in `specs/002-module-improvement-roadmap/plan.md`
- [x] T005 [P] Update research decisions for broader GitLab management scope and explicit priority tracks in `specs/002-module-improvement-roadmap/research.md`
- [x] T006 [P] Update the roadmap entities and scope-decision model for repo-root backlog ownership in `specs/002-module-improvement-roadmap/data-model.md`
- [x] T007 [P] Update the backlog classification contract so follow-up items can target `TODO.md` and the broader GitLab-management scope in `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md`
- [x] T008 Update the maintainer workflow for using repo-root `TODO.md` in `specs/002-module-improvement-roadmap/quickstart.md`

**Checkpoint**: Shared planning artifacts reflect the clarified scope and the
repo-root backlog output.

---

## Phase 3: User Story 1 - Standardize Service Repositories (Priority: P1)

**Goal**: Make repo-root `TODO.md` prioritize Terraform-managed GitLab service
repository standards for security, linting, documentation, and content
structure.

**Independent Test**: Review the DMVP-38 child-ticket inventory, `TODO.md`, and
`specs/002-module-improvement-roadmap/spec.md` and confirm service-repository
standardization is the first major track with explicit security, linting, docs,
and content-structure intent.

### Verification for User Story 1

- [x] T009 [P] [US1] Prepare the service-repository traceability notes in `TODO.md` from the DMVP-38 child-ticket inventory
- [x] T010 [US1] Review the DMVP-38 child-ticket inventory, `TODO.md`, and `specs/002-module-improvement-roadmap/spec.md` for complete US1 source coverage

### Implementation for User Story 1

- [x] T011 [P] [US1] Add the top-priority service-repository standardization section to `TODO.md`
- [x] T012 [P] [US1] Align service-repository standardization wording and theme details in `specs/002-module-improvement-roadmap/spec.md`
- [x] T013 [P] [US1] Align the service-repository usage guidance in `specs/002-module-improvement-roadmap/quickstart.md`
- [x] T014 [US1] Re-run the US1 traceability and ordering review across the DMVP-38 child-ticket inventory, `TODO.md`, and `specs/002-module-improvement-roadmap/spec.md`

**Checkpoint**: `TODO.md` leads with a clear, deduplicated service-repository
standardization track.

---

## Phase 4: User Story 2 - Prioritize Dynamic Environments and E2E DevEx (Priority: P2)

**Goal**: Make repo-root `TODO.md` prioritize review apps and dynamic
environments wired with end-to-end and integration testing.

**Independent Test**: Review `TODO.md`,
`specs/002-module-improvement-roadmap/spec.md`, and
`specs/002-module-improvement-roadmap/quickstart.md` and confirm dynamic
environments are the second major track with review-app and testing
expectations.

### Verification for User Story 2

- [x] T015 [P] [US2] Prepare the dynamic-environment and testing traceability notes in `TODO.md` from the DMVP-38 child-ticket inventory
- [x] T016 [US2] Review `TODO.md`, `specs/002-module-improvement-roadmap/spec.md`, and `specs/002-module-improvement-roadmap/quickstart.md` for explicit review-app and end-to-end testing coverage

### Implementation for User Story 2

- [x] T017 [P] [US2] Add the second-priority dynamic-environments and e2e-devex section to `TODO.md`
- [x] T018 [P] [US2] Align the dynamic-environment story and phase details in `specs/002-module-improvement-roadmap/spec.md`
- [x] T019 [P] [US2] Align the dynamic-environment readiness guidance in `specs/002-module-improvement-roadmap/quickstart.md`
- [x] T020 [US2] Re-run the US2 ordering and coverage review across `TODO.md`, `specs/002-module-improvement-roadmap/spec.md`, and `specs/002-module-improvement-roadmap/quickstart.md`

**Checkpoint**: `TODO.md` clearly places dynamic environments and e2e DevEx as
the second major improvement track.

---

## Phase 5: User Story 3 - Expand Kubernetes and GitLab DevEx Features (Priority: P3)

**Goal**: Make repo-root `TODO.md` explicitly call out Kubernetes integration,
runners, monitoring, and broader GitLab DevEx capabilities as the third major
track while keeping only client-specific and one-off operational work out of
scope.

**Independent Test**: Review `TODO.md`,
`specs/002-module-improvement-roadmap/spec.md`, and
`specs/002-module-improvement-roadmap/contracts/roadmap-classification.md` and
confirm Kubernetes, runners, monitoring, GitLab Workspaces, Duo-style
capabilities, and out-of-scope client-specific work are clearly separated.

### Verification for User Story 3

- [x] T021 [P] [US3] Prepare the Kubernetes and GitLab DevEx traceability notes in `TODO.md` from the DMVP-38 child-ticket inventory
- [x] T022 [US3] Review `TODO.md`, `specs/002-module-improvement-roadmap/spec.md`, and `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md` for explicit Kubernetes, runner, monitoring, and out-of-scope separation

### Implementation for User Story 3

- [x] T023 [P] [US3] Add the third-priority GitLab platform capability section plus explicit out-of-scope section to `TODO.md`
- [x] T024 [P] [US3] Align the GitLab platform capability and broader GitLab DevEx theme details in `specs/002-module-improvement-roadmap/spec.md`
- [x] T025 [P] [US3] Align the broader GitLab-management classification rules in `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md`
- [x] T026 [US3] Re-run the US3 ordering and scope-separation review across `TODO.md`, `specs/002-module-improvement-roadmap/spec.md`, and `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md`

**Checkpoint**: `TODO.md` explicitly shows the third improvement track and the
explicit out-of-scope backlog boundary without mixing the two.

---

## Final Phase: Cross-Cutting Verification and Release Readiness

**Purpose**: Ensure the refreshed repo-root backlog and supporting design docs
are internally consistent before the feature is reported complete.

- [x] T027 Re-run all verification commands recorded in `specs/002-module-improvement-roadmap/plan.md`
- [x] T028 Verify `TODO.md`, `specs/002-module-improvement-roadmap/spec.md`, `specs/002-module-improvement-roadmap/research.md`, `specs/002-module-improvement-roadmap/data-model.md`, `specs/002-module-improvement-roadmap/quickstart.md`, and `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md` reflect the same clarified scope and priority order
- [x] T029 Verify `specs/002-module-improvement-roadmap/checklists/requirements.md` still reflects the shipped planning package and add a note if it needs regeneration
- [x] T030 Update `AGENTS.md` if final edits to `specs/002-module-improvement-roadmap/plan.md` change the recorded planning context

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; starts immediately
- **Phase 2**: Depends on Phase 1 and blocks all user stories
- **Phase 3**: Depends on Phase 2 and is the MVP scope
- **Phase 4**: Depends on Phase 3 because dynamic-environment work builds on the
  standardized service-repository track
- **Phase 5**: Depends on Phase 4 because Kubernetes and broader DevEx work
  should build on the first two tracks
- **Final Phase**: Depends on all user stories

### Within Each User Story

- Traceability and review setup before final story review
- `TODO.md` updates before supporting-doc alignment is considered complete
- Story-specific re-review after all related document edits

### Parallel Opportunities

- **Foundational phase**: `T005`, `T006`, and `T007` can run in parallel because
  they target `research.md`, `data-model.md`, and
  `contracts/roadmap-classification.md`
- **US1**: `T011`, `T012`, and `T013` can run in parallel because they target
  `TODO.md`, `spec.md`, and `quickstart.md`
- **US2**: `T017`, `T018`, and `T019` can run in parallel because they target
  `TODO.md`, `spec.md`, and `quickstart.md`
- **US3**: `T023`, `T024`, and `T025` can run in parallel because they target
  `TODO.md`, `spec.md`, and `contracts/roadmap-classification.md`

---

## Implementation Strategy

### MVP First

Complete Phase 1, Phase 2, and Phase 3 first. That yields the smallest useful
outcome: repo-root `TODO.md` exists with the correct top-priority standardized
service-repository track and aligned supporting docs.

### Incremental Delivery

1. Finish US1 to lock the standardized service-repository baseline.
2. Finish US2 to add dynamic environments and e2e DevEx as the second major
   track.
3. Finish US3 to add GitLab platform capability, including runners and
   monitoring, while preserving the explicit out-of-scope boundary.

### Validation Rule

Do not report the feature complete until the plan-recorded verification commands
have been re-run and `TODO.md` remains consistent with `spec.md`, `plan.md`,
`research.md`, `data-model.md`, `quickstart.md`, and
`contracts/roadmap-classification.md`.

---

## Notes

- `TODO.md` is the primary actionable deliverable for this feature
- Keep client-specific and one-off operational work explicit but out of scope
  from the top three improvement tracks
- Stop for approval before using the roadmap to justify actual interface
  widening or repository renaming

## Post-Refinement Alignment Update

- [x] T031 Update `TODO.md` to move runners, monitoring, and reusable pipeline performance testing into the core GitLab platform roadmap and move client-specific work into an explicit out-of-scope section
- [x] T032 Update `specs/002-module-improvement-roadmap/spec.md` so the refined scope matches the Jira epic: runners and monitoring in scope, client-specific work out of scope
- [x] T033 Update `specs/002-module-improvement-roadmap/plan.md`, `research.md`, and `data-model.md` to replace adjacent-work assumptions with the refined in-scope/out-of-scope boundary
- [x] T034 Update `specs/002-module-improvement-roadmap/quickstart.md` and `specs/002-module-improvement-roadmap/contracts/roadmap-classification.md` to reflect the new review and classification rules
- [x] T035 Update `specs/002-module-improvement-roadmap/checklists/requirements.md` notes so the checklist history reflects the post-refinement alignment pass
- [x] T036 Re-run consistency verification across `TODO.md` and `specs/002-module-improvement-roadmap/` for GitLab platform capability, runner/monitoring scope, and explicit client-specific exclusion
