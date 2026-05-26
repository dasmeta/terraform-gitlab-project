# Feature Specification: Dynamic Environments

**Feature Branch**: `005-dynamic-environments`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "DMVP-10007 GitLab dynamic environments Terraform module support"

## Module Scope and Impact *(mandatory)*

- **Starting Module Path**: repository root
- **Affected Files or Directories**: `variables.tf`, `locals.tf`, `main.tf`,
  `outputs.tf`, `README.md`, `examples/basic/`, generated template content for
  central dynamic-environment repository files, service-repository CI trigger
  files, reusable build-only pipeline files, and tests or validation
  artifacts that prove the behavior
- **Current Consumer Interface**: The root module manages GitLab groups,
  projects, per-project settings, branch protections, approval rules, and
  CI/CD variables through `gitlab_groups`, `gitlab_projects`, and
  `global_env_variables`
- **Proposed Interface Change**: Add an optional
  `dynamic_environments_project` object for central orchestration project
  generation, including `applications` data rendered into
  `config/applications.yaml` and optional GitLab Agent configuration generation
  in an infrastructure repository; add an optional
  `gitlab_projects[].dynamic_environment` object that controls service
  repository trigger-file branch and merge-request generation; add optional
  `gitlab_projects[].build_pipeline` for reusable hidden service build
  template generation and optional `gitlab_projects[].deploy_pipeline` for
  reusable hidden service Helm deploy template generation through
  `modules/gitlab_ci_pipelines`
- **Breaking Change**: No
- **Interface Widening**: Yes, approved by DMVP-10007 refinement; the module
  gains a bounded dynamic environments feature but does not change existing
  project, group, or CI variable behavior when omitted. DMVP-1150 adds
  opt-in per-project `build_pipeline` generation so existing
  consumers can adopt the new file incrementally
- **Docs, Examples, and Tests Impact**: README, examples, generated content
  expectations, validation, and Terraform formatting/validation must be updated
  together with the new inputs and resources

## Assumptions

- The GitLab provider can create or update repository files, branches, and merge
  requests in target projects using project identifiers available to the module.
- Generated branches and generated files named for this feature are managed by
  Terraform; manual edits to those branches are outside the supported workflow.
- Existing service repository root `.gitlab-ci.yml` files are not modified by
  default because imported repositories may have custom CI structures.
- The module keeps dynamic environment orchestration focused on GitLab project
  and repository-file automation, not live Kubernetes or Helm execution.
- GitLab Agent registration and Kubernetes installation are optional and
  disabled by default. If enabled, Terraform creates a GitLab Agent token and
  passes it to Helm, so the sensitive token is stored in Terraform state.

## User Scenarios and Testing *(mandatory)*

### User Story 1 - Generate Central Dynamic Environment Project Files (Priority: P1)

As a module consumer, I want to enable a central dynamic environments project
and provide application stack data so Terraform opens a reviewable merge request
with the orchestration files required to deploy and clean ephemeral stacks.

**Why this priority**: The central orchestration project is the runtime anchor
for all service repository triggers, so service opt-in is not useful until the
central generated files exist.

**Independent Test**: Configure `dynamic_environments_project.enabled = true`
with `applications.defaults`, `applications.infra_deployments`, and
`applications.deployments`, then validate that the generated Terraform plan
contains repository-file and merge-request resources for
`config/applications.yaml`, `scripts/deploy_stack.py`, `scripts/clean_stack.py`,
and `.gitlab-ci.yml` on `feature/dynamic-environments`.

**Acceptance Scenarios**:

1. **Given** the central dynamic environments project is enabled with
   applications data, **When** the consumer plans the module, **Then** the
   generated `config/applications.yaml` content represents the provided
   defaults, infra deployments, and deployments.
2. **Given** the central dynamic environments project is disabled, **When** the
   consumer plans the module, **Then** no central dynamic environment branch,
   repository-file, or merge-request resources are created.

---

### User Story 2 - Opt Service Repositories Into Dynamic Environment Trigger CI (Priority: P2)

As a module consumer, I want to opt individual service repositories into dynamic
environment triggering so only selected repositories receive a reviewable
merge request with a reusable CI trigger file.

