# Research: Improve Module Quality

## Verification Strategy

**Decision**: Use a layered, non-live verification strategy centered on
`pre-commit` plus targeted `terraform validate` runs against the root module
and small example fixtures, including at least one valid primary-flow example
and optional invalid configuration fixtures that prove any new validation
errors. Treat README and example review as required verification in the same
change, and do not plan provider-backed `apply` testing or a new repository-wide
test suite for this feature.

**Rationale**: This feature is about clarifying supported configuration paths,
tightening input validation, and keeping docs and examples trustworthy without
widening scope. The repo already uses repository automation and Terraform-based
validation, while it does not currently ship a dedicated `tests/` suite for
this module. The highest-value evidence is concrete validation of the root
module interface and example fixtures without requiring live GitLab credentials.

**Alternatives considered**: Live acceptance tests against a real GitLab
namespace were rejected because they increase scope and environment
dependencies. A new `terraform test` or repository-wide tests harness was
rejected because this feature does not justify adopting new global test policy.
Relying only on README review and one happy-path example was rejected because
it would not prove that unsupported combinations fail clearly.

## Consumer Contract Boundary

**Decision**: Treat the effective external consumer contract as the root module
surface only: `projects_enabled`, `gitlab_groups`, `gitlab_projects`,
`global_env_variables`, plus the three documented outputs. The contract
boundary for this feature is the root-level behavior consumers rely on today:
namespace selection, group creation versus existing-group reference, project
variable precedence, and the fact that `projects_enabled = false` still allows
group creation.

**Rationale**: Those are the only stable entrypoints exposed directly to
downstream users. The child modules are implementation details, and the current
`gitlab_projects` shape is intentionally loose, so the practical contract is a
combination of root validations, local normalization rules, and README/example
guidance rather than a new machine-readable schema.

**Alternatives considered**: Treating child module inputs or provider resources
as part of the consumer contract was rejected because consumers do not use them
directly. Treating every currently accepted project attribute as separately
contractual was rejected because many fields are provider-aligned details
rather than intentionally promised module-specific behavior.

## Contract Artifact Decision

**Decision**: Do not add a dedicated public contract artifact for this feature.
Record the contract boundary and unsupported combinations in this research
record, then carry the clarified rules into `README.md`, examples, and
verification.

**Rationale**: This feature clarifies an existing Terraform module interface
rather than introducing a new API, CLI grammar, or machine-readable external
schema. Adding another prose contract file would duplicate the README and
specification without increasing enforceability.

**Alternatives considered**: Adding a dedicated consumer contract document was
rejected because it would create an extra artifact to keep in sync for the same
interface. Adding a machine-readable schema was rejected because the module
does not currently expose a strict, closed object model for all project input
attributes.

## Namespace Resolution Rules

**Decision**: Treat project namespace selection as an explicit contract with
three supported paths only: `namespace_id` alone, `group_key` resolving through
`gitlab_groups`, or the existing single-group implicit fallback when exactly
one group exists. Plan to reject `namespace_id` plus `group_key` together as
an ambiguous combination instead of silently preferring one over the other,
subject to implementation compatibility review.

**Rationale**: The current resolver silently prefers `namespace_id`, silently
falls back to the first group in some cases, and does not prove that a
supplied `group_key` actually resolves. Clarifying the supported paths reduces
trial-and-error without widening scope.

**Alternatives considered**: Leaving the current silent precedence untouched
and only documenting it was rejected because the ambiguity would remain.
Removing the single-group fallback entirely was rejected at planning time
because it risks breaking existing baseline consumers.

## Group Mode Rules

**Decision**: Treat `gitlab_groups` as two strict modes only: managed group
(`create = true`, require `name` and `path`) or existing-group reference
(`create = false`, require `existing_group_id`). Treat mixed or partial
combinations as unsupported and validate them before resource creation.

**Rationale**: The implementation already behaves as if these are two modes,
but today it tolerates partial existing-group entries and ignored fields.
Making the modes explicit aligns docs, examples, and validation around what the
module already intends to support.

**Alternatives considered**: Leaving `create = false` entries permissive and
depending on downstream failures was rejected because it preserves ambiguity.
Adding namespace discovery for missing ids was rejected because it adds new
behavior and expands scope.

## Resolvability Requirement

**Decision**: Require every project-to-group path to resolve deterministically
before resource creation, including validation that any `group_key` matches a
declared group and that any referenced existing group supplies a usable
namespace id.

**Rationale**: Current validation checks presence in some cases, but not full
resolvability. A project can still reach an invalid effective namespace path
through an unknown `group_key` or an existing group entry without an id, which
causes a later and less clear failure.

**Alternatives considered**: Deferring failures to Terraform or provider
execution was rejected because those messages arrive too late. Auto-discovery
of missing group ids was rejected because it adds new behavior.

## Variable Precedence

**Decision**: Keep CI/CD variable precedence as key-based replacement:
project-level `env_variables` override `global_env_variables` by key, and the
project entry replaces the full variable definition for that key instead of
merging individual attributes.

**Rationale**: This matches the current implementation and preserves the
documented override path without introducing hidden inheritance behavior.

**Alternatives considered**: Field-level inheritance from global to project
variables was rejected because it changes semantics and adds surprise. Banning
duplicate keys across global and project scopes was rejected because it removes
a supported override path.

## Compatibility Guardrail

**Decision**: Preserve the documented single-group fallback and the existing
shared-variable override path while tightening only the ambiguous or
unresolvable combinations.

**Rationale**: This feature is a quality and validation pass, not a scope
expansion or compatibility reset. Existing consumers should keep working when
they rely on the already documented baseline workflows.

**Alternatives considered**: Removing the single-group fallback entirely or
changing variable precedence semantics was rejected because either change would
turn a clarification feature into an unapproved breaking change.

## Default Value Ownership

**Decision**: Move default project setting values out of `locals.tf` and
declare them through explicit variable definitions that form part of the
consumer-facing module contract.

**Rationale**: The clarified spec requires default behavior to be visible and
owned by variable definitions instead of being embedded in local normalization.
That keeps defaults easier to document, review, and validate as part of the
wrapper interface.

**Alternatives considered**: Leaving defaults embedded in `locals.tf` was
rejected because it hides contract behavior in implementation details.
Duplicating defaults in both variables and locals was rejected because it would
create drift risk and unclear ownership.

## Variable Description Placement

**Decision**: Keep variable descriptions adjacent to each individual variable
block instead of relying on one separate shared description section for many
fields.

**Rationale**: The spec now treats field-local descriptions as part of the
consumer contract. Co-locating descriptions with each variable keeps intent,
default behavior, and validation context discoverable at the exact point where
consumers read or maintain the input schema.

**Alternatives considered**: A single central prose block for many variable
fields was rejected because it creates lookup friction and drift risk. Splitting
descriptions between inline variable blocks and detached narrative summaries was
rejected because it makes ownership unclear and can leave conflicting wording in
multiple places.
