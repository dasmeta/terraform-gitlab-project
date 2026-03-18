# Tasks: Repository Config Alignment

**Input**: Design documents from `/specs/001-align-repo-configs/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`,
`data-model.md`, `contracts/README.md`, `quickstart.md`

**Tests**: Validation tasks are mandatory for this feature because repository
automation, contributor workflow, and documentation can regress consumers and
maintainers even without Terraform behavior changes.

**Organization**: Tasks are grouped by user story so each repository workflow
increment can be implemented and verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when files do not overlap
- **[Story]**: Which user story this task belongs to, for example `US1`
- Include exact file paths in every task description

## Path Conventions

- **Root module context**: `gitlab_project.tf`, `gitlab_branch.tf`,
  `gitlab_pipline.tf`, `gitlab_project_variable.tf`,
  `gitlab_repository_files.tf`, `variables.tf`, `output.tf`, `version.tf`
- **Documentation**: `README.md`, `examples/<name>/README.md`
- **Examples**: `examples/<name>/main.tf`
- **Automation**: `.github/workflows/`, `.pre-commit-config.yaml`,
  `githooks/`, `package.json`, `commitlint.config.js`
- **Planning context**: `specs/001-align-repo-configs/plan.md`,
  `specs/001-align-repo-configs/spec.md`,
  `specs/001-align-repo-configs/research.md`,
  `specs/001-align-repo-configs/quickstart.md`

## Phase 1: Scope and Verification Setup

**Purpose**: Lock scope, affected files, and proof of correctness before making
implementation changes.

- [X] T001 Capture the implementation scope from `specs/001-align-repo-configs/plan.md`, `specs/001-align-repo-configs/spec.md`, and `specs/001-align-repo-configs/research.md`
- [X] T002 Record the exact verification commands from `specs/001-align-repo-configs/quickstart.md` for `README.md`, `.github/workflows/`, `.pre-commit-config.yaml`, `githooks/pre-commit`, `githooks/commit-msg`, `package.json`, and `commitlint.config.js`
- [X] T003 Confirm in `specs/001-align-repo-configs/spec.md` and `specs/001-align-repo-configs/plan.md` that `version.tf`, `variables.tf`, `output.tf`, `gitlab_project.tf`, `gitlab_branch.tf`, `gitlab_pipline.tf`, `gitlab_project_variable.tf`, and `gitlab_repository_files.tf` remain behaviorally unchanged

---

## Phase 2: Foundational Repository Updates

**Purpose**: Shared setup and validation baseline that all user stories depend
on.

**Critical**: Complete this phase before story-specific implementation starts.

- [X] T004 Update contributor prerequisites and root verification commands in `README.md` to match `specs/001-align-repo-configs/quickstart.md`
- [X] T005 [P] Update duplicate hook ownership in `.pre-commit-config.yaml` so root-level validation remains consistent with `README.md`
- [X] T006 [P] Update `githooks/pre-commit` so the root `pre-commit run --all-files` flow stays aligned with `.pre-commit-config.yaml` and `README.md`
- [X] T007 Review `version.tf` while updating provider/version guidance in `README.md`, `examples/basic/README.md`, `examples/branch_protection/README.md`, and `examples/global_multi_repo/README.md`

**Checkpoint**: Shared repository setup guidance and root validation entry
points are aligned before user-story work begins.

---

## Phase 3: User Story 1 - Align Repository Setup Rules (Priority: P1)

**Goal**: Ensure maintainer-facing setup, validation, and release ownership are
described consistently and point only to valid repository paths.

**Independent Test**: `rg -n 'modules/\$\{\{ matrix.path \}\}' .github/workflows`
returns no matches, and the affected workflow files describe root-valid path
usage without stale module-layout assumptions.

### Verification for User Story 1

