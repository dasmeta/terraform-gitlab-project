locals {
  create = var.create
}

# data "gitlab_user" "username" {
#   username = var.username
# }

resource "gitlab_project" "this" {
  count = local.create ? 1 : 0

  name        = var.name
  description = var.description
  # namespace_id = "56195749" // data.gitlab_user.username.namespace_id

  visibility_level       = var.visibility_level
  default_branch         = var.default_branch
  initialize_with_readme = var.initialize_with_readme
  request_access_enabled = var.request_access_enabled
  lfs_enabled            = var.lfs_enabled
  packages_enabled       = var.packages_enabled
  snippets_enabled       = var.snippets_enabled
  wiki_enabled           = var.wiki_enabled

  merge_method                                     = var.merge_method
  approvals_before_merge                           = var.approvals_before_merge
  only_allow_merge_if_pipeline_succeeds            = var.only_allow_merge_if_pipeline_succeeds
  only_allow_merge_if_all_discussions_are_resolved = var.only_allow_merge_if_all_discussions_are_resolved
  remove_source_branch_after_merge                 = var.remove_source_branch_after_merge

  pages_access_level = var.pages_access_level

  suggestion_commit_message = var.suggestion_commit_message
  merge_commit_template     = var.merge_commit_template
  
  dynamic "push_rules" {
    for_each = length(var.push_rules) > 0 ? var.push_rules : []
    content {
      author_email_regex            = try(push_rules.value.author_email_regex, null)
      branch_name_regex             = try(push_rules.value.branch_name_regex, null)
      commit_committer_check        = try(push_rules.value.commit_committer_check, null)
      commit_message_negative_regex = try(push_rules.value.commit_message_negative_regex, null)
      commit_message_regex          = try(push_rules.value.commit_message_regex, null)
      deny_delete_tag               = try(push_rules.value.deny_delete_tag, null)
      file_name_regex               = try(push_rules.value.file_name_regex, null)
      max_file_size                 = try(push_rules.value.max_file_size, null)
      member_check                  = try(push_rules.value.member_check, null)
      prevent_secrets               = try(push_rules.value.prevent_secrets, null)
      reject_unsigned_commits       = try(push_rules.value.reject_unsigned_commits, null)
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
