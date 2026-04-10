# Contract: Roadmap Item Classification

## Purpose

This contract defines the minimum information required when converting a
deduplicated roadmap idea into a `TODO.md` entry, follow-up feature, task list,
ADR, or issue.

## Required Fields

- `title`: Short name of the proposed work item.
- `todo_section`: The target section in `TODO.md`.
- `theme`: One of the approved improvement themes from the roadmap spec.
- `source_ideas`: The exact original Jira lines that informed the item.
- `classification`: `prioritized`, `duplicate`, `adjacent`, or
  `approval-required`.
- `phase`: `Phase 1`, `Phase 2`, `Phase 3`, or `Adjacent`.
- `consumer_impact`: What maintainers or downstream GitLab consumers would
  experience if the item is implemented.
- `scope_boundary`: What the item explicitly does not cover.
- `artifact_impact`: Which of `TODO.md`, `README.md`, `examples/`, `tests/`,
  root Terraform files, or automation files would need to change in a later
  implementation.
- `approval_notes`: Required when the item may widen runtime interface
  ownership, trigger repository renaming, or depend on external platform
  capabilities.
- `verification_expectation`: How readiness will be validated before
  implementation starts.

## Classification Rules

- Use `prioritized` only when the work clearly belongs to one of the three main
  GitLab-management tracks in `TODO.md`.
- Use `duplicate` when the Jira idea is already represented by a broader roadmap
  item and should not create a separate implementation track.
- Use `adjacent` when the work belongs to operational runner management,
  monitoring, client-specific planning, or other non-primary roadmap work.
- Use `approval-required` when the work may broaden the runtime module
  interface, justify repository renaming, or exceed the currently approved
  roadmap ownership.

## Acceptance Criteria

1. Every follow-up item must cite at least one original Jira source line.
2. Every follow-up item must declare one `todo_section` and one `theme`.
3. No follow-up item may omit `scope_boundary` or `artifact_impact`.
4. Any item classified as `approval-required` must name the approval
   dependency before implementation planning begins.
5. Any item added to `TODO.md` must preserve the established priority ordering
   unless maintainers intentionally re-approve a roadmap reorder.