**Why this priority**: Service opt-in lets existing repositories adopt the
feature incrementally without touching repositories that are not ready.

**Independent Test**: Configure one `gitlab_projects[]` entry with
`dynamic_environment.enabled = true` and another with the setting omitted or
false, then validate that only the enabled project receives repository-file and
merge-request resources for the service CI trigger.

**Acceptance Scenarios**:

1. **Given** a service project opts in, **When** the consumer plans the module,
   **Then** Terraform creates or updates a managed
   `feature/dynamic-environments` branch, the configured CI trigger file path,
   and a merge request targeting the project's default branch.
2. **Given** a service project does not opt in, **When** the consumer plans the
   module, **Then** Terraform does not create dynamic-environment branch,
   repository-file, or merge-request resources for that service project.

---

### User Story 3 - Preserve Existing CI Files While Guiding Manual Include (Priority: P3)

As an operator importing existing repositories, I want the module to avoid
rewriting root CI files by default while still telling reviewers how to include
the generated reusable trigger file.

**Why this priority**: Existing repositories may have custom `.gitlab-ci.yml`
structure; safe adoption requires a reviewable generated file and clear manual
instructions rather than risky automatic YAML rewriting.

**Independent Test**: Inspect the generated service merge-request description
and confirm it explains the generated file and includes a local include snippet
without creating a root `.gitlab-ci.yml` file update by default.

**Acceptance Scenarios**:

1. **Given** a service project opts in with default settings, **When** the
   module creates the service merge request, **Then** the MR description
   includes `include: - local: ci-pipelines/dynamic-environment.gitlab-ci.yml`.
2. **Given** the service project already has a root `.gitlab-ci.yml`, **When**
   the module plans the feature, **Then** the root CI file is not modified by
   default.

---

### User Story 4 - Generate GitLab Agent Config for Dynamic Project (Priority: P1)

As a platform operator, I want Terraform to generate the GitLab Agent
`config.yaml` in the central dynamic environments project by default, with
input-driven CI and user access lists, so the generated CI can reference an
agent config owned by the same workflow unless a different target is explicitly
configured.

**Why this priority**: The generated CI references a GitLab Agent context; the
workflow is incomplete unless the agent config has a clear owner and
reviewable generated file.

**Independent Test**: Configure `dynamic_environments_project.gitlab_agent`
with `enabled = true`, then
validate that Terraform plans a branch, repository file, and merge request for
`.gitlab/agents/<agent-name>/config.yaml` in the central dynamic environments
project.

**Acceptance Scenarios**:

1. **Given** GitLab Agent config generation is enabled and no target override
   is set, **When** the consumer plans the module, **Then** the generated agent
   config targets the central dynamic environments project.
2. **Given** the consumer sets an alternate config project or path, **When**
   the module renders the agent config, **Then** the generated file and
   `GITLAB_AGENT_PATH` use the configured target.
3. **Given** `deploy_mode = "gitlab_agent"`, **When** central CI is generated,
   **Then** the deploy job selects `kubectl config use-context
   "$GITLAB_AGENT_PATH"` instead of running the AWS EKS kubeconfig command.
4. **Given** `gitlab_agent.ci_access.projects` and
   `gitlab_agent.user_access.projects` are set, **When** the module renders
   config.yaml, **Then** both lists are rendered from input through the
   config.yaml template.

---

### User Story 5 - Generate Reusable Build Pipeline Files (Priority: P1)

As a platform operator, I want managed application repositories to receive a
reviewable reusable build CI pipeline file so service repositories can
consume standard Docker build behavior without hand-written per-repository CI
duplication.

**Why this priority**: Application repositories need a consistent generated CI
entrypoint before the platform can standardize build, deploy, and dynamic
environment metadata across service repositories.

**Independent Test**: Validate that Terraform creates branch, repository-file,
and merge-request resources for `ci-pipelines/build.gitlab-ci.yml` in
each managed project, and that the rendered file contains one hidden `.build`
template.

**Acceptance Scenarios**:

