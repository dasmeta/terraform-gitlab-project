# Phase 0 Research: Repository Config Alignment

## Decision 1

**Decision**: Treat this feature as repository-scope setup/config alignment for an existing Terraform module, not module behavior work.

**Rationale**: The feature spec explicitly limits the scope to repository setup, contributor workflow, automation, and documentation. The current skill and constitution both require the plan to keep interface impact at none and to stop if the work starts broadening into Terraform module behavior.

**Alternatives considered**: Expanding the feature into Terraform source cleanup or module interface standardization. Rejected because the approved feature scope excludes Terraform code changes.

## Decision 2

**Decision**: Keep the runtime assumption Terraform-first with the current provider baseline, while treating engine pinning as unchanged in this feature.

**Rationale**: `version.tf` declares `gitlabhq/gitlab >= 18.8.2` but no `required_version`. The repository does not declare OpenTofu-specific configuration. The plan can therefore record Terraform CLI usage and provider expectations without inventing a new engine policy.

**Alternatives considered**: Adding a new Terraform/OpenTofu runtime requirement in planning. Rejected because the repository does not currently declare one and the feature is setup-only.

## Decision 3

**Decision**: Use `gitlabhq/gitlab >= 18.8.2` as the root provider baseline and treat README/example version drift as a documentation-alignment problem.

**Rationale**: Root module and most examples use `>= 18.8.2`, `examples/global_multi_repo` uses `>= 18.9.0`, and the root README still shows `>3.0.0` in one provider snippet. This mismatch is precisely the kind of documentation/config drift the feature is meant to resolve.

**Alternatives considered**: Treating the stale README snippet as authoritative or broadening the feature into provider-version refactoring. Rejected because the plan must preserve the current Terraform behavior and only align the repository guidance/configuration around it.

## Decision 4

**Decision**: Model verification as repository automation, hook validation, and documentation/example sync checks rather than a formal Terraform test-suite expansion.

**Rationale**: The repo currently has GitHub Actions for pre-commit, Terraform test, TFLint, TFSEC, and Checkov; `.pre-commit-config.yaml` drives formatting and docs generation; local hooks run pre-commit and commit-message checks; there is no `tests/` directory. The current skill requires examples/tests/docs to stay aligned when relevant, but does not define new repo policy for absent test scaffolding.

**Alternatives considered**: Defining `examples/` as the formal test suite or inventing a new `tests/` policy locally. Rejected because those choices are not defined by the current skill and would introduce repo-specific policy.

## Decision 5

**Decision**: Treat GitLab as the managed platform and GitHub Actions as the repository automation platform.

**Rationale**: The module manages GitLab projects and related resources through the GitLab Terraform provider, while the repository's own CI/release/config validation lives under `.github/workflows/` and `package.json`.

**Alternatives considered**: Treating the repository as end-to-end GitLab automation. Rejected because GitHub Actions is the current repository automation surface.

## Decision 6

**Decision**: Resolve visible automation drift as part of implementation planning, especially duplicate release ownership and stale root/module path assumptions.

**Rationale**: `commitlint.yaml` currently duplicates the release behavior of `semantic-release.yaml` instead of validating commit messages, and `pre-commit.yaml` references `modules/${{ matrix.path }}` even though the repository has no `modules/` directory and no matrix in that workflow. Those are clear alignment targets already justified by the current repo and standards.

**Alternatives considered**: Leaving duplicated ownership or stale paths in place. Rejected because the spec requires one clear documented workflow and valid repository paths.

## Decision 7

**Decision**: Defer any unresolved setup choice not explicitly defined by the current `terraform-module-developer` skill or repository constitution.

**Rationale**: The spec clarification explicitly says unresolved repository setup choices must use only the current skill and bundled standards. The plan may align stale references and contradictory ownership, but it must not invent new local governance.

**Alternatives considered**: Defining new repo-specific policy during planning. Rejected because the user explicitly ruled that out.