- [X] T008 [US1] Add maintainer-facing workflow ownership notes in `README.md` and `examples/global_multi_repo/README.md` so the intended automation responsibilities are explicit before workflow edits are finalized
- [X] T009 [US1] Run `rg -n 'modules/\$\{\{ matrix.path \}\}' .github/workflows` and inspect `.github/workflows/pre-commit.yaml`, `.github/workflows/checkov.yaml`, `.github/workflows/terraform-test.yaml`, `.github/workflows/tflint.yaml`, and `.github/workflows/tfsec.yaml` for invalid root/module path assumptions

### Implementation for User Story 1

- [X] T010 [P] [US1] Update `.github/workflows/pre-commit.yaml` to remove stale `modules/${{ matrix.path }}` assumptions and align execution with the repository root
- [X] T011 [P] [US1] Update `.github/workflows/checkov.yaml`, `.github/workflows/terraform-test.yaml`, `.github/workflows/tflint.yaml`, and `.github/workflows/tfsec.yaml` so their path and responsibility definitions match the repository root layout
- [X] T012 [US1] Re-run the US1 path verification and reconcile any remaining maintainer wording in `README.md` and `examples/global_multi_repo/README.md`

**Checkpoint**: User Story 1 is independently documented and verified.

---

## Phase 4: User Story 2 - Bootstrap Contributor Checks Reliably (Priority: P2)

**Goal**: Give contributors one clear local setup path for validation and
commit checks without changing Terraform behavior.

**Independent Test**: From the documentation and local hook/tooling files
alone, a contributor can identify the required pre-PR checks without reading
workflow internals; `pre-commit run --all-files` completes against the updated
setup.

### Verification for User Story 2

- [X] T013 [US2] Update contributor-facing setup and commit-check instructions in `README.md` to reference `githooks/pre-commit`, `githooks/commit-msg`, `.pre-commit-config.yaml`, `package.json`, and `commitlint.config.js`
- [X] T014 [US2] Run `pre-commit run --all-files` and confirm `README.md`, `.pre-commit-config.yaml`, and `githooks/pre-commit` remain in sync with the documented local flow

### Implementation for User Story 2

- [X] T015 [P] [US2] Update `githooks/commit-msg` so commit-policy behavior no longer contradicts `commitlint.config.js` and `package.json`
- [X] T016 [P] [US2] Update `package.json` and `commitlint.config.js` so the documented contributor commit-policy flow in `README.md` matches the active local tooling
- [X] T017 [US2] Reconcile the final contributor setup path across `README.md`, `githooks/pre-commit`, `githooks/commit-msg`, `.pre-commit-config.yaml`, `package.json`, and `commitlint.config.js`
- [X] T018 [US2] Re-run `pre-commit run --all-files` and confirm the US2 contributor flow is documented without requiring workflow inspection

**Checkpoint**: User Story 2 is independently documented and verified.

---

## Phase 5: User Story 3 - Keep Review and Automation Expectations Consistent (Priority: P3)

**Goal**: Ensure reviewer-facing automation ownership is consistent, with no
duplicate release responsibility or stale CI expectations.

**Independent Test**: `rg -n 'semantic-release-action@v3|Semantic-Release|Publish' .github/workflows`
shows a single clear release owner after implementation, and the reviewer-facing
documentation no longer conflicts with CI behavior.

### Verification for User Story 3

- [X] T019 [US3] Add reviewer-facing automation notes in `README.md` and `examples/global_multi_repo/README.md` to distinguish repository automation from the managed GitLab CI example content
- [X] T020 [US3] Run `rg -n 'semantic-release-action@v3|Semantic-Release|Publish' .github/workflows` and inspect `.github/workflows/commitlint.yaml` and `.github/workflows/semantic-release.yaml` for duplicate release ownership

### Implementation for User Story 3

- [X] T021 [P] [US3] Update `.github/workflows/commitlint.yaml` so it either performs real commit-policy validation or no longer duplicates release behavior from `.github/workflows/semantic-release.yaml`
- [X] T022 [P] [US3] Update `.github/workflows/semantic-release.yaml` and any linked release wording in `README.md` so release ownership is singular and consistent
- [X] T023 [US3] Re-run the US3 automation-ownership verification and reconcile any remaining reviewer-facing guidance in `README.md`

