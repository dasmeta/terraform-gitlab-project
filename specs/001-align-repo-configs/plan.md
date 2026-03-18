# Implementation Plan: Repository Config Alignment

**Branch**: `[001-align-repo-configs]` | **Date**: 2026-03-18 | **Spec**: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/001-align-repo-configs/spec.md`
**Input**: Feature specification from `/specs/001-align-repo-configs/spec.md`

## Summary

Align the repository's contributor setup, validation, release, and documentation
configuration to the current `terraform-module-developer` skill and repository
constitution without changing Terraform module inputs, outputs, provider
behavior, or managed GitLab resources. The work is expected to clean up stale
workflow paths, duplicated automation ownership, outdated setup guidance, and
documentation drift between the root README, examples, hooks, and CI
definitions.

## Technical Context

**Language/Version**: Terraform module repository (HCL) with YAML, JSON, shell, and Node-based repository automation; Terraform CLI is used, but `version.tf` does not declare a `required_version`  
**Primary Dependencies**: `gitlabhq/gitlab >= 18.8.2`, `pre-commit`, `pre-commit-terraform`, reusable GitHub Actions workflows, `@commitlint/*`, `semantic-release`  
**Storage**: N/A  
**Terraform Runtime**: Terraform CLI with provider-only version declaration; no OpenTofu-specific configuration is declared in the repository  
**Primary Provider Constraints**: Root module and most examples use `gitlabhq/gitlab >= 18.8.2`; `examples/global_multi_repo` uses `>= 18.9.0`; the README still contains stale older provider guidance that must be aligned  
**Module Scope**: Root module repository plus repository automation, hooks, README, examples, and any skill-backed documentation/test references; no Terraform resource logic changes  
**Testing Strategy**: Root-level static repository checks, `pre-commit` validation, README/example sync review, and targeted `terraform validate` in touched example directories if Terraform example files change  
**Target Platform**: GitLab API via Terraform provider for the module itself, plus GitHub Actions for repository automation  
**Project Type**: Terraform module repository  
**Constraints**: Preserve opinionated wrapper scope, keep interface impact at none, allow no unapproved breaking change or interface widening, keep changes inside this repository, and do not invent repo policy beyond the current skill and constitution  
**Scale/Scope**: `README.md`, `.pre-commit-config.yaml`, `.github/workflows/*.yaml`, `package.json`, `commitlint.config.js`, `githooks/pre-commit`, `githooks/commit-msg`, affected example READMEs, and supporting planning artifacts under `specs/001-align-repo-configs/`; `tests/` is currently absent and must not be standardized beyond what the current skill already defines

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Scope check: PASS. The feature remains inside this repository's GitLab project lifecycle module responsibility and is limited to setup/config alignment.
- Wrapper check: PASS. The plan records interface impact as none and does not widen the Terraform consumer surface.
- Approval check: PASS. No breaking change or interface widening is planned; if implementation pressure changes that, work must stop for approval.
- File coverage check: PASS with required sync targets. Review or update `README.md`, `.pre-commit-config.yaml`, `.github/workflows/checkov.yaml`, `.github/workflows/commitlint.yaml`, `.github/workflows/pre-commit.yaml`, `.github/workflows/semantic-release.yaml`, `.github/workflows/terraform-test.yaml`, `.github/workflows/tflint.yaml`, `.github/workflows/tfsec.yaml`, `package.json`, `commitlint.config.js`, `githooks/pre-commit`, `githooks/commit-msg`, and any affected `examples/` documentation files together. Review `version.tf` and example provider constraints for documentation sync only.
- Provider/version check: PASS with no planned provider contract change. Root provider baseline is `gitlabhq/gitlab >= 18.8.2`; the plan must reconcile stale README guidance and note differing example constraints without changing Terraform behavior unless approved separately.
- Verification check: PASS. Planned commands are `pre-commit run --all-files`, `terraform fmt -check -recursive`, `rg -n 'modules/\\$\\{\\{ matrix.path \\}\\}' .github/workflows`, `rg -n 'semantic-release-action@v3|Semantic-Release|Publish' .github/workflows`, and `terraform init -backend=false && terraform validate` inside each example directory whose `.tf` files change.

## Project Structure

### Documentation (this feature)

```text
specs/001-align-repo-configs/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── README.md
└── tasks.md
```

### Source Code (repository root)

```text
.
├── .github/workflows/
├── .pre-commit-config.yaml
├── README.md
├── commitlint.config.js
├── githooks/
├── package.json
├── version.tf
├── examples/
├── gitlab_project.tf
├── gitlab_branch.tf
├── gitlab_pipline.tf
├── gitlab_project_variable.tf
├── gitlab_repository_files.tf
├── variables.tf
└── output.tf
```

**Structure Decision**: Create `research.md`, `data-model.md`, `quickstart.md`, and `contracts/README.md`. Implementation work should focus on repository-level setup/config files and example documentation. Terraform module source files remain reference context unless documentation or generated-doc sync requires touching them; Terraform resource behavior is out of scope.

## Complexity Tracking

> **Fill only if the Constitution Check reveals a justified exception**

| Exception | Why Needed | Approval or Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------------------|
| None | N/A | No exception is justified by the current spec |

## Phase 0: Research Outcomes

Research output: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/001-align-repo-configs/research.md`

- Treat this as an existing-module, repository-scope alignment task; new-module sourcing and upstream-wrapper selection are not applicable.
- Use Terraform CLI with the existing provider baseline rather than introducing new engine policy in this feature.
- Treat current testing as repository automation plus hook-based validation; examples are documentation and validation context, not a formal test suite.
- Resolve automation drift by aligning workflow responsibilities and path assumptions to the current repository layout.
- Keep any setup choice not defined by the current skill out of scope for this feature plan.

## Phase 1: Design Artifacts

Design outputs:

- Data model: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/001-align-repo-configs/data-model.md`
- Contracts note: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/001-align-repo-configs/contracts/README.md`
- Quickstart: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/001-align-repo-configs/quickstart.md`

Post-design constitution re-check:

- Scope check: PASS. The design artifacts remain setup/config-only.
- Wrapper check: PASS. No Terraform interface changes were introduced by the design.
- Approval check: PASS. No breaking/interface-widening work was introduced during design.
- File coverage check: PASS. The design explicitly tracks docs, examples, hooks, workflows, and verification surfaces together.
- Provider/version check: PASS. Provider/version review remains an explicit implementation check, but no version change is proposed.
- Verification check: PASS. Quickstart and plan preserve concrete verification commands.

## Phase 2: Implementation Planning

Implementation workstreams to execute next:

1. Documentation and setup-path alignment
   - Update root README contributor/setup guidance and remove stale provider/setup references.
   - Ensure example READMEs and root README describe the same contributor workflow and current provider expectations.

2. Workflow ownership and path cleanup
   - Fix stale workflow path assumptions, especially root-vs-module path drift.
   - Remove or repurpose duplicated release responsibility so each workflow has one clear purpose.

3. Local hook and tooling responsibility alignment
   - Align `githooks/`, `commitlint.config.js`, and `package.json` so local commit validation and CI responsibility are not contradictory.
   - Keep any unsupported repo-policy decision out of scope unless already defined by the current skill.

4. Verification and final sync
   - Run planned repository checks.
   - Reconcile any changed docs/examples/workflow references in the same change set before implementation is considered complete.
