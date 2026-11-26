data "gitlab_project" "authority" {
  for_each = local.projects

  id = lookup(var.project_ids, each.key, "")
}

data "external" "existing" {
  for_each = local.projects

  program = ["python3", "${path.module}/scripts/read_repository_config.py"]
  query = {
    endpoint    = var.endpoint
    project     = lookup(var.project_ids, each.key, "")
    project_url = data.gitlab_project.authority[each.key].web_url
    ref         = each.value.default_branch
  }
}

data "external" "formatted" {
  for_each = local.projects

  program = ["python3", "${path.module}/scripts/format_repository_json.py"]
  query = {
    document = jsonencode(local.documents[each.key])
  }
}