**Checkpoint**: User Story 3 is independently documented and verified.

---

## Final Phase: Cross-Cutting Verification and Release Readiness

**Purpose**: Ensure repository-wide sync before work is reported complete.

- [X] T024 Re-run `pre-commit run --all-files` and `terraform fmt -check -recursive` from `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project`
- [X] T025 If `examples/basic/main.tf`, `examples/branch_protection/main.tf`, or `examples/global_multi_repo/main.tf` changed, run `terraform init -backend=false` and `terraform validate` inside each touched `examples/` directory
- [X] T026 Verify `README.md`, `examples/basic/README.md`, `examples/branch_protection/README.md`, `examples/global_multi_repo/README.md`, `.github/workflows/*.yaml`, `githooks/pre-commit`, `githooks/commit-msg`, `.pre-commit-config.yaml`, `package.json`, and `commitlint.config.js` describe the same shipped workflow
- [X] T027 Verify in `specs/001-align-repo-configs/spec.md` that no approval gates changed and confirm `version.tf`, `variables.tf`, `output.tf`, `gitlab_project.tf`, `gitlab_branch.tf`, `gitlab_pipline.tf`, `gitlab_project_variable.tf`, and `gitlab_repository_files.tf` were not widened or behaviorally changed

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; starts immediately
- **Phase 2**: Depends on Phase 1 and blocks all user stories
- **Phase 3 (US1)**: Depends on Phase 2
- **Phase 4 (US2)**: Depends on Phase 3 because `README.md`, `githooks/`, and setup wording overlap with US1 outputs
- **Phase 5 (US3)**: Depends on Phase 4 because `README.md` and `.github/workflows/` ownership wording overlap with the earlier stories
- **Final Phase**: Depends on all implemented user stories

### User Story Dependency Graph

```text
Phase 1 -> Phase 2 -> US1 -> US2 -> US3 -> Final Phase
```

### Within Each User Story

- Update verification assets before the story's final verification run
- Complete workflow/hook/config edits before final README/example reconciliation
- Re-run the story's verification command after implementation before moving on

### Parallel Opportunities

- **US1**: `T010` and `T011` can run in parallel because they touch disjoint workflow files
- **US2**: `T015` and `T016` can run in parallel because `githooks/commit-msg` is separate from `package.json` and `commitlint.config.js`
- **US3**: `T021` and `T022` can run in parallel if release ownership is clearly split before editing, because they target different workflow files

## Parallel Execution Examples

### User Story 1

```bash
Task: T010 Update .github/workflows/pre-commit.yaml
Task: T011 Update .github/workflows/checkov.yaml, .github/workflows/terraform-test.yaml, .github/workflows/tflint.yaml, .github/workflows/tfsec.yaml
```

### User Story 2

```bash
Task: T015 Update githooks/commit-msg
Task: T016 Update package.json and commitlint.config.js
```

### User Story 3

```bash
Task: T021 Update .github/workflows/commitlint.yaml
Task: T022 Update .github/workflows/semantic-release.yaml and linked README.md release wording
```

## Implementation Strategy

### MVP First

- Complete **Phase 1**, **Phase 2**, and **Phase 3 (US1)** first
- This delivers the smallest useful increment: valid repository paths,
  coherent maintainer setup rules, and removal of the most obvious automation
  drift

### Incremental Delivery

- Add **US2** next to stabilize the contributor setup flow after maintainer
  path alignment is in place
- Add **US3** last to finalize reviewer-facing automation ownership and release
  consistency
- Finish with the cross-cutting verification phase before reporting completion

## Notes

- Every task keeps the Terraform module interface narrow and unchanged
- `tests/` remains contextual only; do not invent new test-layout policy in
  this feature
- Stop for approval before implementing any breaking change or interface
  widening
- Do not mark work complete without citing fresh verification commands
