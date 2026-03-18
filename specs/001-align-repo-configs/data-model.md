# Data Model: Repository Config Alignment

## Entity: Repository Setup Surface

**Purpose**: Represents the repository-level files and directories that define
contributor setup, automation ownership, release flow, documentation, and
validation entry points.

**Fields**:

- `path`: repository-relative file or directory path
- `category`: one of `documentation`, `hook`, `workflow`, `tooling-config`, `example`, `terraform-context`
- `current_state`: one of `present`, `absent`, `stale`, `duplicated`, `aligned`
- `in_scope`: whether the feature is allowed to modify it
- `notes`: short explanation of why the surface matters

**Validation rules**:

- `path` must exist unless the plan explicitly records it as absent context
- `in_scope` must remain false for Terraform behavior changes
- `current_state` must be justified by repository evidence

## Entity: Validation Entry Point

**Purpose**: Represents a local or CI validation mechanism that contributors or
reviewers use to verify repository health.

**Fields**:

- `name`: human-readable validation name
- `source_path`: file that defines the entry point
- `mode`: one of `local-hook`, `pre-commit`, `ci-workflow`, `manual-review`
- `checks`: high-level responsibilities covered by the entry point
- `references_paths`: repository paths assumed by the entry point
- `status`: one of `current`, `stale`, `needs-alignment`

**Validation rules**:

- Every `references_paths` value must exist in the repository layout
- `checks` must not duplicate another entry point's primary responsibility without justification
- `status` must become `current` or be removed by the end of implementation

## Entity: Verification Asset

**Purpose**: Represents a README section, example document, workflow file, or
hook file that other repository setup surfaces depend on.

**Fields**:

- `path`: repository-relative path
- `asset_type`: one of `readme`, `example-readme`, `workflow`, `hook`, `config`
- `referenced_by`: list of validation entry points or setup surfaces that depend on it
- `must_sync_with`: list of related assets that must describe the same workflow
- `status`: one of `current`, `stale`, `missing-reference`, `needs-review`

**Validation rules**:

- `must_sync_with` relationships must be reciprocal in implementation reasoning
- `status` cannot remain `stale` once the feature is complete

## Relationships

- A `Repository Setup Surface` may define zero or more `Validation Entry Points`.
- A `Validation Entry Point` references one or more `Verification Assets`.
- A `Verification Asset` may need to stay synchronized with other
  `Verification Assets` describing the same contributor workflow.

## State Transitions

- `Repository Setup Surface.current_state`: `present` -> `stale` -> `aligned`
- `Validation Entry Point.status`: `current` -> `needs-alignment` -> `current`
- `Verification Asset.status`: `needs-review` -> `stale` or `current`; `stale` -> `current`
