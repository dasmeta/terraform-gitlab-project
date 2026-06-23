# Feature Specification: Selectable Container Build Target

**Feature Branch**: `006-merge-requests-template`
**Created**: 2026-06-22
**Status**: Approved
**Input**: Add an on-premises Docker build template for Harbor and Docker Hub and let Terraform consumers select ECR or on-premises registry builds.

## Module Scope and Impact

- **Starting Module Path**: `modules/gitlab_ci_pipelines`
- **Affected Files or Directories**: pipeline locals, root input schema, Terraform tests, module README, basic example, and the shared GitLab CI templates repository
- **Current Consumer Interface**: `gitlab_ci_pipelines[].type = "build_ecr"` selects the ECR template
- **Proposed Interface Change**: support `type = "build"` with pipeline-level `target = "ecr" | "onprem"` while retaining `type = "build_ecr"` as a compatibility alias
- **Breaking Change**: No
- **Interface Widening**: Bounded extension approved by the user
- **Docs, Examples, and Tests Impact**: update all build pipeline examples and add target-specific tests

## User Scenarios and Testing

### User Story 1 - Select a build registry target (Priority: P1)

A module consumer selects either ECR or an on-premises registry without selecting a provider-specific pipeline type.

**Independent Test**: Terraform tests verify the generated include and variables for both targets.

**Acceptance Scenarios**:

1. **Given** `type = "build"` and `target = "ecr"`, **When** Terraform renders the pipeline, **Then** it includes the ECR build template and renders AWS variables.
2. **Given** `type = "build"` and `target = "onprem"`, **When** Terraform renders the pipeline, **Then** it includes the on-premises build template and renders registry variables without credentials.

### User Story 2 - Preserve existing consumers (Priority: P2)

An existing consumer using `type = "build_ecr"` continues to render the same ECR pipeline.

**Independent Test**: Existing `build_ecr` Terraform tests remain green.

**Acceptance Scenarios**:

1. **Given** a legacy `build_ecr` entry, **When** Terraform plans, **Then** the existing ECR include and variables remain valid.

### Edge Cases

- A build entry with an unsupported or missing target is rejected.
- ECR builds require `aws_region` and `image_repository`.
- On-premises builds require `registry_host` and `image_repository`.
- Registry credentials are provided through GitLab project CI/CD variables and are never rendered into repository files.

## Requirements

### Functional Requirements

- **FR-001**: The shared templates repository MUST provide `onprem-build.gitlab-ci.yml`.
- **FR-002**: The on-premises template MUST support Harbor and Docker Hub using standard Docker registry authentication.
- **FR-003**: The module MUST support one target selection per build pipeline.
- **FR-004**: The module MUST retain `type = "build_ecr"` compatibility.
- **FR-005**: Generated files MUST NOT contain registry username or password values.
- **FR-006**: Invalid targets and missing target-specific variables MUST fail validation.
- **FR-007**: `variables.image_tags` MUST accept a list of tag strings and push every configured tag.

### Key Entities

- **Pipeline selector**: `type` identifies the pipeline family and pipeline-level `target` selects its registry implementation.
- **Build variables**: non-secret values rendered into generated CI configuration.
- **Registry credentials**: masked/protected GitLab CI/CD variables managed through `env_variables`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Both ECR and on-premises target tests pass.
- **SC-002**: Existing ECR compatibility tests pass unchanged.
- **SC-003**: Documentation contains copy-pasteable ECR and on-premises configurations.
- **SC-004**: Generated on-premises YAML contains no registry credential values.
- **SC-005**: A two-item image tag list produces two buildx tag arguments.
