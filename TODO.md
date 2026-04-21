# GitLab Management Roadmap

This file is the primary actionable backlog for broadening this repository from
project-focused GitLab management toward a more complete GitLab-management
module or successor. The priority order below is intentional and should not be
reordered without explicit re-approval.

## Priority 1: Standardize Service Repository Management

Goal: manage service repositories with Terraform so security, linting,
documentation, and repository content structure are standardized by default.

- Define the baseline GitLab-managed service repository standard.
- Standardize security and policy enforcement across repositories.
- Standardize linting and validation tooling across repositories.
- Standardize documentation scaffolding and repository content structure.
- Consolidate reusable pipeline scripts and template automation for service
  repositories.
- Add repository governance checks such as PR title, branch naming, and
  automated Terraform plan feedback where appropriate.
- Integrate Renovate, `tfsec`, `checkov`, and `tflint` into the standardized
  service-repository flow.
- Refactor the current module or repository structure where needed to support
  the broader GitLab-management direction.

Source coverage:

- `Create terraform module to create projects in gitlab`
- `Create infra repository module which will automatically setup all best practices gitlab`
- `Create application repository which will automatically setup all best practices`
- `Create frontend application repository which will automatically setup all best practices`
- `Pipeline template automation`
- `Create re-usable scripts for gitlab infrastructure pipelines`
- `Create re-usable scripts for gitlab application pipelines`
- `Create re-usable scripts repo for GitLab under Das Meta Gitlab Group`
- `Script to add terraform plan result in PR`
- `Integrate tfsec, checkov & tflint to gitlab pipelines`
- `Integrate renovate-bot with GitLab setup`
- `Check for PR title and description - GitLab`
- `Check for branch name - GitLab`
- `Automatically pull main/master branch into dev branch before merge`
- `Implement general pipelines ability`
- `Review/refactor module`
- `Re-visit module folder/repo structure/organisation`

## Priority 2: Deliver Dynamic Environments and E2E Confidence

Goal: make review apps and dynamic environments part of the default developer
experience, backed by end-to-end and integration test confidence.

- Define the review-app workflow for standardized service repositories.
- Implement ephemeral or dynamic environment support as a first-class flow.
- Wire end-to-end and integration tests into the dynamic environment lifecycle.
- Define release and promotion safeguards so older manual deployments cannot
  overwrite newer validated versions.
- Document release phases and multi-stage delivery expectations.
- Improve the service launching process as part of the same DevEx track.

Source coverage:

- `Prepare ADR for CI/CD pipelines with multi stage environments and lots of types of tests`
- `Research and document service release phases`
- `Implement review apps via code`
- `Implement ephemeral/dynamic environment pipeline`
- `Implement e2e and integration tests in ephemeral/dynamic environment`
- `Improve service lunching process`
- `Prevent old version overwriting new version if deployed manually`

## Priority 3: Expand GitLab Platform Capability and DevEx

Goal: use as much of the GitLab developer platform as possible where it
strengthens standardized service repositories and dynamic environments.

- Define GitLab Kubernetes integration support and repository-driven Kubernetes
  configuration patterns where they fit the GitLab delivery scope.
- Support GitLab runner and agent capability needed for the delivery model,
  including lifecycle management, boot-time optimization, and project-level
  runner enablement controls where useful.
- Implement runner and pipeline monitoring or dashboards as part of the GitLab
  delivery platform.
- Evaluate GitLab Workspaces, GitLab Duo, and similar GitLab-native DevEx
  capabilities where they improve repository usability and delivery quality.
- Define performance testing via pipelines where that work becomes part of the
  reusable GitLab delivery model.

Source coverage:

- `GitLab k8s integration`
- `Implement k8s to gitlab configuration via repo`
- `Research Gitlab Duo`
- `GitLab Workspaces`
- `Enable/Disable Runners for Projects`
- `Create terraform module to setup gitlab runners`
- `Update GitLab runners`
- `Research reducing boot time for gitlab runners`
- `Develop dashboard to monitor gitlab self-hosted runners`
- `Setup monitoring gitlab/github pipelines (CI/CD)`
- `Come up with ways to performance test each service via pipeline`

## Explicitly Out Of Scope

These items may still exist in Jira for visibility, but they are not part of
this implementation epic because they are client-specific or one-off
operational work rather than reusable GitLab delivery capability.

- Client-specific planning.
- One-off GitLab connection issue remediation.

Source coverage:

- `Fix gitlab connection issue`
- `Plan for each client`

## Approval Notes

- Broadening the roadmap from project lifecycle management to wider
  GitLab-related management is approved for roadmap planning.
- Any future implementation that widens the live Terraform module interface or
  renames or repositions the repository still requires explicit follow-up
  approval.