1. **Given** a managed project is managed by the module, **When** the consumer
   validates the module, **Then** Terraform plans a generated reusable build
   pipeline file for that project.
2. **Given** the build-only pipeline file is generated, **When** reviewers
   inspect it, **Then** it contains only one hidden `.build` template.
3. **Given** concrete build jobs are needed, **When** the consumer configures
   CI, **Then** those jobs stay in the root CI file or another
   consumer-owned include and use `extends: .build`.

---

### User Story 6 - Generate Reusable Deploy Pipeline Files (Priority: P1)

As a platform operator, I want managed application repositories to receive a
reviewable reusable deploy CI pipeline file so service repositories can
consume standard Kubernetes Helm deploy behavior without hand-written
per-repository CI duplication.

**Independent Test**: Validate that Terraform creates branch, repository-file,
and merge-request resources for `ci-pipelines/deploy.gitlab-ci.yml` in each
managed project, and that the rendered file contains one hidden `.deploy`
template.

**Acceptance Scenarios**:

1. **Given** a managed project opts into deploy pipeline generation, **When**
   the consumer validates the module, **Then** Terraform plans a generated
   reusable deploy pipeline file for that project.
2. **Given** the deploy pipeline file is generated, **When** reviewers inspect
   it, **Then** it contains only one hidden `.deploy` template.
3. **Given** concrete deploy jobs are needed, **When** the consumer configures
   CI, **Then** those jobs stay in the root CI file or another
   consumer-owned include and use `extends: .deploy`.

---

### Edge Cases

- `dynamic_environments_project.enabled` may be false while service projects
  opt in; validation or documentation must make the resulting unsupported
  trigger target clear.
- Service CI file path may be omitted; the module must default it to
  `ci-pipelines/dynamic-environment.gitlab-ci.yml`.
- Service CI file path may be customized per project and must render into the
  correct repository file resource and MR description snippet.
- Applications data may include nested maps and lists for Helm values and
  overrides; rendering must preserve the consumer-provided structure in YAML.
- GitLab Agent config may need to live in an external project; when an external
  project ID is used, consumers must provide either the agent config project
  path or an explicit `gitlab_agent_path` so generated CI can reference the
  agent context.
- Re-applying the module should update Terraform-managed
  `feature/dynamic-environments` branches and generated files rather than
  requiring manual cleanup.
- `build_pipeline` must not render concrete jobs such as `build`.
- `deploy_pipeline` must not render concrete jobs such as `deploy`.
- Root `.gitlab-ci.yml` and `.gitlab-ci.yaml` files must not be modified by
  reusable build or deploy pipeline generation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST expose a top-level
  `dynamic_environments_project` input with an `enabled` flag.
- **FR-002**: The module MUST expose
  `dynamic_environments_project.applications.defaults`,
  `dynamic_environments_project.applications.infra_deployments`, and
  `dynamic_environments_project.applications.deployments` for generating
  `config/applications.yaml`.
- **FR-003**: When `dynamic_environments_project.enabled` is false or omitted,
  the module MUST NOT create central dynamic-environment branch, file, or merge
  request resources.
- **FR-004**: When the central feature is enabled, Terraform MUST create or
  manage repository files for `config/applications.yaml`,
  `scripts/deploy_stack.py`, `scripts/clean_stack.py`, and `.gitlab-ci.yml` on
  source branch `feature/dynamic-environments`.
- **FR-005**: The central merge request MUST target the central project's
  default branch and default its title to
  `Add dynamic environments orchestration`.
- **FR-006**: Each `gitlab_projects[]` entry MUST support an optional
  `dynamic_environment` object with an `enabled` flag.
- **FR-007**: When `gitlab_projects[].dynamic_environment.enabled` is false or
  omitted, the module MUST NOT create dynamic-environment branch, file, or
  merge request resources for that service project.
- **FR-008**: When a service project opts in, Terraform MUST create or manage a
  reusable CI trigger file on source branch `feature/dynamic-environments`.
- **FR-009**: The service CI trigger file path MUST default to
  `ci-pipelines/dynamic-environment.gitlab-ci.yml` and MUST be configurable per
  project.
