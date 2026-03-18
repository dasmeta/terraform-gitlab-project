# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## Module Scope and Impact *(mandatory)*

- **Starting Module Path**: [repository root or submodule path]
- **Affected Files or Directories**: [exact Terraform files, examples, tests,
  README, automation]
- **Current Consumer Interface**: [inputs, outputs, and behaviors touched by
  this feature]
- **Proposed Interface Change**: [new input, output, validation, or behavior]
- **Breaking Change**: [No, or Yes with approval reference]
- **Interface Widening**: [No, or Yes with approval reference]
- **Docs, Examples, and Tests Impact**: [what must be updated together]

## User Scenarios and Testing *(mandatory)*

<!--
  User stories should be prioritized as independent Terraform module outcomes.
  Each story must be testable on its own through validation, example execution,
  or targeted assertions that prove the module behavior.
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe the consumer-facing Terraform workflow in plain language.]

**Why this priority**: [Explain the value and why it is highest priority.]

**Independent Test**: [Describe the exact validation, example, or assertion that
proves this story works independently.]

**Acceptance Scenarios**:

1. **Given** [initial module input state], **When** [consumer applies the
   configuration], **Then** [expected GitLab resource or module behavior]
2. **Given** [initial module input state], **When** [consumer changes the
   configuration], **Then** [expected module behavior]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this Terraform consumer workflow in plain language.]

**Why this priority**: [Explain the value and why it has this priority level.]

**Independent Test**: [Describe how this can be validated independently.]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this Terraform consumer workflow in plain language.]

**Why this priority**: [Explain the value and why it has this priority level.]

**Independent Test**: [Describe how this can be validated independently.]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- What happens when provider validation rejects a requested input or object
  shape?
- How does the module behave when optional nested settings are omitted?
- What happens to README examples, example fixtures, and tests when the consumer
  interface changes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST preserve a focused GitLab project lifecycle scope.
- **FR-002**: The module MUST keep a narrow, validated consumer interface and
  document any new or changed inputs and outputs.
- **FR-003**: The implementation MUST update all affected Terraform files,
  documentation, examples, and tests in the same change set.
- **FR-004**: The implementation MUST record any provider or version constraint
  implications.
- **FR-005**: The implementation MUST define the verification steps required to
  prove the change works before completion is claimed.
- **FR-006**: Breaking changes or interface widening MUST include explicit
  approval references before implementation begins.

### Key Entities *(include if feature involves data or object schemas)*

- **[Entity 1]**: [What it represents and the key attributes or object fields]
- **[Entity 2]**: [What it represents and how it relates to the module]

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Consumers can apply the changed module behavior using documented
  inputs without consulting implementation details.
- **SC-002**: All changed inputs, outputs, and behaviors are reflected in
  `README.md`, affected `examples/`, and affected `tests/`.
- **SC-003**: Verification commands for the feature complete successfully, or
  any failing command is documented explicitly with the failure reason.
- **SC-004**: No unapproved breaking change or interface widening remains in the
  final plan or implementation.
