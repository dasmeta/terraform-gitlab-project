locals {
  dynamic_environments_project_enabled = var.projects_enabled && try(var.dynamic_environments_project.enabled, false)
  dynamic_environments_source_branch   = try(var.dynamic_environments_project.source_branch, "feature/dynamic-environments")
  dynamic_environments_api_url         = trimsuffix(try(var.dynamic_environments_project.gitlab_api_url, "https://gitlab.com/api/v4"), "/")
  dynamic_environments_runner_tags     = try(var.dynamic_environments_project.runner_tags, ["k8s-runner"])
  dynamic_environments_runner_tag_yaml = join("\n", [for tag in local.dynamic_environments_runner_tags : "    - ${tag}"])
  dynamic_environments_deploy_mode     = try(var.dynamic_environments_project.deploy_mode, "aws_eks")

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
  dynamic_environments_gitlab_ci_yml = templatefile("${path.module}/templates/central.gitlab-ci.yml.tftpl", {
    aws_region            = coalesce(try(var.dynamic_environments_project.applications.defaults.aws_region, null), "us-east-2")
    cluster_name          = try(var.dynamic_environments_project.cluster_name, "eks-dev")
    secret_env            = coalesce(try(var.dynamic_environments_project.applications.defaults.secret_env, null), "dev")
    dynamic_base_domain   = coalesce(try(var.dynamic_environments_project.applications.defaults.dynamic_base_domain, null), "dev.example.com")
    dynamic_env_release   = coalesce(try(var.dynamic_environments_project.applications.defaults.dynamic_env_release, null), "app")
    namespace_prefix      = local.dynamic_environments_deploy_config.namespace_prefix
    helm_repo_name        = local.dynamic_environments_deploy_config.helm_repo_name
    helm_repo_url         = local.dynamic_environments_deploy_config.helm_repo_url
    work_dir              = local.dynamic_environments_deploy_config.work_dir
    gitlab_api_url        = local.dynamic_environments_deploy_config.gitlab_api_url
    gitlab_clone_base_url = local.dynamic_environments_deploy_config.gitlab_clone_base_url
    gitlab_agent_path     = local.dynamic_environments_agent_path
    deploy_mode           = local.dynamic_environments_deploy_mode
    runner_tags           = local.dynamic_environments_runner_tags
  })

  dynamic_environments_central_files = local.dynamic_environments_project_enabled ? {
    "config/applications.yaml" = local.dynamic_environments_applications_yaml
    "scripts/deploy_stack.py"  = local.dynamic_environments_deploy_stack_py
    "scripts/clean_stack.py"   = local.dynamic_environments_clean_stack_py
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
