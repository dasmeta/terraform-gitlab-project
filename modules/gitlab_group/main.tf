resource "gitlab_group" "this" {
  count = var.create ? 1 : 0

  name             = var.name
  path             = var.path
  description      = var.description
  visibility_level = var.visibility_level
  parent_id        = var.parent_id
}
