# Feature Specification: Deploy Agent Multi-Job Pipeline

**Feature Branch**: `006-merge-requests-template`  
**Created**: 2026-06-22  
**Status**: Approved  
**Input**: Generate multiple jobs in one reusable CI file, with `ci-pipelines/deploy.gitlab-ci.yml` as the default deploy path.

## Module Scope and Impact

- **Starting Module Path**: repository root and `modules/gitlab_ci_pipelines`
- **Affected Files or Directories**: `variables.tf`, `modules/gitlab_ci_pipelines/main.tf`, module documentation, root documentation, basic example, and this feature package
- **Current Consumer Interface**: A `build_ecr` or `deploy_agent` pipeline generates one job from `job_name` and `variables`.
- **Proposed Interface Change**: Add optional `jobs`, where each entry has a unique job `name` and pipeline-specific `variables`. When `jobs` is non-empty, generate one include and all listed jobs in the same file.
- **Breaking Change**: Approved by the user. The default `deploy_agent` path changes from `ci-pipelines/deploy-gitlab.ci.yaml` to `ci-pipelines/deploy.gitlab-ci.yml`.
- **Interface Widening**: Approved narrow extension for multiple jobs across the supported pipeline types.
- **Docs, Examples, and Tests Impact**: Update the basic example and docs to show `build-dev`, `build-prod`, `deploy-dev`, and `deploy-prod`; preserve the legacy single-job shape.

## User Scenarios and Testing

### User Story 1 - Generate Environment Deploy Jobs (Priority: P1)

As a consumer, I can define development and production deploy jobs in one generated deploy pipeline file.

**Independent Test**: Static rendering checks confirm one include, both job names, and environment-specific variables.

**Acceptance Scenarios**:

1. **Given** a `build_ecr` or `deploy_agent` entry with two `jobs`, **When** content is generated, **Then** one file contains one include and both jobs.
2. **Given** no explicit `file_path`, **When** a deploy-agent pipeline is generated, **Then** its path is `ci-pipelines/deploy.gitlab-ci.yml`.
3. **Given** a legacy `build_ecr` or `deploy_agent` entry with only `variables`, **When** content is generated, **Then** one job is still produced using `job_name` or the default job name.

### Edge Cases

- Job names must be unique within one pipeline entry.
- An empty `jobs` list uses the legacy single-job behavior.
- Defaults such as `KUBE_NAMESPACE_CREATE`, `HELM_WAIT`, and `HELM_TIMEOUT` apply independently to every job.
- `build_ecr` follows the same multi-job and legacy single-job behavior as `deploy_agent`.

## Requirements

### Functional Requirements

- **FR-001**: `gitlab_ci_pipelines[]` MUST accept optional `jobs`.
- **FR-002**: Each `jobs[]` entry MUST contain `name` and MAY contain `variables`.
- **FR-003**: Non-empty `jobs` MUST generate all jobs in one pipeline file with one shared include.
- **FR-004**: Each job MUST merge pipeline-type defaults with its own variables.
- **FR-005**: Legacy `job_name` and `variables` MUST remain supported when `jobs` is omitted or empty.
- **FR-006**: The default `deploy_agent` path MUST be `ci-pipelines/deploy.gitlab-ci.yml`.
- **FR-007**: `build_ecr` behavior and default path MUST remain unchanged except that it also accepts `jobs`.
- **FR-008**: Generated files MUST retain the Terraform-managed header.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A two-job deploy configuration produces `deploy-dev` and `deploy-prod` in one generated file.
- **SC-002**: The generated file contains only one include block.
- **SC-003**: Legacy single-job static checks continue to pass.
- **SC-004**: Formatting and repository diff checks pass.
