data "external" "existing" {
  for_each = local.projects

  program = ["python3", "${path.module}/scripts/read_repository_config.py"]
  query = {
    endpoint = var.endpoint
    project  = lookup(var.project_ids, each.key, "")
    ref      = each.value.default_branch
  }
}

data "external" "formatted" {
  for_each = local.projects

  program = ["python3", "${path.module}/scripts/format_repository_json.py"]
  query = {
    document = jsonencode(local.documents[each.key])
  }
}
