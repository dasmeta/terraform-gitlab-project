locals {
  default_stop_environment_rules = [
    {
      if            = null
      when          = "manual"
      allow_failure = true
      changes       = null
      exists        = null
      start_in      = null
    }
  ]
  empty_ci_rule_lines = tolist(slice([""], 0, 0))

  pipeline_types = {
    build_ecr = {
      file_path      = "ci-pipelines/build-gitlab.ci.yaml"
      job_name       = "build"
      extends        = ".build-ecr"
      commit_message = "Add reusable build_ecr GitLab CI pipeline"

      include = {
        project = "das-meta/gitlab-ci-templates"
        ref     = "1.1.0"
        file    = "/ci-templates/templates/build/ecr-build.gitlab-ci.yml"
      }

      default_variables = {
        IMAGE_TAGS      = "$CI_COMMIT_SHORT_SHA"
        DOCKERFILE_PATH = "Dockerfile"
        BUILD_CONTEXT   = "."
      }

      variable_order = [
        "AWS_REGION",
        "IMAGE_REPOSITORY",
        "IMAGE_TAGS",
        "DOCKERFILE_PATH",
        "BUILD_CONTEXT",
        "BUILD_ARGS",
        "BUILDX_CREATE_ARGS",
      ]

      variable_keys = {
        aws_region         = "AWS_REGION"
        image_repository   = "IMAGE_REPOSITORY"
        image_tags         = "IMAGE_TAGS"
        dockerfile_path    = "DOCKERFILE_PATH"
        build_context      = "BUILD_CONTEXT"
        build_args         = "BUILD_ARGS"
        buildx_create_args = "BUILDX_CREATE_ARGS"
      }
    }

    build_onprem = {
      file_path      = "ci-pipelines/build-gitlab.ci.yaml"
      job_name       = "build"
      extends        = ".build-onprem"
      commit_message = "Add reusable on-premises registry build pipeline"

      include = {
        project = "das-meta/gitlab-ci-templates"
        ref     = "1.1.0"
        file    = "/ci-templates/templates/build/onprem-build.gitlab-ci.yml"
      }

      default_variables = {
        IMAGE_TAGS      = "$CI_COMMIT_SHORT_SHA"
        DOCKERFILE_PATH = "Dockerfile"
        BUILD_CONTEXT   = "."
      }

      variable_order = [
        "REGISTRY_HOST",
        "IMAGE_REPOSITORY",
        "IMAGE_TAGS",
        "DOCKERFILE_PATH",
        "BUILD_CONTEXT",
        "BUILD_ARGS",
        "BUILDX_CREATE_ARGS",
      ]

      variable_keys = {
        registry_host      = "REGISTRY_HOST"
        image_repository   = "IMAGE_REPOSITORY"
        image_tags         = "IMAGE_TAGS"
        dockerfile_path    = "DOCKERFILE_PATH"
        build_context      = "BUILD_CONTEXT"
        build_args         = "BUILD_ARGS"
        buildx_create_args = "BUILDX_CREATE_ARGS"
      }
    }

    deploy_agent = {
      file_path      = "ci-pipelines/deploy.gitlab-ci.yml"
      job_name       = "deploy"
      extends        = ".deploy-agent"
      commit_message = "Add reusable deploy_agent GitLab CI pipeline"

      include = {
        project = "das-meta/gitlab-ci-templates"
        ref     = "1.1.0"
        file    = "/ci-templates/templates/deploy/agent-deploy.gitlab-ci.yml"
      }

      default_variables = {
        KUBE_NAMESPACE_CREATE = "true"
        HELM_WAIT             = "true"
        HELM_TIMEOUT          = "40m"
      }

      variable_order = [
        "DEPLOY_ENVIRONMENT_NAME",
        "DEPLOY_ENVIRONMENT_KUBERNETES_AGENT",
        "DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE",
        "KUBE_NAMESPACE",
        "KUBE_NAMESPACE_CREATE",
        "HELM_RELEASE",
        "HELM_CHART",
        "HELM_CHART_VERSION",
        "HELM_REPOSITORY_NAME",
        "HELM_REPOSITORY_URL",
        "HELM_VALUES_ARGS",
        "HELM_SET_ARGS",
        "HELM_EXTRA_ARGS",
        "DEPLOY_IMAGE_REPOSITORY",
        "HELM_IMAGE_REPOSITORY_SET_PATH",
        "DEPLOY_IMAGE_TAG",
        "HELM_IMAGE_TAG_SET_PATH",
        "HELM_WAIT",
        "HELM_TIMEOUT",
      ]

      variable_keys = {
        deploy_environment_name                = "DEPLOY_ENVIRONMENT_NAME"
        deploy_environment_kubernetes_agent    = "DEPLOY_ENVIRONMENT_KUBERNETES_AGENT"
        deploy_environment_dashboard_namespace = "DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE"
        kube_namespace                         = "KUBE_NAMESPACE"
        kube_namespace_create                  = "KUBE_NAMESPACE_CREATE"
        helm_release                           = "HELM_RELEASE"
        helm_chart                             = "HELM_CHART"
        helm_chart_version                     = "HELM_CHART_VERSION"
        helm_repository_name                   = "HELM_REPOSITORY_NAME"
        helm_repository_url                    = "HELM_REPOSITORY_URL"
        helm_values_args                       = "HELM_VALUES_ARGS"
        helm_set_args                          = "HELM_SET_ARGS"
        helm_extra_args                        = "HELM_EXTRA_ARGS"
        deploy_image_repository                = "DEPLOY_IMAGE_REPOSITORY"
        helm_image_repository_set_path         = "HELM_IMAGE_REPOSITORY_SET_PATH"
        deploy_image_tag                       = "DEPLOY_IMAGE_TAG"
        helm_image_tag_set_path                = "HELM_IMAGE_TAG_SET_PATH"
        helm_wait                              = "HELM_WAIT"
        helm_timeout                           = "HELM_TIMEOUT"
      }
    }
  }

  normalized_ci_pipelines = flatten([
    for p in var.gitlab_projects : [
      for pipeline in try(p.gitlab_ci_pipelines, []) : {
        key            = "${p.name}:${pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type}"
        project_name   = p.name
        type           = pipeline.type
        config         = local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type]
        variables      = try(pipeline.variables, {})
        target_branch  = coalesce(try(p.default_branch, null), "main")
        source_branch  = "terraform/ci-pipelines/${replace(pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type, "_", "-")}"
        create_mr      = coalesce(try(pipeline.create_merge_request, null), true)
        commit_message = coalesce(try(pipeline.commit_message, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].commit_message)
        mr_title       = coalesce(try(pipeline.merge_request_title, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].commit_message)
        remove_branch  = coalesce(try(pipeline.remove_source_branch, null), true)
        file_path      = coalesce(try(pipeline.file_path, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].file_path)
        jobs = length(try(pipeline.jobs, [])) > 0 ? [
          for job in pipeline.jobs : {
            name    = job.name
            extends = local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].extends
            rules = try(length(job.rules), 0) > 0 ? tolist(flatten([
              for rule in job.rules : concat(
                try(rule.if, null) == null ? [] : ["    - if: '${replace(rule.if, "'", "''")}'"],
                try(rule.if, null) != null || try(rule.when, null) == null ? [] : ["    - when: ${jsonencode(rule.when)}"],
                try(rule.if, null) == null || try(rule.when, null) == null ? [] : ["      when: ${jsonencode(rule.when)}"],
                try(rule.allow_failure, null) == null ? [] : [
                  try(rule.if, null) != null || try(rule.when, null) != null
                  ? "      allow_failure: ${jsonencode(rule.allow_failure)}"
                  : "    - allow_failure: ${jsonencode(rule.allow_failure)}"
                ],
                length(coalesce(try(rule.changes, null), [])) == 0 ? [] : concat(
                  [
                    try(rule.if, null) != null || try(rule.when, null) != null || try(rule.allow_failure, null) != null
                    ? "      changes:"
                    : "    - changes:"
                  ],
                  [for path in coalesce(try(rule.changes, null), []) : "        - ${jsonencode(path)}"]
                ),
                length(coalesce(try(rule.exists, null), [])) == 0 ? [] : concat(
                  [
                    try(rule.if, null) != null || try(rule.when, null) != null || try(rule.allow_failure, null) != null || length(coalesce(try(rule.changes, null), [])) > 0
                    ? "      exists:"
                    : "    - exists:"
                  ],
                  [for path in coalesce(try(rule.exists, null), []) : "        - ${jsonencode(path)}"]
                ),
                try(rule.start_in, null) == null ? [] : [
                  try(rule.if, null) != null || try(rule.when, null) != null || try(rule.allow_failure, null) != null || length(coalesce(try(rule.changes, null), [])) > 0 || length(coalesce(try(rule.exists, null), [])) > 0
                  ? "      start_in: ${jsonencode(rule.start_in)}"
                  : "    - start_in: ${jsonencode(rule.start_in)}"
                ]
              )
            ])) : local.empty_ci_rule_lines
            stop_environment = {
              enabled = pipeline.type == "deploy_agent" ? coalesce(
                try(job.stop_environment.enabled, null),
                try(pipeline.stop_environment.enabled, null),
                false
              ) : false
              job_name = coalesce(
                try(job.stop_environment.job_name, null),
                try(pipeline.stop_environment.job_name, null),
                "stop-${job.name}"
              )
              extends = coalesce(
                try(job.stop_environment.extends, null),
                try(pipeline.stop_environment.extends, null),
                ".stop-deploy-agent"
              )
              auto_stop_in = coalesce(
                try(job.stop_environment.auto_stop_in, null),
                try(pipeline.stop_environment.auto_stop_in, null),
                "1 hour"
              )
              rules = try(length(job.stop_environment.rules), 0) > 0 ? tolist(flatten([
                for rule in job.stop_environment.rules : concat(
                  try(rule.if, null) == null ? [] : ["    - if: '${replace(rule.if, "'", "''")}'"],
                  try(rule.if, null) != null || try(rule.when, null) == null ? [] : ["    - when: ${jsonencode(rule.when)}"],
                  try(rule.if, null) == null || try(rule.when, null) == null ? [] : ["      when: ${jsonencode(rule.when)}"],
                  try(rule.allow_failure, null) == null ? [] : [
                    try(rule.if, null) != null || try(rule.when, null) != null
                    ? "      allow_failure: ${jsonencode(rule.allow_failure)}"
                    : "    - allow_failure: ${jsonencode(rule.allow_failure)}"
                  ]
                )
                ])) : try(length(pipeline.stop_environment.rules), 0) > 0 ? tolist(flatten([
                for rule in pipeline.stop_environment.rules : concat(
                  try(rule.if, null) == null ? [] : ["    - if: '${replace(rule.if, "'", "''")}'"],
                  try(rule.if, null) != null || try(rule.when, null) == null ? [] : ["    - when: ${jsonencode(rule.when)}"],
                  try(rule.if, null) == null || try(rule.when, null) == null ? [] : ["      when: ${jsonencode(rule.when)}"],
                  try(rule.allow_failure, null) == null ? [] : [
                    try(rule.if, null) != null || try(rule.when, null) != null
                    ? "      allow_failure: ${jsonencode(rule.allow_failure)}"
                    : "    - allow_failure: ${jsonencode(rule.allow_failure)}"
                  ]
                )
                ])) : length(coalesce(try(job.rules, null), [])) > 0 ? tolist(flatten([
                for rule in job.rules : concat(
                  try(rule.if, null) == null ? [] : ["    - if: '${replace(rule.if, "'", "''")}'"],
                  ["      when: \"manual\"", "      allow_failure: true"]
                )
              ])) : tolist(["    - when: \"manual\"", "      allow_failure: true"])
            }
            variables = tomap(merge(
              local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].default_variables,
              {
                for source_key, target_key in local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].variable_keys :
                target_key => source_key == "image_tags" ? join(
                  "\n",
                  tolist(try(job.variables, {})[source_key])
                ) : tostring(try(job.variables, {})[source_key])
                if try(try(job.variables, {})[source_key], null) != null
              }
            ))
          }
          ] : [
          {
            name    = coalesce(try(pipeline.job_name, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].job_name)
            extends = local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].extends
            rules   = local.empty_ci_rule_lines
            stop_environment = {
              enabled = pipeline.type == "deploy_agent" ? coalesce(try(pipeline.stop_environment.enabled, null), false) : false
              job_name = coalesce(
                try(pipeline.stop_environment.job_name, null),
                "stop-${coalesce(try(pipeline.job_name, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].job_name)}"
              )
              extends      = coalesce(try(pipeline.stop_environment.extends, null), ".stop-deploy-agent")
              auto_stop_in = coalesce(try(pipeline.stop_environment.auto_stop_in, null), "1 hour")
              rules = try(length(pipeline.stop_environment.rules), 0) > 0 ? tolist(flatten([
                for rule in pipeline.stop_environment.rules : concat(
                  try(rule.if, null) == null ? [] : ["    - if: '${replace(rule.if, "'", "''")}'"],
                  try(rule.if, null) != null || try(rule.when, null) == null ? [] : ["    - when: ${jsonencode(rule.when)}"],
                  try(rule.if, null) == null || try(rule.when, null) == null ? [] : ["      when: ${jsonencode(rule.when)}"],
                  try(rule.allow_failure, null) == null ? [] : [
                    try(rule.if, null) != null || try(rule.when, null) != null
                    ? "      allow_failure: ${jsonencode(rule.allow_failure)}"
                    : "    - allow_failure: ${jsonencode(rule.allow_failure)}"
                  ]
                )
              ])) : tolist(["    - when: \"manual\"", "      allow_failure: true"])
            }
            variables = tomap(merge(
              local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].default_variables,
              {
                for source_key, target_key in local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].variable_keys :
                target_key => source_key == "image_tags" ? join(
                  "\n",
                  tolist(try(pipeline.variables, {})[source_key])
                ) : tostring(try(pipeline.variables, {})[source_key])
                if try(try(pipeline.variables, {})[source_key], null) != null
              }
            ))
          }
        ]
        template = {
          project = coalesce(try(pipeline.template_project, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].include.project)
          ref     = coalesce(try(pipeline.template_ref, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].include.ref)
          file    = coalesce(try(pipeline.template_file, null), local.pipeline_types[pipeline.type == "build" ? "build_${pipeline.target}" : pipeline.type].include.file)
        }
      }
    ]
  ])

  ci_pipeline_files = {
    for pipeline in local.normalized_ci_pipelines : pipeline.key => {
      project_name   = pipeline.project_name
      target_branch  = pipeline.target_branch
      source_branch  = pipeline.create_mr ? pipeline.source_branch : pipeline.target_branch
      create_mr      = pipeline.create_mr
      commit_message = pipeline.commit_message
      mr_title       = pipeline.mr_title
      mr_description = <<-EOT
        This merge request adds a reusable ${pipeline.type} pipeline wrapper generated by Terraform.

        It creates `${pipeline.file_path}`. That file includes the shared GitLab CI template from `${pipeline.template.project}` and defines these generated jobs: ${join(", ", [for job in pipeline.jobs : "`${job.name}`"])}.

        To use it, keep your root `.gitlab-ci.yml` or `.gitlab-ci.yaml` manually owned and add this include:

        ```yaml
        include:
          - local: ${pipeline.file_path}
        ```

        After that, GitLab will load the generated wrapper pipeline and run the generated jobs.
      EOT
      remove_branch  = pipeline.remove_branch
      file_path      = pipeline.file_path
      content = join("\n", concat(
        [
          "# GENERATED FILE - DO NOT EDIT",
          "# Managed by Terraform. Manual changes may be overwritten.",
          "# Update the source Terraform configuration instead.",
          "",
          "include:",
          "  - project: ${pipeline.template.project}",
          "    ref: ${pipeline.template.ref}",
          "    file: ${pipeline.template.file}",
          "",
        ],
        flatten([
          for job in pipeline.jobs : concat(
            [
              "${job.name}:",
              "  extends: ${job.extends}",
              "  variables:",
            ],
            [
              for variable_name in pipeline.config.variable_order :
              "    ${variable_name}: ${jsonencode(job.variables[variable_name])}"
              if contains(keys(job.variables), variable_name)
            ],
            job.stop_environment.enabled ? concat(
              [
                "  environment:",
                "    name: ${jsonencode(job.variables["DEPLOY_ENVIRONMENT_NAME"])}",
              ],
              contains(keys(job.variables), "DEPLOY_ENVIRONMENT_KUBERNETES_AGENT") || contains(keys(job.variables), "DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE") ? concat(
                ["    kubernetes:"],
                contains(keys(job.variables), "DEPLOY_ENVIRONMENT_KUBERNETES_AGENT") ? [
                  "      agent: ${jsonencode(job.variables["DEPLOY_ENVIRONMENT_KUBERNETES_AGENT"])}"
                ] : [],
                contains(keys(job.variables), "DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE") ? [
                  "      dashboard:",
                  "        namespace: ${jsonencode(job.variables["DEPLOY_ENVIRONMENT_DASHBOARD_NAMESPACE"])}"
                ] : []
              ) : [],
              [
                "    on_stop: ${job.stop_environment.job_name}",
                "    auto_stop_in: ${jsonencode(job.stop_environment.auto_stop_in)}",
              ]
            ) : [],
            length(job.rules) == 0 ? [] : concat(["  rules:"], job.rules),
            [""]
          )
        ]),
        flatten([
          for job in pipeline.jobs : job.stop_environment.enabled ? concat(
            [
              "${job.stop_environment.job_name}:",
              "  extends: ${job.stop_environment.extends}",
              "  variables:",
            ],
            [
              for variable_name in pipeline.config.variable_order :
              "    ${variable_name}: ${jsonencode(job.variables[variable_name])}"
              if contains(keys(job.variables), variable_name)
            ],
            [
              "  environment:",
              "    name: ${jsonencode(job.variables["DEPLOY_ENVIRONMENT_NAME"])}",
              "    action: stop",
            ],
            length(job.stop_environment.rules) == 0 ? [] : concat(["  rules:"], job.stop_environment.rules),
            [""]
          ) : []
        ]),
        [""]
      ))
    }
  }

  gitlab_merge_request_command = <<-SH
    python3 <<'PY'
    import json
    import os
    import sys
    import urllib.error
    import urllib.parse
    import urllib.request

    token = os.environ.get("GITLAB_API_TOKEN") or os.environ.get("GITLAB_TOKEN")
    if not token:
        print("ERROR: set GITLAB_API_TOKEN or GITLAB_TOKEN so Terraform can create the GitLab merge request", file=sys.stderr)
        sys.exit(1)

    api_url = os.environ["GITLAB_API_URL"].rstrip("/")
    project = urllib.parse.quote(os.environ["GITLAB_PROJECT"], safe="")
    source_branch = os.environ["GITLAB_SOURCE_BRANCH"]
    target_branch = os.environ["GITLAB_TARGET_BRANCH"]
    title = os.environ["GITLAB_MR_TITLE"]
    description = os.environ["GITLAB_MR_DESCRIPTION"]
    remove_source_branch = os.environ.get("GITLAB_REMOVE_SOURCE_BRANCH", "true").lower() == "true"
    headers = {"PRIVATE-TOKEN": token, "Content-Type": "application/json"}

    def request(method, path, payload=None):
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(api_url + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                body = response.read().decode("utf-8")
                return json.loads(body) if body else None
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            print(f"ERROR: GitLab API {method} {path} failed: {exc.code} {body}", file=sys.stderr)
            sys.exit(1)

    query = urllib.parse.urlencode({
        "state": "opened",
        "source_branch": source_branch,
        "target_branch": target_branch,
    })
    existing = request("GET", f"/projects/{project}/merge_requests?{query}") or []
    payload = {
        "source_branch": source_branch,
        "target_branch": target_branch,
        "title": title,
        "description": description,
        "remove_source_branch": remove_source_branch,
    }
    if existing:
        iid = existing[0]["iid"]
        request("PUT", f"/projects/{project}/merge_requests/{iid}", payload)
        print(f"Updated existing merge request !{iid}")
    else:
        created = request("POST", f"/projects/{project}/merge_requests", payload)
        print("Created merge request !%s" % created.get("iid"))
    PY
  SH
}

