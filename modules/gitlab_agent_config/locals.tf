locals {
  gitlab_api_url = trimsuffix(var.gitlab_api_url, "/")

  agent_name                    = coalesce(try(var.gitlab_agent.name, null), var.cluster_name)
  config_project_name           = try(var.gitlab_agent.config_project_name, null)
  config_project_id             = try(coalesce(try(var.gitlab_agent.config_project_id, null), local.config_project_name == null ? null : try(var.project_ids[local.config_project_name], null), var.central_project_id), null)
  config_project_path           = try(coalesce(try(var.gitlab_agent.config_project_path, null), local.config_project_name == null ? null : try(var.project_paths[local.config_project_name], null), var.central_project_path), null)
  source_branch                 = try(var.gitlab_agent.source_branch, "feature/gitlab-agent-config")
  target_branch                 = try(var.gitlab_agent.target_branch, "main")
  mr_title                      = try(var.gitlab_agent.mr_title, "Add GitLab Agent configuration")
  config_file_path              = coalesce(try(var.gitlab_agent.config_file_path, null), ".gitlab/agents/${local.agent_name}/config.yaml")
  register_agent                = var.enabled && try(var.gitlab_agent.register_agent, false)
  install_enabled               = local.register_agent && try(var.gitlab_agent.install.enabled, false)
  token_name                    = coalesce(try(var.gitlab_agent.token_name, null), "${local.agent_name}-token")
  token_description             = coalesce(try(var.gitlab_agent.token_description, null), "Token for the ${local.agent_name} GitLab Agent Helm deployment")
  helm_release_name             = coalesce(try(var.gitlab_agent.install.release_name, null), local.agent_name)
  helm_namespace                = coalesce(try(var.gitlab_agent.install.namespace, null), "gitlab-agent-${local.agent_name}")
  helm_create_namespace         = try(var.gitlab_agent.install.create_namespace, true)
  helm_repository               = try(var.gitlab_agent.install.repository, "https://charts.gitlab.io")
  helm_chart                    = try(var.gitlab_agent.install.chart, "gitlab-agent")
  helm_chart_version            = try(var.gitlab_agent.install.chart_version, null)
  helm_kas_address              = try(var.gitlab_agent.install.kas_address, "wss://kas.gitlab.com")
  helm_timeout                  = try(var.gitlab_agent.install.timeout, 300)
  helm_wait                     = try(var.gitlab_agent.install.wait, true)
  helm_atomic                   = try(var.gitlab_agent.install.atomic, false)
  helm_values                   = try(var.gitlab_agent.install.values, [])
  helm_set_values               = try(var.gitlab_agent.install.set_values, [])
  default_ci_access_paths       = var.enabled ? concat(var.central_project_path == null ? [] : [var.central_project_path], var.service_project_paths) : []
  configured_ci_access_projects = coalesce(try(var.gitlab_agent.ci_access.projects, null), [])
  ci_access_project_inputs = length(local.configured_ci_access_projects) > 0 ? [
    for project in local.configured_ci_access_projects : {
      id                      = project.id
      environments            = try(project.environments, null)
      protected_branches_only = try(project.protected_branches_only, null)
      access_as_ci_job        = try(project.access_as_ci_job, false)
    }
    ] : [
    for path in local.default_ci_access_paths : {
      id                      = path
      environments            = null
      protected_branches_only = null
      access_as_ci_job        = false
    }
  ]
  ci_access_projects = [
    for project in local.ci_access_project_inputs : merge(
      { id = project.id },
      project.environments == null ? {} : { environments = project.environments },
      project.protected_branches_only == null ? {} : { protected_branches_only = project.protected_branches_only },
      project.access_as_ci_job ? { access_as = { ci_job = {} } } : {}
    )
  ]
  ci_access_groups = [
    for group in coalesce(try(var.gitlab_agent.ci_access.groups, null), []) : merge(
      { id = group.id },
      try(group.environments, null) == null ? {} : { environments = group.environments },
      try(group.protected_branches_only, null) == null ? {} : { protected_branches_only = group.protected_branches_only },
      try(group.access_as_ci_job, false) ? { access_as = { ci_job = {} } } : {}
    )
  ]
  ci_access = merge(
    length(local.ci_access_projects) == 0 ? {} : { projects = local.ci_access_projects },
    length(local.ci_access_groups) == 0 ? {} : { groups = local.ci_access_groups },
    try(var.gitlab_agent.ci_access.instance, false) ? { instance = {} } : {}
  )
  user_access_projects = [
    for project in coalesce(try(var.gitlab_agent.user_access.projects, null), []) : {
      id = project.id
    }
  ]
  user_access_as_agent = coalesce(try(var.gitlab_agent.user_access.access_as_agent, null), length(local.user_access_projects) > 0)
  user_access = merge(
    local.user_access_as_agent ? { access_as = { agent = {} } } : {},
    length(local.user_access_projects) == 0 ? {} : { projects = local.user_access_projects }
  )
  config_yaml = templatefile("${path.module}/templates/config.yaml.tftpl", {
    ci_access_projects = local.ci_access_projects
    ci_access_groups   = local.ci_access_groups
    ci_access_instance = try(var.gitlab_agent.ci_access.instance, false)
    user_access        = local.user_access
  })

  agent_path = var.enabled && local.config_project_path != null ? "${local.config_project_path}:${local.agent_name}" : ""

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
