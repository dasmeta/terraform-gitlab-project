resource "gitlab_project" "this" {
  for_each = {
    for p in var.gitlab_projects : p.name => p
    if var.projects_enabled
  }

  name         = each.value.name
  description  = try(each.value.description, null)
  namespace_id = try(each.value.namespace_id, null)

  visibility_level       = coalesce(try(each.value.visibility_level, null), "private")
  default_branch         = coalesce(try(each.value.default_branch, null), "develop")
  initialize_with_readme = coalesce(try(each.value.initialize_with_readme, null), true)
  request_access_enabled = coalesce(try(each.value.request_access_enabled, null), true)
  lfs_enabled            = coalesce(try(each.value.lfs_enabled, null), true)
  packages_enabled       = coalesce(try(each.value.packages_enabled, null), true)

  squash_option = coalesce(try(each.value.squash_option, null), "default_on")
  merge_method  = coalesce(try(each.value.merge_method, null), "merge")

  only_allow_merge_if_pipeline_succeeds = coalesce(try(each.value.only_allow_merge_if_pipeline_succeeds, null), true)

  ci_pipeline_variables_minimum_override_role = coalesce(try(each.value.ci_pipeline_variables_minimum_override_role, null), "developer")

  only_allow_merge_if_all_discussions_are_resolved = coalesce(try(each.value.only_allow_merge_if_all_discussions_are_resolved, null), true)

  remove_source_branch_after_merge = coalesce(try(each.value.remove_source_branch_after_merge, null), true)

  pages_access_level = coalesce(try(each.value.pages_access_level, null), "private")

  suggestion_commit_message = try(each.value.suggestion_commit_message, null)
  merge_commit_template     = try(each.value.merge_commit_template, null)

  dynamic "push_rules" {
    for_each = try(each.value.push_rules, [])
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
  for_each = {
    for row in local.branch_protections_flat : row.key => row
    if var.projects_enabled
  }

  project = gitlab_project.this[each.value.project_name].id
  branch  = each.value.branch

  merge_access_level           = each.value.merge_access_level
  push_access_level            = each.value.push_access_level
  allow_force_push             = each.value.allow_force_push
  code_owner_approval_required = each.value.code_owner_approval_required
  unprotect_access_level       = each.value.unprotect_access_level
}

resource "gitlab_project_approval_rule" "this" {
  for_each = {
    for row in flatten([
      for p in var.gitlab_projects : concat(
        [
          for rule in [try(p.approval_rule, null)] : {
            key                               = "${p.name}::${coalesce(try(rule.name, null), "Approval rule")}::0"
            project_name                      = p.name
            name                              = coalesce(try(rule.name, null), "Approval rule")
            approvals_required                = coalesce(try(rule.approvals_required, null), 1)
            applies_to_all_protected_branches = coalesce(try(rule.applies_to_all_protected_branches, null), false)
            user_ids                          = try(rule.user_ids, null)
            group_ids                         = try(rule.group_ids, null)
          } if rule != null && can(keys(rule))
        ],
        [
          for idx, rule in can(p.approval_rule[0]) ? p.approval_rule : [] : {
            key                               = "${p.name}::${coalesce(try(rule.name, null), "Approval rule")}::${idx}"
            project_name                      = p.name
            name                              = coalesce(try(rule.name, null), "Approval rule")
            approvals_required                = coalesce(try(rule.approvals_required, null), 1)
            applies_to_all_protected_branches = coalesce(try(rule.applies_to_all_protected_branches, null), false)
            user_ids                          = try(rule.user_ids, null)
            group_ids                         = try(rule.group_ids, null)
          } if can(rule.name)
        ]
      )
    ]) : row.key => row
    if var.projects_enabled
  }

  project = gitlab_project.this[each.value.project_name].id

  name               = each.value.name
  approvals_required = each.value.approvals_required

  applies_to_all_protected_branches = each.value.applies_to_all_protected_branches

  user_ids  = each.value.user_ids
  group_ids = each.value.group_ids
}
