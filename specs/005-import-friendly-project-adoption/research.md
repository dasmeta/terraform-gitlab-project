# Research: Import-Friendly Project Adoption

## Decision: Use the DasMeta module directly from the consumer root

**Rationale**: The requested workflow is to change the local DasMeta module and
point the consumer root at that module path. This keeps the PR in the module
repository and avoids a copied module implementation in the consumer workspace.

**Alternatives considered**:
- Vendor the module under the consumer root. Rejected because it would hide the
  module change from the DasMeta module PR.
- Keep using the registry module only. Rejected because the required optional
  fields are not available until the module change is merged and released.

## Decision: Add explicit optional adoption fields

**Rationale**: Existing projects may have provider-visible settings such as
`squash_commit_template`, `approvals_before_merge`, and
`resolve_outdated_diff_discussions`. Explicit optional attributes let consumers
match existing state without creating a generic pass-through surface.

**Alternatives considered**:
- Ignore the fields. Rejected because Terraform would show drift or changes
  after import.
- Add a generic settings map. Rejected because it weakens the typed wrapper
  contract and makes review harder.

## Decision: Keep branch protections enabled by default

**Rationale**: Existing module consumers expect default branch-protection
resources to be generated. A per-project opt-out supports import-only adoption
without changing the default for other users.

**Alternatives considered**:
- Disable branch protections globally. Rejected because it would be a breaking
  behavioral change.
- Require consumers to import branch protections immediately. Rejected because
  the requested workflow is project import first, without the plan showing
  dozens of extra resource actions.

## Decision: Treat `approvals_before_merge` as compatibility-only

**Rationale**: Provider 18.x still supports the field but marks it deprecated.
For import adoption it is useful to prevent drift for existing projects. The
field should not be presented as the preferred long-term approval workflow.

**Alternatives considered**:
- Omit the field. Rejected because it can produce import drift for existing
  projects.
- Replace it with approval-rule resources in this PR. Rejected because that
  would expand the import scope beyond project adoption.

## Decision: Make `group_key` validation null-safe

**Rationale**: Direct `namespace_id` remains a supported project placement path,
so validation must tolerate omitted `group_key` values.

**Alternatives considered**:
- Require `group_key` for every project. Rejected because it would break the
  documented direct namespace workflow.
