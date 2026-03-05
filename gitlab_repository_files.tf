# Global files applied to every project; per-project repository_files override same file_path
locals {
  # Per-project file map: project_name => { file_path => file_spec }
  # Global first, then project repository_files override
  project_file_map = {
    for p in var.gitlab_projects : p.name => merge(
      { for f in var.global_repository_files : f.file_path => f },
      { for f in lookup(p, "repository_files", []) : f.file_path => f }
    )
  }

  project_repository_files = {
    for item in flatten([
      for pname, files in local.project_file_map : [
        for fpath, file in files : {
          project_name = pname
          file_path    = fpath
          file         = file
        }
      ]
    ]) : "${item.project_name}:${item.file_path}" => item
  }
}

resource "gitlab_repository_file" "project_files" {
  for_each = local.project_repository_files

  project        = gitlab_project.this[each.value.project_name].id
  file_path      = each.value.file_path
  encoding       = "text"
  branch         = try(each.value.file.branch, "main")
  content        = try(each.value.file.content_file, null) != null && try(each.value.file.content_file, "") != "" ? file(each.value.file.content_file) : each.value.file.content
  commit_message = try(each.value.file.commit_message, "Managed by Terraform")
  author_name    = try(each.value.file.author_name, null)
  author_email   = try(each.value.file.author_email, null)

  overwrite_on_create = true
}
