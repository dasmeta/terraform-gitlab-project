# Research: Dynamic Environments

## Decision: Keep Central Applications Data Under `dynamic_environments_project.applications`

**Rationale**: The generated `config/applications.yaml` belongs to the central
orchestration project, not to individual service repository opt-in. Keeping
`defaults`, `infra_deployments`, and `deployments` under
`dynamic_environments_project.applications` makes the input shape mirror the
generated YAML file and avoids mixing trigger configuration with deployment
inventory.

**Alternatives considered**:

- Generate deployments automatically from
  `gitlab_projects[].dynamic_environment`: rejected because the user needs to
  provide explicit `infra_deployments`, `deployments`, and `defaults`.
- Put `defaults`, `infra_deployments`, and `deployments` directly on
  `dynamic_environments_project`: rejected because those fields specifically
  define the `applications.yaml` contract.

## Decision: Place Service Trigger Opt-In Under `gitlab_projects[].dynamic_environment`

**Rationale**: Service repository trigger generation is per-project behavior.
The existing module already groups per-project settings, branch protections,
approval rules, and CI variables in `gitlab_projects[]`, so this preserves the
current consumer interface pattern.

**Alternatives considered**:

- A separate top-level `dynamic_environment_repositories` list: rejected
  because it would duplicate project identity and make drift between project
  creation and trigger opt-in more likely.

## Decision: Do Not Modify Service Root `.gitlab-ci.yml` By Default

**Rationale**: Many target repositories already exist and may have custom CI
structure. Creating a reusable file plus a merge-request description snippet is
reviewable and avoids risky YAML rewriting.

**Alternatives considered**:

- Automatically patch root `.gitlab-ci.yml`: rejected for the first version due
  to high risk in imported repositories with unknown CI layouts.

## Decision: Manage Generated Branch `feature/dynamic-environments`

**Rationale**: A stable branch name makes re-apply behavior predictable and
lets Terraform update the same managed branch, files, and merge requests.

**Alternatives considered**:

- Timestamped branches: rejected because they would produce repeated MRs and
  make cleanup harder.
- Fail when the branch already exists: rejected because the desired workflow is
  Terraform-managed generation rather than one-time manual creation.

## Decision: Implement In `modules/project`

**Rationale**: Project-scoped repository files, branches, and merge requests
need project IDs. The project submodule already owns GitLab project resources
and returns project IDs, so dynamic environment repository automation belongs
there with root-module normalization feeding it.

**Alternatives considered**:

- Root-only resources referencing `module.project.project_ids`: possible, but
  would split project-owned behavior across root and child module boundaries.

## Decision: Create Merge Requests With a Bounded GitLab API `local-exec`

**Rationale**: Local provider inspection for `gitlabhq/gitlab 18.10.0` showed
`gitlab_branch` and `gitlab_repository_file` resources but no resource capable
of creating merge requests. The provider exposes merge request data sources and
`gitlab_project_merge_request_note`, which cannot create the required MR.
Because DMVP-10007 requires Terraform to create the MR, the implementation will
use a bounded local command that calls the GitLab API after the branch and files
exist.

**Alternatives considered**:

- Provider-native MR resource: rejected because it is not available in the
  installed provider.
- Output MR URLs only: rejected because it does not satisfy the confirmed
  requirement that Terraform creates the MR.
- Direct commits to default branch: rejected because review through MR is a
  core acceptance criterion.
