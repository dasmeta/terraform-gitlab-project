# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. Replace all
placeholders with repository-specific details before implementation starts.

## Summary

[Extract the primary requirement, affected module surface, and planned
verification approach from the feature spec.]

## Technical Context

**Terraform Runtime**: [e.g., Terraform 1.6.x or OpenTofu 1.8.x]  
**Primary Provider Constraints**: [e.g., gitlabhq/gitlab >= 18.8.2]  
**Module Scope**: [root module only, root module + examples, or NEEDS CLARIFICATION]  
**Testing Strategy**: [e.g., terraform validate, example-based tests, README example verification]  
**Target Platform**: GitLab API via Terraform provider  
**Project Type**: Terraform module repository  
**Constraints**: [e.g., preserve opinionated wrapper interface, no unapproved interface widening, no unapproved breaking changes]  
**Scale/Scope**: [affected files, examples, tests, automation]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Scope check: confirm the change stays within this repository's GitLab project
  lifecycle module responsibility.
- Wrapper check: record how the change preserves an opinionated, validated
  consumer interface instead of widening into provider pass-through.
- Approval check: flag any breaking change or interface widening and link the
  explicit approval before implementation starts.
- File coverage check: list every affected Terraform file plus `README.md`,
  `examples/`, `tests/`, and automation files that must be updated together.
- Provider/version check: record whether `version.tf`, example constraints, or
  provider-dependent behavior must change.
- Verification check: name the exact commands that will prove the change is
  correct before completion is claimed.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output when needed
├── quickstart.md        # Phase 1 output when needed
├── contracts/           # Phase 1 output when needed
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
.
├── gitlab_project.tf
├── gitlab_branch.tf
├── gitlab_pipline.tf
├── gitlab_project_variable.tf
├── gitlab_repository_files.tf
├── variables.tf
├── output.tf
├── version.tf
├── README.md
├── examples/
└── tests/
```

**Structure Decision**: [List the exact files and directories this feature will
modify or create. Keep files grouped by responsibility.]

## Complexity Tracking

> **Fill only if the Constitution Check reveals a justified exception**

| Exception | Why Needed | Approval or Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------------------|
| [e.g., interface widening] | [specific use case] | [approval link or reason narrower interface failed] |
| [e.g., breaking change] | [specific problem] | [approval link or compatibility path rejected] |