resource "gitlab_branch" "ci_pipeline" {
  for_each = {
    for key, file in local.ci_pipeline_files : key => file
    if file.create_mr
  }

  project = var.project_ids[each.value.project_name]
  name    = each.value.source_branch
  ref     = each.value.target_branch
}

resource "gitlab_repository_file" "ci_pipeline" {
  for_each = local.ci_pipeline_files

  project = var.project_ids[each.value.project_name]

  file_path = each.value.file_path
  branch    = each.value.source_branch
  content   = each.value.content
  encoding  = "text"

  commit_message      = each.value.commit_message
  overwrite_on_create = true

  depends_on = [gitlab_branch.ci_pipeline]
}

resource "null_resource" "ci_pipeline_merge_request" {
  for_each = {
    for key, file in local.ci_pipeline_files : key => file
    if file.create_mr
  }

  triggers = {
    project_id    = tostring(var.project_ids[each.value.project_name])
    source_branch = each.value.source_branch
    target_branch = each.value.target_branch
    title         = each.value.mr_title
    description   = each.value.mr_description == null ? "" : each.value.mr_description
    remove_branch = tostring(each.value.remove_branch)
    file_path     = each.value.file_path
    file_content  = each.value.content
  }

  provisioner "local-exec" {
    command = local.gitlab_merge_request_command
    environment = {
      GITLAB_API_URL              = "https://gitlab.com/api/v4"
      GITLAB_PROJECT              = self.triggers.project_id
      GITLAB_SOURCE_BRANCH        = self.triggers.source_branch
      GITLAB_TARGET_BRANCH        = self.triggers.target_branch
      GITLAB_MR_TITLE             = self.triggers.title
      GITLAB_MR_DESCRIPTION       = self.triggers.description
      GITLAB_REMOVE_SOURCE_BRANCH = self.triggers.remove_branch
    }
  }

  depends_on = [gitlab_repository_file.ci_pipeline]
}
