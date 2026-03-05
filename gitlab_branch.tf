############################################
# Protect main branch
############################################
resource "gitlab_branch_protection" "main" {
  count   = var.branch_protection.enabled ? 1 : 0
  project = values(gitlab_project.this)[0].id
  branch  = var.branch_protection.branch

  allow_force_push = var.branch_protection.allow_force_push

  push_access_level  = var.branch_protection.push_access_level
  merge_access_level = var.branch_protection.merge_access_level

  code_owner_approval_required = var.branch_protection.code_owner_approval_required
}

############################################
# MR Approvals
############################################
resource "gitlab_project_approval_rule" "default" {
  count   = var.approval_rule.enabled ? 1 : 0
  project = values(gitlab_project.this)[0].id

  name               = var.approval_rule.name
  approvals_required = var.approval_rule.approvals_required

  applies_to_all_protected_branches = var.approval_rule.applies_to_all_protected_branches

  user_ids  = try(var.approval_rule.user_ids, null)
  group_ids = try(var.approval_rule.group_ids, null)
}
