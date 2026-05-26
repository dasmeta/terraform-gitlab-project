# Tasks: Import-Friendly Project Adoption

**Input**: Design documents from `/specs/005-import-friendly-project-adoption/`
**Prerequisites**: plan.md (required), spec.md (required), research.md,
data-model.md, contracts/README.md, quickstart.md

**Tests**: Validation and a downstream consumer plan are mandatory because this
feature exists to prove project imports do not produce remote changes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Phase 1: Speckit and Scope Setup

**Purpose**: Capture the PR scope and required evidence before review.

- [X] T001 Create the Speckit feature package in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/`
- [X] T002 Record interface widening, compatibility defaults, and verification gates in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/spec.md`
- [X] T003 Record design decisions in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/plan.md`, `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/research.md`, and `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/data-model.md`

---

## Phase 2: User Story 1 - Adopt Existing Projects Without Drift (Priority: P1)

**Goal**: Support a downstream root that imports existing GitLab projects
without Terraform proposing remote changes.

**Independent Test**: Run `terraform plan` from the consumer root and confirm
imports only with zero add, change, or destroy actions.

### Implementation for User Story 1

- [X] T004 [US1] Add optional import-adoption project fields in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/variables.tf`
- [X] T005 [US1] Forward optional adoption fields to the project resource in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/modules/project/main.tf`
- [X] T006 [US1] Make root project validation null-safe for omitted `group_key` in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/variables.tf`

### Verification for User Story 1

- [X] T007 [US1] Run `terraform validate` from `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project`
- [X] T008 [US1] Run `terraform validate` from `/Users/juliaaghamyan/Desktop/corify/workspace_module/gitlab_repos`
- [X] T009 [US1] Run `terraform plan -input=false -out=/tmp/gitlab_repos_dasmeta_local.tfplan` from `/Users/juliaaghamyan/Desktop/corify/workspace_module/gitlab_repos` and confirm `58 to import, 0 to add, 0 to change, 0 to destroy`

---

## Phase 3: User Story 2 - Keep Default Branch Protection Behavior Compatible (Priority: P2)

**Goal**: Preserve branch-protection generation by default while supporting an
explicit import-only opt-out.

**Independent Test**: Review the optional variable default and locals expansion
logic to confirm omitted values still behave as enabled.

### Implementation for User Story 2

- [X] T010 [US2] Add optional `branch_protections_enabled` with default-enabled semantics in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/variables.tf`
- [X] T011 [US2] Guard generated default branch protections with the per-project flag in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/modules/project/locals.tf`

### Verification for User Story 2

- [X] T012 [US2] Review `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/modules/project/locals.tf` to confirm omitted `branch_protections_enabled` values still generate protections

---

## Phase 4: User Story 3 - Preserve a Safe Wrapper Boundary (Priority: P3)

**Goal**: Keep the extension narrow and PR-reviewable.

**Independent Test**: Review changed files and confirm the module does not add
unrelated GitLab management features or a generic provider pass-through.

### Implementation for User Story 3

- [X] T013 [US3] Keep adoption fields explicit in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/variables.tf`
- [X] T014 [US3] Replace token-like placeholders in `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/examples/basic/main.tf`

### Verification for User Story 3

- [X] T015 [US3] Search `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project` and the consumer root for token-like placeholders after the example cleanup

---

## Final Phase: PR Readiness

**Purpose**: Provide the Speckit evidence required for review.

- [X] T016 Verify `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/` contains `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/README.md`, and `checklists/requirements.md`
- [X] T017 Confirm the PR evidence references the downstream no-change import plan saved at `/tmp/gitlab_repos_dasmeta_local.tfplan`

## Task Count Summary

- **Total tasks**: 17
- **US1 tasks**: 6
- **US2 tasks**: 3
- **US3 tasks**: 3
- **Setup / Final tasks**: 5
