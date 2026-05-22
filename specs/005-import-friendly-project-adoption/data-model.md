# Data Model: Import-Friendly Project Adoption

## Project Configuration

Represents one GitLab project managed by the module.

### Added optional attributes

- `squash_commit_template`: Optional string forwarded to `gitlab_project` when
  present so imported projects can preserve their existing squash commit
  template.
- `approvals_before_merge`: Optional number forwarded to `gitlab_project` when
  present for provider-18.x import compatibility. This field is deprecated by
  the provider and should not be treated as the preferred future approval
  model.
- `resolve_outdated_diff_discussions`: Optional boolean forwarded to
  `gitlab_project` when present so imported projects can preserve their
  discussion-resolution setting.
- `branch_protections_enabled`: Optional boolean controlling whether the module
  generates default branch-protection resources for the project. Defaults to
  true.

## Branch Protection Expansion

Derived from each project configuration.

### Rules

- When `branch_protections_enabled` is omitted, default branch protections are
  generated exactly as before.
- When `branch_protections_enabled` is true, default branch protections are
  generated.
- When `branch_protections_enabled` is false, generated default branch
  protections are skipped for that project.

## Consumer Import Plan

Represents downstream verification from a root module that points at this local
module path.

### Required evidence

- Terraform initializes and validates successfully.
- Terraform plan reports imports only, with zero add, change, and destroy
  actions.
- Repository files and branch-protection resources are not introduced as
  unexpected side effects of project import adoption.