- **FR-010**: Service merge requests MUST target each service project's default
  branch and default their title to `Add dynamic environment CI trigger`.
- **FR-011**: Service merge-request descriptions MUST explain the generated file
  and include a manual root `.gitlab-ci.yml` include snippet.
- **FR-012**: The module MUST NOT modify service repository root
  `.gitlab-ci.yml` files by default.
- **FR-013**: The new inputs MUST preserve existing module behavior for
  consumers that do not configure dynamic environments.
- **FR-014**: README and examples MUST document central project enablement,
  applications YAML generation, service opt-in, default file paths, branch/MR
  behavior, and the manual include workflow.
- **FR-015**: Verification MUST include Terraform formatting and validation, and
  must cover enabled and disabled dynamic environment behavior.
- **FR-016**: The module MUST support optional
  `dynamic_environments_project.gitlab_agent` configuration that generates
  `.gitlab/agents/<agent-name>/config.yaml` in the central dynamic environments
  project by default.
- **FR-017**: When GitLab Agent config generation is enabled and no target
  override is provided, the module MUST default the config target to the
  central dynamic environments project.
- **FR-018**: GitLab Agent config target project, target path, agent name,
  source branch, target branch, CI access projects/groups, and user access
  projects MUST be configurable.
- **FR-019**: Generated central and service CI MUST reference the effective
  GitLab Agent path, and `deploy_mode = "gitlab_agent"` MUST select the GitLab
  Agent kube context in central deploy jobs.
- **FR-020**: The module MUST keep GitLab Agent registration and Helm
  installation disabled by default.
- **FR-021**: When `gitlab_agent.register_agent = true`, the module MUST create
  the GitLab cluster agent and agent token in the configured agent config
  project.
- **FR-022**: When `gitlab_agent.install.enabled = true`, the module MUST deploy
  the `gitlab/gitlab-agent` Helm chart to the configured Kubernetes cluster
  using the generated token and configured KAS address.
- **FR-023**: Documentation MUST state that enabling registration/install stores
  the sensitive generated agent token in Terraform state.
- **FR-024**: Terraform MUST generate
  `ci-pipelines/build.gitlab-ci.yml` for every managed project through a
  dedicated reusable CI pipeline submodule.
- **FR-025**: The generated build pipeline file MUST include one hidden
  `.build` job, and reusable deploy behavior MUST live in a separate generated
  deploy pipeline file rather than inside `ci-pipelines/build.gitlab-ci.yml`.
- **FR-026**: The generated build pipeline file MUST NOT render global
  `stages` or global `variables`; those remain consumer-managed.
- **FR-027**: The generated build pipeline file MUST be rendered through a
  template file inside `modules/gitlab_ci_pipelines`.
- **FR-028**: The hidden `.build` template MUST render `stage: build`,
  `amazon/aws-cli` with empty entrypoint, and `docker:dind` with Docker TLS
  disabled by default, while allowing the image and service blocks to be
  overridden.
- **FR-029**: The hidden `.build` template MUST render `tags` only when
  `build_pipeline.tags` is non-empty.
- **FR-030**: Concrete service jobs MUST consume the generated hidden template
  through `extends: .build` and configure build behavior through CI variables
  rather than by replacing the generated script.
- **FR-031**: The hidden `.build` template MUST support `BUILD_MODE=docker`
  and `BUILD_MODE=buildx`.
- **FR-032**: The hidden `.build` template MUST support
  `REGISTRY_PROVIDER=ecr|dockerhub`.
- **FR-033**: The hidden `.build` template MUST push images to
  `${IMAGE_REPOSITORY}:${IMAGE_TAG}` and require `IMAGE_REPOSITORY`,
  `IMAGE_TAG`, `DOCKERFILE_PATH`, and `BUILD_CONTEXT`.
- **FR-034**: The hidden `.build` template MUST support optional `BUILD_ARGS`
  as a plain string and optional `BUILD_PLATFORMS` for `buildx`.
- **FR-035**: The generated build pipeline file MUST NOT render concrete
  jobs such as `build` or any `extends` consumers, and it MUST keep job-level
  `needs`, `variables`, `rules`, hooks, and deploy behavior consumer-managed.
