output "repository_file_paths" {
  description = "Exact generated CI file paths indexed by project name, for coordination with other repository automation."
  value = {
    for project in var.gitlab_projects : project.name => distinct([
      for file in values(local.ci_pipeline_files) : file.file_path if file.project_name == project.name
    ])
  }
}
