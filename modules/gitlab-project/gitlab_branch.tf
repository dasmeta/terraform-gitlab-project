locals {
  create_branch = var.create_branch
}

resource "gitlab_branch" "branch" {
  count = local.create_branch ? 1 : 0

  project = gitlab_project.this[0].id
  name    = var.branch_name
  ref     = var.ref
}

resource "gitlab_branch_protection" "branch_protection" {
  count = local.create_branch ? 1 : 0

  project            = gitlab_project.this[0].id
  branch             = var.branch_name
  merge_access_level = var.merge_access_level
  push_access_level  = var.push_access_level
}
