# Feature Specification: Import-Friendly Project Adoption

**Feature Branch**: `005-import-friendly-project-adoption`  
**Created**: 2026-05-21  
**Status**: Draft  
**Input**: User description: "change dasmeta module locally and use it from a consumer root so imported GitLab projects plan with no remote changes"

## Module Scope and Impact *(mandatory)*

- **Starting Module Path**: repository root
- **Affected Files or Directories**: `variables.tf`, `modules/project/main.tf`,
  `modules/project/locals.tf`, `examples/basic/main.tf`, and consumer-side
  verification evidence from a local module source
- **Current Consumer Interface**: The root module accepts grouped GitLab
  project objects and forwards supported project settings to the child project
  module while creating default branch-protection resources for every project
- **Proposed Interface Change**: Add narrowly scoped optional project fields
  required to adopt existing GitLab projects without drift, and add an explicit
  per-project switch to skip the module-created default branch protection when
  importing projects whose branch protections are not being adopted
- **Breaking Change**: No
- **Interface Widening**: Yes. The change adds optional fields only and keeps
  existing defaults unchanged for current consumers.
- **Docs, Examples, and Tests Impact**: The basic example must avoid real token
  patterns, and verification must include Terraform validation plus a consumer
  plan that proves imported projects produce no add, change, or destroy actions

## Clarifications

### Session 2026-05-21

- Q: Should the consumer root vendor a copy of the module? -> A: No. Use the
  local DasMeta module repository directly.
- Q: Should importing existing projects create repository files or branch
  protection resources by default? -> A: No. The import workflow should only
  import existing GitLab projects unless those resources are explicitly
  configured later.
- Q: Is the deprecated GitLab `approvals_before_merge` field allowed? -> A: It
  may be exposed as an optional compatibility field while provider 18.x still
  supports it, only to prevent import drift for existing projects.

## Assumptions

- Existing consumers that omit the new optional fields keep the same project and
  default branch-protection behavior.
- Imported-project adoption is limited to GitLab project attributes already
  supported by the provider and does not add new management domains such as
  runners, integrations, or repository files.
- Live import verification is performed from a consumer root that points to this
  local module repository.

## User Scenarios and Testing *(mandatory)*

### User Story 1 - Adopt Existing Projects Without Drift (Priority: P1)

As a platform engineer importing existing GitLab repositories, I want the module
to accept existing project settings so Terraform can adopt the repositories
without proposing remote changes.

**Why this priority**: Import adoption is blocked if the module cannot describe
the current project settings closely enough to produce a no-change plan.

**Independent Test**: Run Terraform plan from a consumer root using this local
module source and confirm the plan reports imports only, with zero add, change,
or destroy actions.

**Acceptance Scenarios**:

1. **Given** a consumer root defines existing projects with imported IDs,
   **When** Terraform plans with this local module, **Then** project resources
   can be imported without remote add, change, or destroy actions.
2. **Given** an imported project has existing approval or discussion settings,
   **When** those settings are provided through optional fields, **Then** the
   provider receives the values and does not show drift for those attributes.

---

### User Story 2 - Keep Default Branch Protection Behavior Compatible (Priority: P2)

As an existing module consumer, I want default branch protection behavior to
remain enabled unless I explicitly opt out for an import-only workflow.

**Why this priority**: The new import workflow must not silently reduce
protection coverage for existing module users.

**Independent Test**: Review the module default and child-module expansion logic
to confirm `branch_protections_enabled` defaults to true and only suppresses
generated protections when set false for a project.

**Acceptance Scenarios**:

1. **Given** a consumer omits `branch_protections_enabled`, **When** the module
   expands project configuration, **Then** default branch protections are still
   generated as before.
2. **Given** a consumer sets `branch_protections_enabled = false` for an import
   target, **When** the module expands project configuration, **Then** no
   module-created branch-protection resource is generated for that project.

---

### User Story 3 - Preserve a Safe Wrapper Boundary (Priority: P3)

As a maintainer, I want this extension to stay narrowly scoped so the wrapper
does not become a broad pass-through for every GitLab project field.

**Why this priority**: The module remains maintainable only if optional fields
are added for a demonstrated adoption need and existing defaults stay intact.

**Independent Test**: Review the final change set and confirm only the
import-needed fields and branch-protection opt-out were added.

**Acceptance Scenarios**:

1. **Given** maintainers review the PR, **When** they inspect the interface
   changes, **Then** they can identify the specific import-drift attributes and
   the compatibility default for branch protections.
2. **Given** a future request asks for unrelated GitLab project settings,
   **When** this feature is used as precedent, **Then** the request still needs
   its own explicit scope and verification evidence.

## Edge Cases

- `group_key` may be omitted for projects that use direct `namespace_id`; root
  validation must not call `contains()` with a null lookup value.
- `approvals_before_merge` is deprecated by the GitLab provider and should be
  treated as a provider-18.x compatibility field, not a preferred new workflow.
- Consumers may disable branch protections only for import adoption while still
  managing branch protections for other projects in the same module call.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST support import-only project adoption without
  requiring consumers to copy or vendor the module locally.
- **FR-002**: The module MUST expose only optional fields for adoption-specific
  project drift that has been observed in the consumer plan.
- **FR-003**: The module MUST keep default branch-protection generation enabled
  for projects that do not explicitly opt out.
- **FR-004**: The module MUST allow a project to opt out of generated default
  branch protections for import-only adoption.
- **FR-005**: The module MUST forward supported optional adoption fields to the
  `gitlab_project` resource.
- **FR-006**: Root validation MUST handle omitted `group_key` values without
  failing due to null validation helper inputs.
- **FR-007**: Example content touched by the change MUST avoid real token-like
  placeholder patterns.
- **FR-008**: Verification evidence MUST include Terraform validation for this
  module and a consumer-root plan showing imports only.

### Key Entities *(include if feature involves data or object schemas)*

- **Project Adoption Field**: An optional project object attribute that mirrors
  an existing GitLab project setting and is forwarded to the provider to avoid
  drift during import.
- **Branch Protection Opt-Out**: A per-project boolean that controls whether
  the module generates default branch-protection resources for that project.
- **Consumer Import Plan**: A Terraform plan from a downstream root module that
  uses this local module source and proves the adoption workflow has no remote
  add, change, or destroy actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The consumer import plan reports `58 to import, 0 to add, 0 to
  change, 0 to destroy` when pointed at the local module.
- **SC-002**: Root `terraform validate` passes in the module repository after
  the interface changes.
- **SC-003**: Existing consumers that omit the new optional fields retain the
  previous branch-protection default behavior.
- **SC-004**: Reviewers can identify the Speckit package for this PR under
  `specs/005-import-friendly-project-adoption/`.
