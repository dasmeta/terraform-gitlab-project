<!--
Sync Impact Report
Version change: template draft -> 1.0.0
Modified principles:
- placeholder principle 1 -> I. Opinionated Wrapper Scope
- placeholder principle 2 -> II. Narrow, Validated Consumer Interface
- placeholder principle 3 -> III. File Coverage Stays in Sync
- placeholder principle 4 -> IV. Explicit Provider and Version Contracts
- placeholder principle 5 -> V. Evidence-Driven Verification
Added sections:
- Module Delivery Standards
- Change Workflow and Approval Gates
Removed sections:
- None
Templates requiring updates:
- updated .specify/templates/plan-template.md
- updated .specify/templates/spec-template.md
- updated .specify/templates/tasks-template.md
Follow-up TODOs:
- None
-->
# terraform-gitlab-project Constitution

## Core Principles

### I. Opinionated Wrapper Scope
This repository MUST remain a focused Terraform module for GitLab project
lifecycle management. Changes MUST preserve a coherent responsibility boundary,
prefer the common use case over edge-case branching, and avoid turning the
module into a generic pass-through for unrelated GitLab resources or workflows.
If requested scope expands beyond this repository's module responsibility, work
MUST stop until the scope change is approved explicitly. Rationale: a narrow,
opinionated module is easier to maintain, test, and adopt safely.

### II. Narrow, Validated Consumer Interface
Inputs and outputs MUST expose only the supported consumer surface for common
use cases. Defaults, derived values, and validated object schemas MUST be
preferred over forwarding rarely used provider options. Any change that
materially broadens consumer inputs, weakens defaults, or mirrors upstream
provider surface area MUST be treated as interface widening and requires
explicit approval before implementation. Rationale: predictable module behavior
depends on a small, documented, validated interface.

### III. File Coverage Stays in Sync
Every interface or behavior change MUST update all affected artifacts in the
same change set: relevant Terraform files, variable and output descriptions,
`README.md`, affected `examples/`, affected `tests/`, and repository automation
files when they govern the changed behavior. Examples and tests MUST describe
the live module interface; stale documentation or stale fixtures are
non-compliant. Rationale: consumers rely on examples and documentation as part
of the module contract.

### IV. Explicit Provider and Version Contracts
Provider expectations and version constraints MUST be declared explicitly in the
repository's version files and re-checked whenever provider-dependent behavior
changes. New and modified Terraform identifiers MUST use lowercase with
underscores, variables and outputs MUST include descriptions, and validation
logic MUST live in the module closest to the managed resources. Rationale:
explicit contracts reduce upgrade risk and keep the interface legible.

### V. Evidence-Driven Verification
No change may be reported as complete without fresh verification evidence.
Interface or behavior changes MUST add or update executable tests or example
validation steps; documentation-only changes MUST be checked against the actual
rendered interface they describe. Final status reports MUST name the commands
run for verification and state whether they passed or failed. Rationale:
verification evidence is required to preserve trust and catch regressions.

## Module Delivery Standards

- Root module files MUST stay grouped by responsibility, such as project,
  branch, pipeline, repository file, variable, output, and version concerns.
- New or modified variable blocks MUST include `type`, `default` when
  applicable, and `description`, with validation added when the module owns the
  rule being enforced.
- Outputs MUST use descriptive names and descriptions that match consumer-facing
  behavior.
- `README.md` examples MUST remain copy-pasteable and aligned with the current
  input and output surface.
- When Terraform-based tests are added or updated, they SHOULD prefer a clear
  staged layout such as setup, example, and assertions.
- Repository automation changes MUST stay inside this repository and support the
  module's documented workflow.

## Change Workflow and Approval Gates

- Every implementation plan MUST record the current repository module state,
  gaps versus this constitution, affected files, interface impact, and the
  intended verification commands.
- Breaking changes MUST include downstream impact analysis and require explicit
  approval before implementation.
- Interface widening MUST be called out explicitly and require approval before
  implementation.
- Shared governance from the bundled constitution-derived standards is
  authoritative for cross-repository rules; local guidance may add
  repository-specific detail but MUST NOT contradict those rules.
- Conflicts between existing repository patterns and this constitution MUST be
  surfaced explicitly before broad standardization work proceeds.
- Scope expansion outside the current repository MUST NOT proceed without new
  direction.

## Governance

This constitution is the authoritative source for repository-level engineering
governance. Amendments MUST be delivered in the same change set as any required
updates to dependent templates or guidance files, and the Sync Impact Report at
the top of this file MUST be refreshed with each amendment.

Versioning policy is semantic:
- MAJOR for removing a principle, redefining a non-negotiable rule, or weakening
  an approval gate in a backward-incompatible way.
- MINOR for adding a principle, adding a new governance section, or materially
  expanding required workflow guidance.
- PATCH for clarifications, wording improvements, and non-semantic refinements.

Compliance review expectations are mandatory for every plan, task list, review,
and completion report:
- confirm module scope remains coherent
- confirm wrapper-preservation and interface impact were assessed
- confirm affected Terraform files, documentation, examples, and tests were
  updated together when required
- confirm provider and version implications were checked
- confirm verification evidence was produced before completion was claimed

**Version**: 1.0.0 | **Ratified**: 2026-03-18 | **Last Amended**: 2026-03-18
