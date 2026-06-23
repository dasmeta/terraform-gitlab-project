locals {
  dynamic_environments_project_enabled = var.projects_enabled && try(var.dynamic_environments_project.enabled, false)
  dynamic_environments_source_branch   = try(var.dynamic_environments_project.source_branch, "feature/dynamic-environments")
  dynamic_environments_api_url         = trimsuffix(try(var.dynamic_environments_project.gitlab_api_url, "https://gitlab.com/api/v4"), "/")
  dynamic_environments_runner_tags     = try(var.dynamic_environments_project.runner_tags, ["k8s-runner"])
  dynamic_environments_runner_tag_yaml = join("\n", [for tag in local.dynamic_environments_runner_tags : "    - ${tag}"])
  dynamic_environments_deploy_mode     = try(var.dynamic_environments_project.deploy_mode, "aws_eks")
  dynamic_environments_ci_config = {
    deploy_image                   = try(var.dynamic_environments_project.ci_config.deploy_image, "alpine/k8s:1.20.15")
    cleanup_image                  = try(var.dynamic_environments_project.ci_config.cleanup_image, "alpine/k8s:1.20.15")
    placeholder_image              = try(var.dynamic_environments_project.ci_config.placeholder_image, "alpine:latest")
    alpine_packages                = try(var.dynamic_environments_project.ci_config.alpine_packages, ["python3", "py3-pip", "git", "bash"])
    python_packages                = try(var.dynamic_environments_project.ci_config.python_packages, ["pyyaml"])
    migration_job_name             = try(var.dynamic_environments_project.ci_config.migration_job_name, "db-migration")
    migration_timeout              = try(var.dynamic_environments_project.ci_config.migration_timeout, "600s")
    aws_access_key_id_variable     = try(var.dynamic_environments_project.ci_config.aws_access_key_id_variable, "AWS_ACCESS_KEY_DEV_ID")
    aws_secret_access_key_variable = try(var.dynamic_environments_project.ci_config.aws_secret_access_key_variable, "AWS_SECRET_ACCESS_DEV_KEY")
  }
  dynamic_environments_e2e_default_variables = {
    E2E_DYNAMIC_STACK = "true"
  }
  dynamic_environments_e2e_default_rules = [
    {
      if   = "$REMOVE_DYNAMIC"
      when = "never"
    },
    {
      if   = "$CI_PIPELINE_SOURCE == \"merge_request_event\""
      when = "never"
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"pipeline\""
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"parent_pipeline\""
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"trigger\""
    },
  ]
  dynamic_environments_e2e_config = {
    enabled  = try(var.dynamic_environments_project.e2e_config.enabled, false)
    project  = try(var.dynamic_environments_project.e2e_config.project, null)
    branch   = try(var.dynamic_environments_project.e2e_config.branch, "main")
    strategy = try(var.dynamic_environments_project.e2e_config.strategy, "depend")
    variables = merge(
      local.dynamic_environments_e2e_default_variables,
      try(var.dynamic_environments_project.e2e_config.variables, {})
    )
    rules = concat(
      local.dynamic_environments_e2e_default_rules,
      [
        for rule in try(var.dynamic_environments_project.e2e_config.rules, []) : merge(
          { if = rule.if },
          try(rule.when, null) != null ? { when = rule.when } : {}
        )
      ]
    )
  }

  dynamic_environments_project_id   = local.dynamic_environments_project_enabled ? gitlab_project.dynamic_environment["central"].id : null
  dynamic_environments_project_path = local.dynamic_environments_project_enabled ? gitlab_project.dynamic_environment["central"].path_with_namespace : null

  dynamic_environments_agent_path = local.dynamic_environments_project_enabled ? coalesce(
    try(var.dynamic_environments_project.gitlab_agent_path, null),
    var.gitlab_agent_path != "" ? var.gitlab_agent_path : null,
    local.dynamic_environments_project_path != null ? "${local.dynamic_environments_project_path}:${try(var.dynamic_environments_project.cluster_name, "eks-dev")}" : null
  ) : ""

  dynamic_environments_applications_defaults = {
    for k, v in try(var.dynamic_environments_project.applications.defaults, {}) : k => v
    if v != null
  }
  dynamic_environments_applications_infra_deployments = [
    for deployment in try(var.dynamic_environments_project.applications.infra_deployments, []) : {
      for k, v in deployment : k => v
      if v != null
    }
  ]
  dynamic_environments_applications_deployments = [
    for deployment in try(var.dynamic_environments_project.applications.deployments, []) : {
      for k, v in deployment : k => v
      if v != null
    }
  ]
  dynamic_environments_applications_yaml = templatefile("${path.module}/templates/applications.yaml.tftpl", {
    defaults          = local.dynamic_environments_applications_defaults
    infra_deployments = local.dynamic_environments_applications_infra_deployments
    deployments       = local.dynamic_environments_applications_deployments
  })

  dynamic_environments_deploy_config = merge(
    {
      aws_region                   = "us-east-2"
      namespace_prefix             = "e2e-"
      fallback_image_tag           = "latest"
      gitlab_api_timeout_seconds   = 20
      gitlab_api_url               = try(var.dynamic_environments_project.gitlab_api_url, "https://gitlab.com/api/v4")
      gitlab_clone_base_url        = "https://gitlab.com"
      helm_repo_name               = "dasmeta"
      helm_repo_url                = "https://dasmeta.github.io/helm"
      work_dir                     = "/tmp/dynamic-deploy"
      helm_dir                     = "helm"
      image_tag_set_path           = "image.tag"
      migration_image_tag_set_path = "job.image.tag"
      base_ref_fallbacks           = ["main", "master"]
      helm_value_files             = ["values.yaml", "values.dev.yaml"]
      helm_optional_value_files    = ["values.dev.<APP_COMPONENT>.yaml"]
      helm_required_value_files    = ["values.e2e.yaml"]
      helm_migration_value_files   = ["values.e2e.migration.yaml"]
    },
    {
      for k, v in try(var.dynamic_environments_project.deploy_config, {}) : k => v
      if v != null
    }
  )
  dynamic_environments_cleanup_config = merge(
    {
      namespace_prefix      = local.dynamic_environments_deploy_config.namespace_prefix
      max_attempts          = 3
      retry_backoff_seconds = 5
    },
    {
      for k, v in try(var.dynamic_environments_project.cleanup_config, {}) : k => v
      if v != null
    }
  )

  dynamic_environments_deploy_stack_py = templatefile("${path.module}/templates/deploy_stack.py.tftpl", {
    deploy_config = local.dynamic_environments_deploy_config
  })
  dynamic_environments_clean_stack_py = templatefile("${path.module}/templates/clean_stack.py.tftpl", {
    cleanup_config = local.dynamic_environments_cleanup_config
  })
  dynamic_environments_pipeline_rules = [
    {
      if   = "$REMOVE_DYNAMIC"
      when = "never"
    },
    {
      if   = "$CI_PIPELINE_SOURCE == \"merge_request_event\""
      when = "never"
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"pipeline\""
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"parent_pipeline\""
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"trigger\""
    },
    {
      if = "$CI_PIPELINE_SOURCE == \"web\""
    },
  ]
  dynamic_environments_deploy_before_script = concat(
    length(local.dynamic_environments_ci_config.alpine_packages) > 0 ? [
      "apk add --no-cache ${join(" ", local.dynamic_environments_ci_config.alpine_packages)}"
    ] : [],
    length(local.dynamic_environments_ci_config.python_packages) > 0 ? [
      "pip3 install --no-cache-dir ${join(" ", local.dynamic_environments_ci_config.python_packages)}"
    ] : [],
    local.dynamic_environments_deploy_mode == "gitlab_agent" ? [
      "kubectl config use-context \"$GITLAB_AGENT_PATH\""
      ] : [
      format("export AWS_ACCESS_KEY_ID=$%s", local.dynamic_environments_ci_config.aws_access_key_id_variable),
      format("export AWS_SECRET_ACCESS_KEY=$%s", local.dynamic_environments_ci_config.aws_secret_access_key_variable),
      "aws --region $AWS_REGION eks update-kubeconfig --name $CLUSTER_NAME",
    ]
  )
  dynamic_environments_gitlab_ci = merge(
    {
      stages = concat(
        ["deploy"],
        local.dynamic_environments_e2e_config.enabled ? ["e2e-test"] : [],
        ["remove"]
      )
      variables = merge(
        {
          AWS_REGION            = coalesce(try(var.dynamic_environments_project.applications.defaults.aws_region, null), "us-east-2")
          CLUSTER_NAME          = try(var.dynamic_environments_project.cluster_name, "eks-dev")
          SECRET_ENV            = coalesce(try(var.dynamic_environments_project.applications.defaults.secret_env, null), "dev")
          DYNAMIC_NAMESPACE     = "${local.dynamic_environments_deploy_config.namespace_prefix}$CI_PIPELINE_ID"
          DYNAMIC_BASE_DOMAIN   = coalesce(try(var.dynamic_environments_project.applications.defaults.dynamic_base_domain, null), "dev.example.com")
          DYNAMIC_ENV_RELEASE   = coalesce(try(var.dynamic_environments_project.applications.defaults.dynamic_env_release, null), "app")
          GITLAB_AGENT_PATH     = local.dynamic_environments_agent_path
          NAMESPACE_PREFIX      = local.dynamic_environments_deploy_config.namespace_prefix
          HELM_REPO_NAME        = local.dynamic_environments_deploy_config.helm_repo_name
          HELM_REPO_URL         = local.dynamic_environments_deploy_config.helm_repo_url
          WORK_DIR              = local.dynamic_environments_deploy_config.work_dir
          GITLAB_API_URL        = local.dynamic_environments_deploy_config.gitlab_api_url
          GITLAB_CLONE_BASE_URL = local.dynamic_environments_deploy_config.gitlab_clone_base_url
        },
        local.dynamic_environments_e2e_config.enabled ? {
          E2E_PROJECT = local.dynamic_environments_e2e_config.project
          E2E_BRANCH  = local.dynamic_environments_e2e_config.branch
        } : {}
      )
      ".deploy-dynamic" = {
        stage = "deploy"
        image = {
          name       = local.dynamic_environments_ci_config.deploy_image
          entrypoint = ["/bin/sh", "-c"]
        }
        tags = local.dynamic_environments_runner_tags
        environment = {
          name    = "review/$DYNAMIC_NAMESPACE"
          url     = "https://$DYNAMIC_NAMESPACE.$DYNAMIC_BASE_DOMAIN"
          on_stop = "remove-dynamic-stack"
          kubernetes = {
            agent = "$GITLAB_AGENT_PATH"
            dashboard = {
              namespace = "$DYNAMIC_NAMESPACE"
            }
          }
        }
        before_script = local.dynamic_environments_deploy_before_script
        script = [
          "kubectl delete job ${local.dynamic_environments_ci_config.migration_job_name} -n $DYNAMIC_NAMESPACE --ignore-not-found",
          "python3 scripts/deploy_stack.py",
          "kubectl wait --for=condition=complete --timeout=${local.dynamic_environments_ci_config.migration_timeout} job/${local.dynamic_environments_ci_config.migration_job_name} -n $DYNAMIC_NAMESPACE || true",
        ]
      }
      "deploy-dynamic-stack" = {
        extends = ".deploy-dynamic"
        rules   = local.dynamic_environments_pipeline_rules
      }
      mr_pipeline_placeholder = {
        stage = "deploy"
        image = local.dynamic_environments_ci_config.placeholder_image
        tags  = local.dynamic_environments_runner_tags
        script = [
          "echo \"MR pipeline noop. Real deploys run downstream from service MRs.\""
        ]
        rules = [
          {
            if = "$CI_PIPELINE_SOURCE == \"merge_request_event\""
          }
        ]
      }
      "remove-dynamic-stack" = {
        stage = "remove"
        image = {
          name       = local.dynamic_environments_ci_config.cleanup_image
          entrypoint = ["/bin/sh", "-c"]
        }
        tags = local.dynamic_environments_runner_tags
        environment = {
          name   = "review/$DYNAMIC_NAMESPACE"
          action = "stop"
          kubernetes = {
            agent = "$GITLAB_AGENT_PATH"
            dashboard = {
              namespace = "$DYNAMIC_NAMESPACE"
            }
          }
        }
        script = [
          "python3 scripts/clean_stack.py --namespace $DYNAMIC_NAMESPACE",
          "kubectl delete namespace \"$DYNAMIC_NAMESPACE\" --ignore-not-found=true",
        ]
        rules = [
          {
            if = "$REMOVE_DYNAMIC"
          }
        ]
      }
    },
    local.dynamic_environments_e2e_config.enabled ? {
      e2e_tests = {
        stage = "e2e-test"
        trigger = {
          project  = "$E2E_PROJECT"
          branch   = "$E2E_BRANCH"
          strategy = local.dynamic_environments_e2e_config.strategy
        }
        variables = local.dynamic_environments_e2e_config.variables
        rules     = local.dynamic_environments_e2e_config.rules
      }
    } : {}
  )
  dynamic_environments_variables_yaml = join("\n", concat(
    ["variables:"],
    [
      for key in [
        "AWS_REGION",
        "CLUSTER_NAME",
        "SECRET_ENV",
        "DYNAMIC_NAMESPACE",
        "DYNAMIC_BASE_DOMAIN",
        "DYNAMIC_ENV_RELEASE",
        "GITLAB_AGENT_PATH",
        "NAMESPACE_PREFIX",
        "HELM_REPO_NAME",
        "HELM_REPO_URL",
        "WORK_DIR",
        "GITLAB_API_URL",
        "GITLAB_CLONE_BASE_URL",
      ] : "  ${key}: ${local.dynamic_environments_gitlab_ci.variables[key]}"
    ],
    local.dynamic_environments_e2e_config.enabled ? [
      "  E2E_PROJECT: ${local.dynamic_environments_gitlab_ci.variables.E2E_PROJECT}",
      "  E2E_BRANCH: ${local.dynamic_environments_gitlab_ci.variables.E2E_BRANCH}",
    ] : []
  ))
  dynamic_environments_tags_yaml = join("\n", [
    for tag in local.dynamic_environments_runner_tags : "    - ${tag}"
  ])
  dynamic_environments_pipeline_rules_yaml = join("\n", flatten([
    for rule in local.dynamic_environments_pipeline_rules : concat(
      ["    - if: ${rule.if}"],
      try(rule.when, null) != null ? ["      when: ${rule.when}"] : []
    )
  ]))
  dynamic_environments_e2e_rules_yaml = join("\n", flatten([
    for rule in local.dynamic_environments_e2e_config.rules : concat(
      ["    - if: ${rule.if}"],
      try(rule.when, null) != null ? ["      when: ${rule.when}"] : []
    )
  ]))
  dynamic_environments_e2e_variables_yaml = join("\n", [
    for key in sort(keys(local.dynamic_environments_e2e_config.variables)) :
    "    ${key}: ${key == "E2E_DYNAMIC_STACK" ? "\"${local.dynamic_environments_e2e_config.variables[key]}\"" : local.dynamic_environments_e2e_config.variables[key]}"
  ])
  dynamic_environments_deploy_job_yaml = join("\n", concat(
    [
      ".deploy-dynamic:",
      "  stage: deploy",
      "  image:",
      "    name: ${local.dynamic_environments_ci_config.deploy_image}",
      "    entrypoint: [\"/bin/sh\", \"-c\"]",
      "  tags:",
      local.dynamic_environments_tags_yaml,
      "  environment:",
      "    name: review/$DYNAMIC_NAMESPACE",
      "    url: https://$DYNAMIC_NAMESPACE.$DYNAMIC_BASE_DOMAIN",
      "    on_stop: remove-dynamic-stack",
      "    kubernetes:",
      "      agent: $GITLAB_AGENT_PATH",
      "      dashboard:",
      "        namespace: $DYNAMIC_NAMESPACE",
      "  before_script:",
    ],
    [for command in local.dynamic_environments_deploy_before_script : "    - ${command}"],
    [
      "  script:",
      "    - kubectl delete job ${local.dynamic_environments_ci_config.migration_job_name} -n $DYNAMIC_NAMESPACE --ignore-not-found",
      "    - python3 scripts/deploy_stack.py",
      "    - kubectl wait --for=condition=complete --timeout=${local.dynamic_environments_ci_config.migration_timeout} job/${local.dynamic_environments_ci_config.migration_job_name} -n $DYNAMIC_NAMESPACE || true",
    ]
  ))
  dynamic_environments_deploy_stack_job_yaml = join("\n", [
    "deploy-dynamic-stack:",
    "  extends: .deploy-dynamic",
    "  rules:",
    local.dynamic_environments_pipeline_rules_yaml,
  ])
  dynamic_environments_placeholder_job_yaml = join("\n", [
    "mr_pipeline_placeholder:",
    "  stage: deploy",
    "  image: ${local.dynamic_environments_ci_config.placeholder_image}",
    "  tags:",
    local.dynamic_environments_tags_yaml,
    "  script:",
    "    - echo \"MR pipeline noop. Real deploys run downstream from service MRs.\"",
    "  rules:",
    "    - if: $CI_PIPELINE_SOURCE == \"merge_request_event\"",
  ])
  dynamic_environments_e2e_job_yaml = join("\n", [
    "e2e_tests:",
    "  stage: e2e-test",
    "  trigger:",
    "    project: $E2E_PROJECT",
    "    branch: $E2E_BRANCH",
    "    strategy: ${local.dynamic_environments_e2e_config.strategy}",
    "  variables:",
    local.dynamic_environments_e2e_variables_yaml,
    "  rules:",
    local.dynamic_environments_e2e_rules_yaml,
  ])
  dynamic_environments_remove_job_yaml = join("\n", [
    "remove-dynamic-stack:",
    "  stage: remove",
    "  image:",
    "    name: ${local.dynamic_environments_ci_config.cleanup_image}",
    "    entrypoint: [\"/bin/sh\", \"-c\"]",
    "  tags:",
    local.dynamic_environments_tags_yaml,
    "  environment:",
    "    name: review/$DYNAMIC_NAMESPACE",
    "    action: stop",
    "    kubernetes:",
    "      agent: $GITLAB_AGENT_PATH",
    "      dashboard:",
    "        namespace: $DYNAMIC_NAMESPACE",
    "  script:",
    "    - python3 scripts/clean_stack.py --namespace $DYNAMIC_NAMESPACE",
    "    - kubectl delete namespace \"$DYNAMIC_NAMESPACE\" --ignore-not-found=true",
    "  rules:",
    "    - if: $REMOVE_DYNAMIC",
  ])
  dynamic_environments_gitlab_ci_sections = concat(
    [
      join("\n", concat(
        ["stages:"],
        [for stage in local.dynamic_environments_gitlab_ci.stages : "  - ${stage}"]
      )),
      local.dynamic_environments_variables_yaml,
      local.dynamic_environments_deploy_job_yaml,
      local.dynamic_environments_deploy_stack_job_yaml,
      local.dynamic_environments_placeholder_job_yaml,
    ],
    local.dynamic_environments_e2e_config.enabled ? [
      local.dynamic_environments_e2e_job_yaml
    ] : [],
    [
      local.dynamic_environments_remove_job_yaml
    ]
  )
  dynamic_environments_gitlab_ci_yml = join("\n", [
    "# GENERATED FILE - DO NOT EDIT",
    "# Managed by Terraform. Manual changes may be overwritten.",
    "# Update the source Terraform configuration instead.",
    "",
    join("\n\n", local.dynamic_environments_gitlab_ci_sections),
  ])

  dynamic_environments_managed_directory_readme = <<-MD
    # Terraform-managed directory

    This directory is generated and managed by Terraform.
    Do not edit files manually; changes may be overwritten.
  MD

  dynamic_environments_project_readme = <<-MD
    # Dynamic Environments

    This project is provisioned and maintained through Terraform.

    Files under `config/` and `scripts/`, along with the root `.gitlab-ci.yml`,
    are generated artifacts and must not be modified manually. Any out-of-band
    changes may be overwritten during the next Terraform apply.

    Update the corresponding Terraform configuration in the source module
    instead of editing generated files directly.
  MD

  dynamic_environments_central_files = local.dynamic_environments_project_enabled ? {
    "README.md"                = local.dynamic_environments_project_readme
    "config/applications.yaml" = local.dynamic_environments_applications_yaml
    "config/README.md"         = local.dynamic_environments_managed_directory_readme
    "scripts/deploy_stack.py"  = local.dynamic_environments_deploy_stack_py
    "scripts/clean_stack.py"   = local.dynamic_environments_clean_stack_py
    "scripts/README.md"        = local.dynamic_environments_managed_directory_readme
    ".gitlab-ci.yml"           = local.dynamic_environments_gitlab_ci_yml
  } : {}

  dynamic_environment_enabled_services = {
    for p in var.gitlab_projects : p.name => p
    if var.projects_enabled && try(p.dynamic_environment.enabled, false)
  }

  dynamic_environment_service_file_content = {
    for name, p in local.dynamic_environment_enabled_services : name => templatefile("${path.module}/templates/service-dynamic-environment.gitlab-ci.yml.tftpl", {
      name                                = name
      stage                               = try(p.dynamic_environment.stage, "e2e-test-dynamic")
      needs                               = try(p.dynamic_environment.needs, ["build"])
      dynamic_environments_project_path   = local.dynamic_environments_project_path
      dynamic_environments_default_branch = try(var.dynamic_environments_project.default_branch, "main")
      dynamic_base_domain                 = coalesce(try(var.dynamic_environments_project.applications.defaults.dynamic_base_domain, null), "dev.example.com")
      dynamic_environments_agent_path     = local.dynamic_environments_agent_path
      source_environment                  = try(p.dynamic_environment.source_environment, "dev")
      dynamic_env_release                 = coalesce(try(p.dynamic_environment.dynamic_env_release, null), name)
      cleanup_stage                       = try(p.dynamic_environment.cleanup_stage, "e2e-test-dynamic-clean")
    })
  }

  dynamic_environment_service_mr_descriptions = {
    for name, p in local.dynamic_environment_enabled_services : name => replace(trimspace(<<-MD
      Adds the reusable dynamic environment CI trigger file.

      To activate it from the root `.gitlab-ci.yml`, include:

      ```yaml
      include:
        - local: ${try(p.dynamic_environment.ci_file_path, "ci-pipelines/dynamic-environment.gitlab-ci.yml")}
      ```

      The generated branch and file are managed by Terraform.
    MD
    ), "\n      ", "\n")
  }

  gitlab_merge_request_command = <<-SH
python3 <<'PY'
import json
import os
import sys
import urllib.parse
import urllib.request
import urllib.error

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
    "remove_source_branch": True,
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
