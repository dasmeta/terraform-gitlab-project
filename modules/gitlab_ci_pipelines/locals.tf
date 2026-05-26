locals {
  build_pipeline_file_path      = "ci-pipelines/build.gitlab-ci.yml"
  build_pipeline_source_branch  = "feature/build-gitlab-ci-template"
  build_pipeline_mr_title       = "Add reusable build-only GitLab CI template"
  deploy_pipeline_file_path     = "ci-pipelines/deploy.gitlab-ci.yml"
  deploy_pipeline_source_branch = "feature/deploy-gitlab-ci-template"
  deploy_pipeline_mr_title      = "Add reusable Helm deploy GitLab CI template"

  build_pipeline_projects = {
    for p in var.gitlab_projects : p.name => p
    if var.projects_enabled && try(p.build_pipeline, {}) != null
  }

  deploy_pipeline_projects = {
    for p in var.gitlab_projects : p.name => p
    if var.projects_enabled && try(p.deploy_pipeline, {}) != null
  }

  build_pipeline_content = {
    for name, p in local.build_pipeline_projects : name => templatefile("${path.module}/templates/build-gitlab.ci.yaml.tftpl", {
      tags           = try(p.build_pipeline.tags, [])
      build_image    = try(p.build_pipeline.build_image, {})
      build_services = try(p.build_pipeline.build_services, [])
    })
  }

  deploy_pipeline_content = {
    for name, p in local.deploy_pipeline_projects : name => templatefile("${path.module}/templates/deploy-gitlab.ci.yaml.tftpl", {
      tags                = try(p.deploy_pipeline.tags, [])
      deploy_image        = try(p.deploy_pipeline.deploy_image, {})
      environment_enabled = try(p.dynamic_environment.enabled, false)
    })
  }

  build_pipeline_mr_descriptions = {
    for name, p in local.build_pipeline_projects : name => replace(trimspace(<<-MD
      Adds the reusable build CI pipeline file.

      To activate it from the root `.gitlab-ci.yml`, include:

      ```yaml
      include:
        - local: ${local.build_pipeline_file_path}
      ```

      Then create concrete jobs with `extends: .build` and pass only `variables` from the root CI file. The generated file keeps reusable build logic in one place and leaves the root `.gitlab-ci.yml` or `.gitlab-ci.yaml` under manual control.

      Standard runtime variables include `BUILD_MODE`, `REGISTRY_PROVIDER`, `IMAGE_REPOSITORY`, `IMAGE_TAG`, `DOCKERFILE_PATH`, and `BUILD_CONTEXT`. Optional variable-driven hooks such as `BUILD_PRE_SCRIPT`, `BUILD_SETUP_SCRIPT`, and `BUILD_COMMAND` can be used when a repository needs custom build preparation or a custom build invocation without redefining the reusable `.build` job.

      The generated branch and file are managed by Terraform.
    MD
    ), "\n      ", "\n")
  }

  deploy_pipeline_mr_descriptions = {
    for name, p in local.deploy_pipeline_projects : name => replace(trimspace(<<-MD
      Adds the reusable Helm deploy CI pipeline file.

      To activate it from the root `.gitlab-ci.yml`, include:

      ```yaml
      include:
        - local: ${local.deploy_pipeline_file_path}
      ```

      Then create concrete jobs with `extends: .deploy` and pass only `variables` from the root CI file. The generated file keeps reusable deploy logic in one place and leaves the root `.gitlab-ci.yml` or `.gitlab-ci.yaml` under manual control.

      Standard runtime variables include `KUBE_CONTEXT`, `AWS_EKS_CLUSTER_NAME`, `AWS_REGION`, `KUBE_NAMESPACE`, `HELM_RELEASE`, and `HELM_CHART`. Optional variables such as `HELM_CHART_VERSION`, `HELM_VALUES_ARGS`, `HELM_SET_ARGS`, `HELM_EXTRA_ARGS`, `DEPLOY_IMAGE_REPOSITORY`, and `DEPLOY_IMAGE_TAG` can be used to customize the Helm deploy without redefining the reusable `.deploy` job.

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
