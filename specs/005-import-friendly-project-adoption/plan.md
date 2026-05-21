# Implementation Plan: Import-Friendly Project Adoption

**Branch**: `005-import-friendly-project-adoption` | **Date**: 2026-05-21 | **Spec**: [spec.md](/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/specs/005-import-friendly-project-adoption/spec.md)
**Input**: Feature specification from `/specs/005-import-friendly-project-adoption/spec.md`

## Summary

Extend the existing GitLab project wrapper with a narrow set of optional
project-adoption fields and a per-project branch-protection opt-out so a
consumer root can import existing repositories through the local DasMeta module
without Terraform proposing remote changes. Existing consumers keep the current
default behavior because every added field is optional and
`branch_protections_enabled` defaults to true.

## Technical Context

**Terraform Runtime**: Repository-managed Terraform CLI  
**Primary Provider Constraints**: `gitlabhq/gitlab >= 18.8.2` in the module,
validated by a consumer root using provider `18.9.0`  
**Module Scope**: Root module variables, child project module wiring, generated
branch-protection locals, example token placeholder hygiene, and Speckit
evidence  
**Testing Strategy**: Root `terraform validate`, consumer-root `terraform
validate`, and consumer-root `terraform plan` with imports only  
**Target Platform**: GitLab API via Terraform provider  
**Project Type**: Terraform module repository  
**Constraints**: Preserve wrapper defaults; avoid vendored module copies; do
not manage repository files or branch-protection resources during import-only
adoption unless explicitly configured  
**Scale/Scope**: One root module interface update, one child project resource
wiring update, one branch-protection expansion guard, one example hygiene fix,
and one downstream plan proof

## Constitution Check

*GATE: Passes before implementation. Re-checked after design.*

- Scope check: Pass. The change stays inside existing GitLab project resource
  management and does not add unrelated GitLab capabilities.
- Wrapper check: Pass with explicit interface widening. The module adds a small
  number of optional fields needed for import drift control instead of exposing
  a broad provider pass-through.
- Approval check: Pass. The user explicitly asked to change the DasMeta module
  locally and use it from the consumer root instead of creating a local module
  copy.
- Compatibility check: Pass. Defaults remain unchanged; new attributes are
  optional and branch protections still default to enabled.
- Provider/version check: Pass. `approvals_before_merge` is deprecated but
  still present in provider 18.9.0 and is used only as an import-compatibility
  field.
- Verification check: Pass. Required proof is validation plus a consumer plan
  showing imports only and no remote changes.

## Project Structure

### Documentation (this feature)

```text
specs/005-import-friendly-project-adoption/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── README.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
.
├── variables.tf
├── modules/
│   └── project/
│       ├── main.tf
│       └── locals.tf
└── examples/
    └── basic/
        └── main.tf
```

**Structure Decision**:
- Root consumer interface updates live in
  `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/variables.tf`.
- Child project resource forwarding lives in
  `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/modules/project/main.tf`.
- Branch-protection opt-out behavior lives in
  `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/modules/project/locals.tf`.
- Example hygiene lives in
  `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project/examples/basic/main.tf`.
- Consumer verification evidence comes from
  `/Users/juliaaghamyan/Desktop/corify/workspace_module/gitlab_repos`.

## Phase 0: Research Outcomes

- Import adoption requires describing real project settings, not creating
  replacement resources or repository files.
- A narrow optional-field expansion is preferable to a generic project settings
  map because it preserves the wrapper contract and keeps reviewable behavior.
- Branch-protection resources need a per-project opt-out because importing the
  project resource alone should not imply management of every protection rule.
- Null `group_key` handling must be defensive in validation because direct
  `namespace_id` is a supported path.

## Phase 1: Design Outputs

- `research.md` captures the decisions around narrow interface widening,
  branch-protection compatibility, deprecated provider-field handling, and
  validation null-safety.
- `data-model.md` records the added project adoption fields and branch
  protection opt-out semantics.
- `contracts/README.md` confirms the consumer contract remains the typed
  Terraform module interface and no separate API contract is added.
- `quickstart.md` defines the implementation and verification sequence for PR
  reviewers.

## Post-Design Constitution Check

- Scope check: Still passes; no unrelated GitLab platform areas were added.
- Wrapper check: Still passes; the optional fields are explicit and bounded.
- Approval check: Still passes; interface widening is documented and requested
  for import adoption.
- Compatibility check: Still passes; all previous defaults remain in effect
  unless a consumer explicitly opts out.
- Verification check: Still passes; validation and downstream no-change import
  plan are the required evidence.

## Complexity Tracking

No constitution exceptions are required for this feature.
