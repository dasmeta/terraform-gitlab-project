# Feature Specification: Deploy Job Rules

**Feature Branch**: `006-merge-requests-template`  
**Created**: 2026-06-22  
**Status**: Approved  
**Input**: Support GitLab CI rules on generated build and deploy jobs.

## Module Scope and Impact

- **Starting Module Path**: repository root and `modules/gitlab_ci_pipelines`
- **Affected Files or Directories**: `variables.tf`, pipeline renderer, Terraform tests, basic example, docs, and this feature package
- **Current Consumer Interface**: `jobs[]` supports `name` and `variables` for build and deploy pipelines.
- **Proposed Interface Change**: Add optional `jobs[].rules`, supporting `if`, `when`, `allow_failure`, `changes`, `exists`, and `start_in`.
- **Breaking Change**: No.
- **Interface Widening**: Narrow GitLab CI job-rule extension requested by the user.
- **Docs, Examples, and Tests Impact**: Add a branch rule to the development job example and verify generated YAML.

## User Scenarios and Testing

### User Story 1 - Control Deploy Jobs with Rules (Priority: P1)

As a consumer, I can control when each generated build or deploy job runs using GitLab CI rules.

**Independent Test**: Terraform test verifies the generated `deploy-dev` job includes the configured `if` and `when` rule.

**Acceptance Scenarios**:

1. **Given** a job with `rules`, **When** its YAML is generated, **Then** the rules appear under that job.
2. **Given** a job without `rules`, **When** its YAML is generated, **Then** no empty rules block is emitted.
3. **Given** multiple rules, **When** YAML is generated, **Then** their declared order is preserved.

### Edge Cases

- A rule may omit optional fields.
- `changes` and `exists` render as YAML lists.
- Empty rule objects are rejected.
- Existing multi-job and legacy single-job behavior remains unchanged.

## Requirements

- **FR-001**: `jobs[]` MUST accept optional `rules`.
- **FR-002**: Rules MUST support `if`, `when`, `allow_failure`, `changes`, `exists`, and `start_in`.
- **FR-003**: Rules MUST render in declared order under their owning job.
- **FR-004**: Empty `rules` MUST omit the YAML rules block.
- **FR-005**: Empty rule objects MUST fail input validation.
- **FR-006**: Existing job variables, defaults, and legacy behavior MUST remain unchanged.

## Success Criteria

- **SC-001**: Terraform tests confirm a generated branch rule matches the requested YAML.
- **SC-002**: Existing multi-job and legacy tests continue to pass.
- **SC-003**: Root/example validation and formatting checks pass.
