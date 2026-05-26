# Data Model: Dynamic Environments

## Dynamic Environments Project

Represents the optional central GitLab project that owns generated orchestration
files.

Fields:

- `enabled`: boolean feature flag.
- `name`: central project name.
- `description`: optional project description.
- `visibility_level`: project visibility.
- `default_branch`: target branch for generated merge requests.
- `deploy_mode`: kube context selection mode for generated central CI,
  defaulting to `aws_eks`; `gitlab_agent` selects the generated agent context.
- `namespace_id` or `group_key`: namespace selection, matching existing project
  behavior.
- `gitlab_agent`: optional GitLab Agent config generation settings.
- `applications`: applications configuration rendered to
  `config/applications.yaml`.

Validation:

- No central branch, file, or MR resources are created when `enabled` is false.
- Namespace selection follows the same deterministic rules as `gitlab_projects`.
- Generated MR target branch is the central project's default branch.

## Applications Configuration

Represents the YAML payload for `config/applications.yaml`.

Fields:

- `defaults`: object containing stack defaults such as AWS region, secret
  environment, base ref, ref fallbacks, Helm chart, timeout, base domain, and
  dynamic environment release.
- `infra_deployments`: list of infra chart definitions with release, repository
  metadata, chart, version, values, set values, and optional timeout.
- `deployments`: list of application release definitions with project path,
  Helm release, component, version, ref controls, migration flag, and Helm
  overrides.

Validation:

- `defaults.base_ref_fallbacks` defaults to a non-empty list when omitted.
- Infra deployment items require release, chart, and version.
- Application deployment items require project, Helm release, component, and
  Helm version.

## GitLab Agent Configuration

Represents optional generated `.gitlab/agents/<agent-name>/config.yaml`
content. The central dynamic environments project owns this file by default
unless the consumer overrides the target.

Fields:

- `enabled`: boolean feature flag.
- `name`: GitLab Agent name; defaults to the configured cluster name.
- `config_project_name`: optional managed project name that receives the config
  instead of the central dynamic environments project.
- `config_project_id` and `config_project_path`: external target project
  wiring when the config repository is not managed by this module.
- `config_file_path`: generated file path, defaulting to
  `.gitlab/agents/<agent-name>/config.yaml`.
- `source_branch` and `target_branch`: review branch and target branch for the
  generated config MR.
- `ci_access`: projects, groups, or instance-level CI access entries. When
  `ci_access.projects` is set, that input list is rendered directly; when it is
  omitted, the generated config falls back to the central dynamic environments
  project and enabled service projects.
- `user_access`: optional user access config with `access_as_agent` and
  input-driven project entries.
- `register_agent`: optional flag that creates the GitLab cluster agent and
  agent token, disabled by default.
- `install`: optional Helm chart install settings for `gitlab/gitlab-agent`,
  disabled by default.

Validation:

- GitLab Agent config resources are created only when both
  `dynamic_environments_project.enabled` and `gitlab_agent.enabled` are true.
- If no target override is provided, the central dynamic environments project
  ID and path are used.
- If `config_project_id` targets an external project, consumers must also set
  `config_project_path` or an explicit `gitlab_agent_path`.
- The generated config is rendered through
  `modules/gitlab_agent_config/templates/config.yaml.tftpl`.
- Registration/install are opt-in. When enabled, Terraform stores the generated
  sensitive agent token in state so Helm can use it as `config.token`.

## Service Dynamic Environment Configuration

Represents optional per-service repository trigger generation.

Fields:

- `enabled`: boolean feature flag.
- `ci_file_path`: path for the generated reusable CI trigger file, defaulting
  to `ci-pipelines/dynamic-environment.gitlab-ci.yml`.
- `dynamic_env_release`: optional release name used by trigger variables.
- `needs`: optional list of upstream CI jobs for the trigger job.
- `stage` and `cleanup_stage`: optional CI stage names.

Validation:

- No service branch, file, or MR resources are created when `enabled` is false.
- `ci_file_path` must be non-empty when enabled.
- The generated MR target branch is the service project's default branch.

## Build Deploy Pipeline Configuration

Represents optional per-project reusable application pipeline generation for
`ci-pipelines/build.gitlab-ci.yml`.

Fields:

- `tags`: optional runner tags rendered on the hidden `.build` template. Defaults to
  no tags.
- `build_image`: optional `.build` image block with `name` and `entrypoint`.
- `build_services`: optional `.build` service blocks with `name`, `entrypoint`,
  and `command`.
- runtime build behavior is controlled by consumer CI variables such as
  `BUILD_MODE`, `REGISTRY_PROVIDER`, `IMAGE_REPOSITORY`, `IMAGE_TAG`,
  `DOCKERFILE_PATH`, `BUILD_CONTEXT`, optional `BUILD_ARGS`, optional
  `BUILD_PLATFORMS`, and optional hook variables such as `BUILD_PRE_SCRIPT`,
  `BUILD_SETUP_SCRIPT`, and `BUILD_COMMAND`.

Validation:

- When `build_pipeline` is set, only a hidden `.build` template is
  rendered.
- `.build` renders `stage: build`, default `amazon/aws-cli` image with empty
  entrypoint, and default `docker:dind` service with Docker TLS disabled unless
  overridden.
- Concrete jobs, global `stages`, global `variables`, `needs`, `rules`, and
  deploy behavior are not rendered by this generated file.

## Deploy Pipeline Configuration

Represents optional per-project reusable Helm deploy pipeline generation for
`ci-pipelines/deploy.gitlab-ci.yml`.

Fields:

- `tags`: optional runner tags rendered on the hidden `.deploy` template.
- `deploy_image`: optional `.deploy` image block with `name` and `entrypoint`.
- runtime deploy behavior is controlled by consumer CI variables such as
  `KUBE_CONTEXT`, `AWS_EKS_CLUSTER_NAME`, `AWS_REGION`, `KUBE_NAMESPACE`,
  `HELM_RELEASE`, `HELM_CHART`, optional `HELM_CHART_VERSION`,
  `HELM_VALUES_ARGS`, `HELM_SET_ARGS`, `HELM_EXTRA_ARGS`,
  `DEPLOY_IMAGE_REPOSITORY`, `DEPLOY_IMAGE_TAG`,
  `HELM_IMAGE_REPOSITORY_SET_PATH`, and `HELM_IMAGE_TAG_SET_PATH`.

Validation:

- When `deploy_pipeline` is set, only a hidden `.deploy` template is rendered.
- `.deploy` renders `stage: deploy` with a Kubernetes-and-Helm capable image by
  default, while allowing the image block to be overridden.
- Concrete jobs, global `stages`, global `variables`, and consumer-specific
  deploy `rules` are not rendered by this generated file.

## Generated Repository File

Represents a Terraform-managed repository file on
`feature/dynamic-environments`.

Fields:

- `project_id`: GitLab project ID.
- `branch`: `feature/dynamic-environments`.
- `file_path`: generated file path.
- `content`: deterministic rendered content.
- `commit_message`: generated file commit message.

Validation:

- File resources are created only for enabled central or enabled service
  configurations, and for required build or deploy pipeline configurations.

## Generated Merge Request

Represents the review request for generated branch content.

Fields:

- `project_id`: GitLab project ID.
- `source_branch`: `feature/dynamic-environments`.
- `target_branch`: project default branch.
- `title`: default title for central or service MR.
- `description`: generated explanation, including include snippet for service
  repositories.

Validation:

- MR resources are created only when their corresponding generated file
  resources are enabled.
