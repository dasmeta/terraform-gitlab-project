# Implementation Plan: Dynamic Environments

**Branch**: `005-dynamic-environments` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-dynamic-environments/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. Replace all
placeholders with repository-specific details before implementation starts.

## Summary

Add an optional dynamic environments feature to the existing GitLab project
Terraform module. The root module will expose a central
`dynamic_environments_project` object that creates/manages a GitLab project and
opens a merge request with generated orchestration files, including
`config/applications.yaml` rendered from consumer input. Each
`gitlab_projects[]` entry can independently opt into a service-repository merge
request containing a reusable dynamic environment CI trigger file. Verification
will rely on Terraform formatting, Terraform validation, and example-based plan
checks for enabled and disabled behavior.

DMVP-10061 extends the same package with optional GitLab Agent config
generation through a dedicated `modules/gitlab_agent_config` submodule. When
enabled, Terraform writes `.gitlab/agents/<agent-name>/config.yaml` to an
central dynamic environments project by default, while allowing the target
project/path, CI access entries, and user access entries to be overridden. The
dynamic environment submodule consumes only the effective `GITLAB_AGENT_PATH`;
generated CI can keep the AWS EKS kubeconfig flow or switch to the GitLab Agent kube context with
`deploy_mode = "gitlab_agent"`.

## Technical Context

**Terraform Runtime**: Terraform `>= 1.3`  
**Primary Provider Constraints**: `gitlabhq/gitlab >= 18.8.2`  
**Module Scope**: root module, `modules/project`, README, examples, and validation artifacts  
**Testing Strategy**: `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, example validation, and plan-shape review where provider credentials are unavailable  
**Target Platform**: GitLab API via Terraform provider  
**Project Type**: Terraform module repository  
**Constraints**: preserve existing group/project/CI variable behavior when dynamic environments are omitted; no direct default-branch commits; service root `.gitlab-ci.yml` is not modified by default; generated branches/files are Terraform-managed; GitLab Agent registration and Helm install are disabled by default; when enabled, the generated agent token is sensitive but necessarily stored in Terraform state; GitLab provider lacks a merge-request creation resource, so MR creation is approved through a bounded `local-exec` GitLab API call  
**Scale/Scope**: root variables and normalization, project submodule resources, generated template locals, outputs, README, `examples/basic/`, and this feature's Speckit artifacts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Scope check: PASS. The change stays inside GitLab project lifecycle and
  repository-file/MR automation for managed projects.
- Wrapper check: PASS. The interface is grouped into a central orchestration
  object and a per-service opt-in object instead of exposing raw provider
  resources.
- Approval check: PASS WITH RECORDED INTERFACE WIDENING. DMVP-10007 refinement
  explicitly approves adding the bounded dynamic environments interface. No
  breaking change is approved or planned.
- File coverage check: update `variables.tf`, `locals.tf`, `main.tf`,
  `outputs.tf`, `modules/project/main.tf`, `modules/project/locals.tf`,
  `modules/project/outputs.tf`, `modules/dynamic_environment/*`, `README.md`,
  `examples/basic/main.tf`, and generated documentation as needed.
- Provider/version check: `gitlabhq/gitlab >= 18.8.2` supports project,
  branch, and repository file resources. Local provider inspection showed no
  merge-request creation resource, only merge-request data sources and notes.
  MR creation will use `local-exec` against the GitLab API with an operator
  token.
- Verification check: run `terraform fmt -check -recursive`, `terraform init
  -backend=false`, `terraform validate`, and example validation/plan checks
  where credentials allow.

## Project Structure

### Documentation (this feature)

```text
specs/005-dynamic-environments/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output when needed
├── quickstart.md        # Phase 1 output when needed
├── contracts/           # Phase 1 output when needed
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
.
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── modules/project/
│   ├── locals.tf
│   ├── main.tf
│   └── outputs.tf
├── README.md
├── examples/
└── tests/
```

**Structure Decision**: Keep GitLab project creation and project-scoped dynamic
environment resources in `modules/project` because service repository files,
branches, and merge requests are scoped to project IDs created there. Keep
consumer input definitions, normalization, and high-level outputs at the root.
Represent generated file content with Terraform locals so repository-file
resources can consume deterministic strings.

## Complexity Tracking

> **Fill only if the Constitution Check reveals a justified exception**

| Exception | Why Needed | Approval or Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------------------|
| Interface widening | Adds central dynamic environment orchestration and per-service trigger opt-in inputs | Approved during DMVP-10007 refinement; a narrower documentation-only change would not create the requested GitLab MR automation |
| Interface widening | Adds optional GitLab Agent config generation, registration, and Helm install under the dynamic environments object | Approved during DMVP-10061 follow-up; registration/install are disabled by default and documented as storing the sensitive generated token in Terraform state |
| Imperative MR creation | GitLab provider does not expose a merge-request creation resource | Approved after provider inspection; `local-exec` GitLab API call keeps branch/file resources declarative while satisfying MR creation requirement |
