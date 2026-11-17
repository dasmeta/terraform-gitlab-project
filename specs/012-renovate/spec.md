# Feature Specification: Shared Renovate and Repository Opt-in

**Feature Branch**: `DMVP-10881`
**Created**: 2026-11-17
**Status**: Approved scope
**Input**: DMVP-10881 and operator-approved reusable module approach.

## Module Scope and Impact

- **Starting Module Path**: repository root and new `modules/renovate`.
- **Affected Files or Directories**: root wiring/inputs/outputs, new deployment
  and repository-configuration submodules, examples, READMEs, tests, test CI.
- **Current Consumer Interface**: GitLab groups, projects, repository files,
  optional GitLab Agent Helm installation; no Renovate support.
- **Proposed Interface Change**: optional root `renovate` deployment settings,
  per-project `renovate.enabled`, standalone deployment and repository paths.
- **Breaking Change**: No. All new behavior is opt-in.
- **Interface Widening**: Yes. Operator approved standalone Kubernetes deployment,
  root deployment, and repository configuration MRs, then said to start work.
- **Docs, Examples, and Tests Impact**: update together; mocked provider tests
  must exercise both deployment paths, opt-out, configuration, and MR creation.

## User Scenarios and Testing

### User Story 1 - Deploy one shared bot (Priority: P1)

An operator installs a scheduled Renovate worker independently of GitLab project
management, using existing credentials and an explicit repository allowlist.

**Why this priority**: all update proposals need a running worker.
**Independent Test**: inspect the planned Helm values and render the pinned chart.

**Acceptance Scenarios**:
1. Given enabled installation, a namespace, an existing Secret and repositories,
   planning produces one scheduled worker with those references and no tokens.
2. Given disabled installation, no Helm release is created.
3. Given missing credentials or an empty allowlist, enabled installation fails
   with an actionable validation error.

### User Story 2 - Opt projects in through review (Priority: P1)

A maintainer enables Renovate on a managed GitLab project. Terraform proposes
the repository configuration on a dedicated branch and opens an MR. Subsequent
dependency-update MRs belong to Renovate after configuration is merged.

**Why this priority**: repository owners retain the review and CI workflow.
**Independent Test**: mocked plan assertions plus an HTTP-fake test of MR reuse.

**Acceptance Scenarios**:
1. An opted-in project receives `renovate.json` on a dedicated source branch,
   with an MR targeting its configured default branch.
2. Omitted/disabled opt-in and `projects_enabled=false` create no repository
   configuration resources.
3. Configuration disables automatic merging and supports standard chart/image
   detection plus explicit custom extraction for nonstandard YAML sources.
4. Re-running the MR operation reuses an existing open MR; after its configuration
   is merged, the bot processes the repository without a second onboarding MR.

### User Story 3 - Use the root module (Priority: P2)

An operator uses the same root call to enable repository files and optionally
install the shared worker, with repository paths derived from enabled projects.

**Why this priority**: supports the existing account YAML entry point.
**Independent Test**: root mocked-provider tests for config-only and installation.

**Acceptance Scenarios**:
1. Per-project opt-in works without enabling installation.
2. Root installation includes enabled project paths and explicit extra paths.
3. Standalone deployment does not depend on the GitLab provider or project state.

### Edge Cases

- Empty names, identical source/target branches, invalid custom-manager types,
  malformed schedules and missing explicit repository paths fail early.
- No registry credentials are committed to config files or deployment values.
- Existing `renovate.json` is reviewed through the proposed MR; maintainers must
  reconcile other existing Renovate configuration files before adoption.
- Generated deployment trees must be excluded when configuring source YAML.
- Terraform does not merge the configuration MR or update dependencies itself.

## Requirements

- **FR-001**: Wrap the upstream Renovate chart, pin its version, and keep the
  module's interface bounded; use caller-configured Helm provider credentials.
- **FR-002**: Allow deployment and repository configuration independently.
- **FR-003**: Reference an existing Kubernetes Secret for bot and registry access.
- **FR-004**: Keep autodiscovery off, require merged repository configuration,
  disable automerge, and expose a full dry-run mode for controlled rollout.
- **FR-005**: Open configuration MRs without changing existing CI or review rules.
- **FR-006**: Preserve existing root behavior and supported project inputs.
- **FR-007**: Update documentation, examples, executable tests and provider
  compatibility evidence with the implementation.
- **FR-008**: Record local validation separately from actual deployment/run/MR
  evidence; do not claim Jira rollout acceptance without the live evidence.

### Key Entities

- Worker installation: chart release, namespace, Secret reference, schedule,
  repository allowlist and dry-run setting.
- Project opt-in: source/target branches, configuration policy and custom managers.
- Configuration MR: reviewable proposal whose merge activates the worker.

## Success Criteria

- **SC-001**: Both standalone and root usage validate with documented inputs.
- **SC-002**: Disabled defaults add zero Renovate resources.
- **SC-003**: Tests demonstrate opt-in isolation, credential references,
  allowlist derivation, generated valid config and MR reuse/error behavior.
- **SC-004**: Maintainers can follow the runbook to validate config, render the
  chart, run full dry-run, review configuration and dependency-update MRs.
- **SC-005**: Delivery report distinguishes tested module capability from pending
  client release, secret provisioning and rollout acceptance.
