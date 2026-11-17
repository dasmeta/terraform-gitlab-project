resource "gitlab_branch" "this" {
  for_each = local.projects

  project = lookup(var.project_ids, each.key, "")
  name    = each.value.renovate.source_branch
  ref     = each.value.default_branch

  lifecycle {
    precondition {
      condition     = contains(keys(var.project_ids), each.key)
      error_message = "Every enabled Renovate project must have an entry in project_ids."
    }
  }
}

resource "gitlab_repository_file" "this" {
  for_each = local.projects

  project             = var.project_ids[each.key]
  branch              = gitlab_branch.this[each.key].name
  file_path           = "renovate.json"
  content             = jsonencode(local.configs[each.key])
  encoding            = "text"
  commit_message      = "chore: configure Renovate"
  overwrite_on_create = true
}

resource "null_resource" "merge_request" {
  for_each = local.projects

  triggers = {
    endpoint       = var.endpoint
    project        = var.project_ids[each.key]
    source_branch  = each.value.renovate.source_branch
    target_branch  = each.value.default_branch
    title          = each.value.renovate.merge_request_title
    content_sha256 = sha256(gitlab_repository_file.this[each.key].content)
    script_sha256  = filesha256("${path.module}/scripts/ensure_merge_request.py")
  }

  provisioner "local-exec" {
    command = "python3 \"$RENOVATE_MR_SCRIPT\""
    environment = {
      RENOVATE_MR_SCRIPT   = abspath("${path.module}/scripts/ensure_merge_request.py")
      GITLAB_API_URL       = self.triggers.endpoint
      GITLAB_PROJECT       = self.triggers.project
      GITLAB_SOURCE_BRANCH = self.triggers.source_branch
      GITLAB_TARGET_BRANCH = self.triggers.target_branch
      GITLAB_MR_TITLE      = self.triggers.title
    }
  }
}
