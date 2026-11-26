resource "gitlab_branch" "this" {
  for_each = local.projects

  project = lookup(var.project_ids, each.key, "")
  name    = local.source_branches[each.key]
  ref     = each.value.default_branch

  depends_on = [data.external.existing]

  lifecycle {
    create_before_destroy = true
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
  file_path           = data.external.existing[each.key].result.file_path
  content             = local.file_contents[each.key]
  encoding            = "text"
  commit_message      = "chore: configure Renovate"
  overwrite_on_create = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "merge_request" {
  for_each = local.projects

  triggers = {
    endpoint       = var.endpoint
    project        = var.project_ids[each.key]
    source_branch  = local.source_branches[each.key]
    target_branch  = each.value.default_branch
    title          = each.value.renovate.merge_request_title
    file_path      = gitlab_repository_file.this[each.key].file_path
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
      GITLAB_CONFIG_PATH   = self.triggers.file_path
    }
  }
}
