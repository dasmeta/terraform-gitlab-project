# Tasks: Dynamic Environments

**Input**: Design documents from `specs/005-dynamic-environments/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/dynamic-environments-input.md`, `quickstart.md`

## Phase 1: Setup

- [x] T001 Inspect provider resource names and current Terraform module boundaries in `providers.tf`, `modules/project/main.tf`, and `modules/project/outputs.tf`
- [x] T002 Confirm generated file content ownership and static template placement in `locals.tf` and `modules/project/locals.tf`

## Phase 2: Foundational

- [x] T003 Add root `dynamic_environments_project` input schema and validation in `variables.tf`
- [x] T004 Add `gitlab_projects[].dynamic_environment` nested input schema and validation in `variables.tf`
- [x] T005 Normalize central dynamic environment project and service opt-in data in `locals.tf`
- [x] T006 Pass normalized dynamic environment data into `modules/project` from `main.tf`
- [x] T007 Add matching child-module input variables in `modules/project/variables.tf`

## Phase 3: User Story 1 - Generate Central Dynamic Environment Project Files (Priority: P1)

**Goal**: Enable a central dynamic environments project and generate orchestration files through an MR.

**Independent Test**: With central feature enabled, Terraform plan includes generated repository files and an MR for `config/applications.yaml`, `scripts/deploy_stack.py`, `scripts/clean_stack.py`, and `.gitlab-ci.yml`.

- [x] T008 [US1] Add central project creation or reuse logic in `modules/project/main.tf`
- [x] T009 [US1] Render `dynamic_environments_project.applications` to YAML content in `modules/project/locals.tf`
- [x] T010 [US1] Add generated central `scripts/deploy_stack.py` content local in `modules/project/locals.tf`
- [x] T011 [US1] Add generated central `scripts/clean_stack.py` content local in `modules/project/locals.tf`
- [x] T012 [US1] Add generated central `.gitlab-ci.yml` content local in `modules/project/locals.tf`
- [x] T013 [US1] Add central branch, repository file, and merge request resources in `modules/project/main.tf`
- [x] T014 [US1] Add central dynamic environment outputs in `modules/project/outputs.tf` and root `outputs.tf`

## Phase 4: User Story 2 - Opt Service Repositories Into Dynamic Environment Trigger CI (Priority: P2)

**Goal**: Generate a reusable service CI trigger file and MR only for opted-in repositories.

**Independent Test**: With one service enabled and one disabled, only the enabled service project receives dynamic environment file and MR resources.

- [x] T015 [US2] Build enabled service dynamic environment map in `modules/project/locals.tf`
- [x] T016 [US2] Render service reusable CI trigger file content in `modules/project/locals.tf`
- [x] T017 [US2] Add service branch, repository file, and merge request resources in `modules/project/main.tf`
- [x] T018 [US2] Add service dynamic environment outputs in `modules/project/outputs.tf` and root `outputs.tf`

## Phase 5: User Story 3 - Preserve Existing CI Files While Guiding Manual Include (Priority: P3)

**Goal**: Keep root service `.gitlab-ci.yml` untouched by default and guide operators through MR descriptions.

**Independent Test**: Service MR description includes the local include snippet and no root CI repository-file resource is created.

- [x] T019 [US3] Add service MR description content with manual include snippet in `modules/project/locals.tf`
- [x] T020 [US3] Verify no root service `.gitlab-ci.yml` repository-file resource is created in `modules/project/main.tf`

## Phase 6: Documentation, Examples, and Validation

- [x] T021 [P] Update `examples/basic/main.tf` with central and service dynamic environment examples
- [x] T022 [P] Update `examples/basic/README.md` with dynamic environment usage notes
- [x] T023 Update `README.md` with input behavior, generated files, MR workflow, and include snippet
- [x] T024 Run `terraform fmt -recursive`
- [x] T025 Run `terraform init -backend=false`
- [x] T026 Run `terraform validate`
- [x] T027 Run example validation or document provider-credential limitation in `specs/005-dynamic-environments/quickstart.md`
- [x] T028 Document GitLab API token requirements for MR creation in `README.md`

## Phase 7: DMVP-10061 - GitLab Agent Config Generation

**Goal**: Generate GitLab Agent `config.yaml` in the central dynamic environments project by default, while keeping the target and access lists configurable.

**Independent Test**: With `dynamic_environments_project.gitlab_agent.enabled = true`, Terraform plans a branch, repository file, and merge request for `.gitlab/agents/<agent-name>/config.yaml` in the central dynamic environments project by default.

- [x] T029 [DMVP-10061] Add `dynamic_environments_project.gitlab_agent` and `deploy_mode` input schema and validation in `variables.tf`
- [x] T030 [DMVP-10061] Pass managed project paths into dedicated `modules/gitlab_agent_config` from root `main.tf`
- [x] T031 [DMVP-10061] Resolve effective `GITLAB_AGENT_PATH` at the root and pass it into `modules/dynamic_environment`
- [x] T032 [DMVP-10061] Generate GitLab Agent `ci_access` YAML in `modules/gitlab_agent_config`
- [x] T033 [DMVP-10061] Add agent config branch, repository file, and merge-request resources in `modules/gitlab_agent_config`
- [x] T034 [DMVP-10061] Add `deploy_mode = "gitlab_agent"` central CI kube context selection
- [x] T035 [DMVP-10061] Add outputs for effective agent path and generated config file target
- [x] T036 [DMVP-10061] Update README, example, and Speckit contracts/quickstart for agent config ownership
- [x] T037 [DMVP-10061] Add optional GitLab Agent registration and token creation
- [x] T038 [DMVP-10061] Add optional Helm deployment for the `gitlab/gitlab-agent` chart
- [x] T039 [DMVP-10061] Document that generated agent tokens are sensitive and stored in Terraform state when registration/install is enabled

## Dependencies

- Phase 1 must complete before Phase 2.
- Phase 2 must complete before any user story.
- User Story 1 is the MVP and should complete before User Story 2.
- User Story 2 should complete before User Story 3.
- Documentation and validation complete after all selected stories.

## Parallel Execution Examples

- T021 and T022 can run in parallel after implementation because they touch different files.
- T010, T011, and T012 can be drafted independently before T013 wires them into resources.
- T014 and T018 can be updated after their respective resource phases without blocking generated content work.

## Implementation Strategy

Deliver the MVP by implementing User Story 1 first, then add service opt-in resources for User Story 2, then finalize the service MR description behavior for User Story 3. Keep existing consumers unaffected when all new inputs are omitted.
