# Feature Specification: Merge Requests Template Support

**Feature Branch**: `006-merge-requests-template`  
**Created**: 2026-06-05  
**Status**: Draft  
**Input**: User description: "DMVP-10134 add optional gitlab_projects merge_requests_template support and forward it to gitlab_project"

## Module Scope and Impact *(mandatory)*

- **Starting Module Path**: repository root, with project behavior implemented in `modules/project`
- **Affected Files or Directories**: `variables.tf`, `modules/project/main.tf`, `README.md`, `examples/basic/main.tf`, `examples/basic/README.md`, and `specs/006-merge-requests-template/`
- **Current Consumer Interface**: `gitlab_projects` supports per-project merge request and commit template settings such as `merge_commit_template`, `squash_commit_template`, and `suggestion_commit_message`, but not GitLab's project-level merge request description template.
- **Proposed Interface Change**: Add optional `gitlab_projects[].merge_requests_template` as a string and forward it to `gitlab_project.this.merge_requests_template`.
- **Breaking Change**: No. Existing consumers that omit the field must keep the current behavior.
- **Interface Widening**: No unapproved broad pass-through. This is a narrow optional project setting aligned with already exposed merge request template behavior.
- **Docs, Examples, and Tests Impact**: Root README input docs, generated module docs when applicable, and at least one example or validation path must show the supported field. Verification commands must be recorded.

## User Scenarios and Testing *(mandatory)*

### User Story 1 - Configure Merge Request Template (Priority: P1)

As a Terraform module consumer, I want to set a default merge request description template per GitLab project so project merge request defaults are reproducible from Terraform instead of being configured manually in the GitLab UI.

**Why this priority**: This is the core request from DMVP-10134 and removes configuration drift for projects that rely on a default merge request description template.

**Independent Test**: A validation fixture or example includes `merge_requests_template` in one project object, and Terraform validation confirms the input is accepted and forwarded through the project module wiring.

**Acceptance Scenarios**:

1. **Given** a project object includes `merge_requests_template`, **When** the module expands the project configuration, **Then** the child project resource receives that value through `gitlab_project.this.merge_requests_template`.
2. **Given** a project object omits `merge_requests_template`, **When** the module expands the project configuration, **Then** the project keeps the current behavior with no value forced by the module.

---

### User Story 2 - Preserve Narrow Project Interface (Priority: P2)

As a module maintainer, I want the new input to stay narrowly scoped so the module does not become a broad pass-through for unrelated GitLab project settings.

**Why this priority**: The repository standards require preserving an opinionated wrapper interface and avoiding unapproved interface widening.

**Independent Test**: Review the resulting input type, project resource mapping, and docs to confirm only `merge_requests_template` was added for this request.

**Acceptance Scenarios**:

1. **Given** the implementation is complete, **When** changed project input fields are reviewed, **Then** only the requested optional field and directly related documentation/example updates are present.

### Edge Cases

- When `merge_requests_template` is omitted, Terraform must treat it as absent/null rather than replacing a GitLab value with an empty string.
- When a consumer supplies a string containing template content, the module should pass it through without module-specific parsing or rewriting.
- Existing examples and README content must remain consistent with the live root `gitlab_projects` object shape.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST preserve a focused GitLab project lifecycle scope.
- **FR-002**: The module MUST add `merge_requests_template` as an optional string attribute on `gitlab_projects[]`.
- **FR-003**: The implementation MUST forward `gitlab_projects[].merge_requests_template` to `gitlab_project.this.merge_requests_template`.
- **FR-004**: The implementation MUST keep omission backward compatible by passing no forced value when the field is absent.
- **FR-005**: The implementation MUST update all affected Terraform files, documentation, examples, and validation evidence in the same change set.
- **FR-006**: The implementation MUST record any provider or version constraint implications.
- **FR-007**: The implementation MUST define and run verification steps required to prove the change works before completion is claimed.
- **FR-008**: Breaking changes or broad interface widening MUST include explicit approval references before implementation begins.

### Key Entities *(include if feature involves data or object schemas)*

- **Project Configuration**: One `gitlab_projects[]` object that defines a GitLab project and optional project-level settings, now including optional `merge_requests_template`.
- **GitLab Project Resource Mapping**: The child module mapping from normalized project configuration to `gitlab_project.this` arguments.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Consumers can configure a per-project merge request description template using documented `gitlab_projects[].merge_requests_template`.
- **SC-002**: Existing consumers that omit `merge_requests_template` continue to validate without changing their input shape.
- **SC-003**: `README.md`, affected examples, and affected Terraform files reflect the new supported field.
- **SC-004**: Verification commands for the feature complete successfully, or any failing command is documented explicitly with the failure reason.
- **SC-005**: No unapproved breaking change or broad interface widening remains in the final plan or implementation.