- **FR-036**: The generated build pipeline MR description MUST tell the
  operator to manually include `ci-pipelines/build.gitlab-ci.yml` from
  root `.gitlab-ci.yml` or `.gitlab-ci.yaml`.
- **FR-037**: Terraform MUST generate
  `ci-pipelines/deploy.gitlab-ci.yml` for every managed project that opts into
  reusable deploy pipelines through the reusable CI pipeline submodule.
- **FR-038**: The generated deploy pipeline file MUST include one hidden
  `.deploy` job.
- **FR-039**: The hidden `.deploy` template MUST render `stage: deploy` and a
  Kubernetes-and-Helm capable image by default, while allowing the image block
  to be overridden.
- **FR-040**: Concrete service jobs MUST consume the generated hidden deploy
  template through `extends: .deploy` and configure deploy behavior through CI
  variables.
- **FR-041**: The hidden `.deploy` template MUST support Kubernetes context
  selection through `KUBE_CONTEXT` and optional AWS EKS kubeconfig generation
  through `AWS_EKS_CLUSTER_NAME` plus `AWS_REGION`.
- **FR-042**: The hidden `.deploy` template MUST support Helm deployment
  inputs for `KUBE_NAMESPACE`, `HELM_RELEASE`, `HELM_CHART`,
  optional `HELM_CHART_VERSION`, optional `HELM_VALUES_ARGS`,
  optional `HELM_SET_ARGS`, and optional `HELM_EXTRA_ARGS`.
- **FR-043**: The hidden `.deploy` template MUST support optional image tag
  propagation through `DEPLOY_IMAGE_REPOSITORY`, `DEPLOY_IMAGE_TAG`,
  `HELM_IMAGE_REPOSITORY_SET_PATH`, and `HELM_IMAGE_TAG_SET_PATH`.
- **FR-044**: The generated deploy pipeline MR description MUST tell the
  operator to manually include `ci-pipelines/deploy.gitlab-ci.yml` from
  root `.gitlab-ci.yml` or `.gitlab-ci.yaml`.

### Key Entities *(include if feature involves data or object schemas)*

- **Dynamic Environments Project**: Top-level optional configuration that
  controls central project generation, generated orchestration files, source
  branch, and central merge request behavior.
- **Applications Configuration**: Consumer-provided data under
  `dynamic_environments_project.applications` rendered to
  `config/applications.yaml`, including defaults, infra deployments, and service
  deployments.
- **Service Dynamic Environment Configuration**: Per-project optional object
  that controls service repository trigger-file path and service merge-request
  generation.
- **Generated Repository File**: Terraform-managed GitLab repository file
  created or updated on `feature/dynamic-environments`.
- **Generated Merge Request**: Terraform-managed GitLab merge request from
  `feature/dynamic-environments` to the target project's default branch.
- **GitLab Agent Configuration**: Terraform-generated
  `.gitlab/agents/<agent-name>/config.yaml` stored in the central dynamic
  environments project by default, containing input-driven CI access and user
  access authorization.
- **Build Deploy Pipeline**: Optional per-project reusable CI pipeline
  configuration that renders a hidden `.build` template into
  `ci-pipelines/build.gitlab-ci.yml`.
- **Deploy Pipeline**: Optional per-project reusable CI pipeline
  configuration that renders a hidden `.deploy` template into
  `ci-pipelines/deploy.gitlab-ci.yml`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A consumer can identify the exact inputs needed to create the
  central dynamic environments project and applications YAML within 10 minutes
  using README and examples.
- **SC-002**: A consumer can opt in one service repository without producing any
  dynamic-environment resources for another disabled service repository in the
  same module configuration.
- **SC-003**: Terraform validation succeeds for the documented example covering
  central enablement and one service opt-in.
- **SC-004**: Existing configurations that omit `dynamic_environments_project`
  and `gitlab_projects[].dynamic_environment` retain their current plan shape
  for group, project, and CI variable resources.
- **SC-005**: Reviewers can see all generated repository-file changes through
  GitLab merge requests rather than direct commits to default branches.
