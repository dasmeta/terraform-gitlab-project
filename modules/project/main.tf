resource "gitlab_project" "this" {
  for_each = var.projects_enabled ? { for p in var.gitlab_projects : p.name => p } : {}

  name         = each.value.name
  description  = try(each.value.description, null)
  namespace_id = try(each.value.namespace_id, null)

  visibility_level       = each.value.visibility_level
  default_branch         = each.value.default_branch
  initialize_with_readme = each.value.initialize_with_readme
  request_access_enabled = each.value.request_access_enabled
  lfs_enabled            = each.value.lfs_enabled
  packages_enabled       = each.value.packages_enabled

  squash_option = each.value.squash_option
  merge_method  = each.value.merge_method

  only_allow_merge_if_pipeline_succeeds = each.value.only_allow_merge_if_pipeline_succeeds

  ci_pipeline_variables_minimum_override_role = each.value.ci_pipeline_variables_minimum_override_role

  only_allow_merge_if_all_discussions_are_resolved = each.value.only_allow_merge_if_all_discussions_are_resolved

  remove_source_branch_after_merge = each.value.remove_source_branch_after_merge

  pages_access_level = each.value.pages_access_level

  suggestion_commit_message = try(each.value.suggestion_commit_message, null)
  merge_commit_template     = try(each.value.merge_commit_template, null)

  dynamic "push_rules" {
    for_each = each.value.push_rules
    content {
      author_email_regex            = try(push_rules.value.author_email_regex, null)
      branch_name_regex             = try(push_rules.value.branch_name_regex, null)
      commit_committer_check        = push_rules.value.commit_committer_check
      commit_message_negative_regex = try(push_rules.value.commit_message_negative_regex, null)
      commit_message_regex          = try(push_rules.value.commit_message_regex, null)
      deny_delete_tag               = push_rules.value.deny_delete_tag
      file_name_regex               = try(push_rules.value.file_name_regex, null)
      max_file_size                 = try(push_rules.value.max_file_size, null)
      member_check                  = push_rules.value.member_check
      prevent_secrets               = push_rules.value.prevent_secrets
      reject_unsigned_commits       = push_rules.value.reject_unsigned_commits
    }
  }
}

resource "gitlab_branch_protection" "branch" {
  for_each = var.projects_enabled ? {
    for row in local.branch_protections_flat : row.key => row
  } : {}

  project = gitlab_project.this[each.value.project_name].id
  branch  = each.value.branch

  merge_access_level           = each.value.merge_access_level
  push_access_level            = each.value.push_access_level
  allow_force_push             = each.value.allow_force_push
  code_owner_approval_required = each.value.code_owner_approval_required
  unprotect_access_level       = each.value.unprotect_access_level
}

resource "gitlab_project_approval_rule" "this" {
  for_each = var.projects_enabled ? {
    for p in var.gitlab_projects : p.name => p
    if try(p.approval_rule.enabled, false)
  } : {}

  project = gitlab_project.this[each.key].id

  name               = coalesce(try(each.value.approval_rule.name, null), "Approval rule")
  approvals_required = coalesce(try(each.value.approval_rule.approvals_required, null), 1)

  applies_to_all_protected_branches = coalesce(try(each.value.approval_rule.applies_to_all_protected_branches, null), false)

  user_ids  = try(each.value.approval_rule.user_ids, null)
  group_ids = try(each.value.approval_rule.group_ids, null)
}
