resource "gitlab_branch" "this" {
  for_each = local.projects

  project = lookup(var.project_ids, each.key, "")
  name    = local.source_branches[each.key]
  ref     = data.external.existing[each.key].result.commit_sha

  depends_on = [data.external.existing]

  lifecycle {
    create_before_destroy = true
    # Creation uses the exact snapshot inspected at plan. Later target commits
    # must not replace an existing content-addressed proposal branch.
    ignore_changes = [ref]
    precondition {
      condition     = contains(keys(var.project_ids), each.key)
      error_message = "Every enabled Renovate project must have an entry in project_ids."
    }
  }
}

# File publication now compares live contents before writing. Forget legacy
# file instances without deleting files from existing proposal branches.
removed {
  from = gitlab_repository_file.this
  lifecycle {
    destroy = false
  }
}

resource "null_resource" "merge_request" {
  for_each = local.projects

  lifecycle {
    # Branch recreation must republish even when its name/content are unchanged.
    replace_triggered_by = [gitlab_branch.this[each.key]]
  }

  triggers = {
    endpoint      = var.endpoint
    project       = var.project_ids[each.key]
    project_url   = data.gitlab_project.authority[each.key].web_url
    source_branch = gitlab_branch.this[each.key].name
    # The ID becomes unknown when refresh detects deletion. The unchanged name
    # and replace_triggered_by alone do not rerun publication on a create action.
    branch_id             = gitlab_branch.this[each.key].id
    target_branch         = each.value.default_branch
    title                 = each.value.renovate.merge_request_title
    file_path             = data.external.existing[each.key].result.file_path
    content               = local.file_contents[each.key]
    content_sha256        = sha256(local.file_contents[each.key])
    source_content_sha256 = data.external.existing[each.key].result.source_sha256
    script_sha256 = sha256(join("", [for script in ["ensure_merge_request.py", "read_repository_config.py", "gitlab_api.py"] :
      filesha256("${path.module}/scripts/${script}")
    ]))
  }

  provisioner "local-exec" {
    command = "python3 \"$RENOVATE_MR_SCRIPT\""
    environment = {
      RENOVATE_MR_SCRIPT             = abspath("${path.module}/scripts/ensure_merge_request.py")
      GITLAB_API_URL                 = self.triggers.endpoint
      GITLAB_PROJECT                 = self.triggers.project
      GITLAB_PROJECT_URL             = self.triggers.project_url
      GITLAB_SOURCE_BRANCH           = self.triggers.source_branch
      GITLAB_TARGET_BRANCH           = self.triggers.target_branch
      GITLAB_MR_TITLE                = self.triggers.title
      GITLAB_CONFIG_PATH             = self.triggers.file_path
      GITLAB_CONFIG_CONTENT          = self.triggers.content
      GITLAB_EXPECTED_CONTENT_SHA256 = self.triggers.source_content_sha256
    }
  }
}
