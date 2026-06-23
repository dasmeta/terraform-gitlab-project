# Feature Specification: Parameterize Dynamic Environment CI

**Feature Branch**: `006-merge-requests-template`
**Created**: 2026-06-23
**Status**: Approved
**Input**: Replace hardcoded central dynamic-environment CI values with grouped
Terraform configuration and generate the pipeline with `yamlencode`.

## Module Scope and Impact

- **Starting Module Path**: repository root and `modules/dynamic_environment`
- **Affected Files or Directories**: `variables.tf`,
  `modules/dynamic_environment/locals.tf`,
  `modules/dynamic_environment/templates/central.gitlab-ci.yml.tftpl`,
  `modules/dynamic_environment/tests/`, `examples/basic/main.tf`, and generated
  README input documentation
- **Current Consumer Interface**: `dynamic_environments_project` configures the
  central project, deployments, cleanup, applications, runner tags, and deploy
  mode; the generated CI still embeds runtime and E2E-specific values
- **Proposed Interface Change**: add optional grouped `ci_config` and
  `e2e_config` objects under `dynamic_environments_project`
- **Breaking Change**: No; existing deployment behavior retains defaults, while
  the unusable placeholder E2E trigger is no longer emitted by default
- **Interface Widening**: Approved narrow extension; only commonly changed CI
  runtime and E2E trigger settings are exposed
- **Docs, Examples, and Tests Impact**: update the basic example, generated
  README tables, and add Terraform tests for default and customized rendering

## User Scenarios and Testing

### User Story 1 - Configure CI Runtime (Priority: P1)

A module consumer can configure the container images, installed packages,
migration job handling, and AWS credential variable names used by the central
dynamic-environment pipeline.

**Independent Test**: Render the managed `.gitlab-ci.yml` with non-default
`ci_config` values and assert that the decoded document contains those values.

**Acceptance Scenarios**:

1. **Given** custom CI runtime values, **When** the module renders the central
   pipeline, **Then** deploy and cleanup jobs use the configured values.
2. **Given** no `ci_config`, **When** the pipeline is rendered, **Then** the
   established deployment defaults remain available.

### User Story 2 - Configure Optional E2E Trigger (Priority: P1)

A module consumer can enable a downstream E2E trigger with a real project,
branch, strategy, and arbitrary variables.

**Independent Test**: Render pipelines with E2E disabled and enabled; assert
that the job is absent by default and uses the supplied trigger and variables
when enabled.

**Acceptance Scenarios**:

1. **Given** omitted `e2e_config`, **When** the pipeline is rendered, **Then**
   no placeholder E2E job is present.
2. **Given** enabled E2E configuration, **When** the pipeline is rendered,
   **Then** project and branch are exposed as global CI variables, the trigger
   references them, and configured variables and rules are merged with defaults.

### User Story 3 - Keep Pipeline Definition in Terraform (Priority: P2)

Maintainers can inspect one Terraform data structure to understand the complete
central CI definition without cross-reading a template containing logic and
environment-specific values.

**Independent Test**: Verify that the central CI content is produced with
`yamlencode` and the obsolete central CI template is absent.

### Edge Cases

- Enabling E2E without a project must fail input validation.
- Empty package lists must render valid no-op package installation behavior.
- Variable names are indirect CI variable references and must remain non-empty.
- Arbitrary E2E variable values may contain GitLab `$VARIABLE` references.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST generate the central CI document from a Terraform
  object using `yamlencode`.
- **FR-002**: The module MUST expose optional grouped `ci_config` settings for
  deploy, cleanup, and placeholder images; Alpine and Python packages;
  migration job name and timeout; and AWS credential variable names.
- **FR-003**: Existing deployment settings MUST retain backward-compatible
  defaults.
- **FR-004**: The module MUST expose optional grouped `e2e_config` settings for
  enabled state, project, branch, strategy, arbitrary string variables, and
  additional rules.
- **FR-005**: E2E MUST be disabled by default and MUST require a non-empty
  project when enabled.
- **FR-006**: The generated pipeline MUST NOT embed the placeholder
  `example/e2e-tests` project.
- **FR-007**: Enabled E2E pipelines MUST expose `E2E_PROJECT` and `E2E_BRANCH`
  as global variables and use `$E2E_PROJECT` and `$E2E_BRANCH` in the trigger.
- **FR-008**: E2E variables MUST merge over the standard E2E variable map and
  additional E2E rules MUST append to the five standard E2E rules.
- **FR-009**: Documentation, examples, and tests MUST describe and verify the
  changed interface.

### Key Entities

- **CI configuration**: Runtime settings shared by generated deploy, placeholder,
  and cleanup jobs.
- **E2E configuration**: Optional downstream pipeline trigger and its variables.
- **Central pipeline document**: Terraform map encoded as managed GitLab CI YAML.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All identified environment-specific hardcoded values are either
  configurable or replaced by safe CI-variable references.
- **SC-002**: Default rendering contains no E2E trigger job.
- **SC-003**: Customized rendering includes 100% of supplied `ci_config` and
  `e2e_config` test values.
- **SC-004**: Terraform formatting, tests, and validation complete successfully.
