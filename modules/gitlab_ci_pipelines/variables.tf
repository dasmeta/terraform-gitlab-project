variable "gitlab_projects" {
  type        = any
  description = "Same normalized shape as the root module variable gitlab_projects, including gitlab_ci_pipelines entries."

  validation {
    condition = alltrue(flatten([
      for project in var.gitlab_projects : [
        for pipeline in try(project.gitlab_ci_pipelines, []) :
        try(pipeline.type, null) != "deploy_agent" ? true : (
          length(try(pipeline.jobs, [])) > 0 ? alltrue([
            for job in try(pipeline.jobs, []) :
            !coalesce(try(job.stop_environment.enabled, null), try(pipeline.stop_environment.enabled, null), false) || (
              try(length(trimspace(job.variables.deploy_environment_name)) > 0, false) &&
              try(length(trimspace(job.variables.deploy_environment_kubernetes_agent)) > 0, false) &&
              try(length(trimspace(job.variables.kube_namespace)) > 0, false) &&
              try(length(trimspace(job.variables.helm_release)) > 0, false)
            )
            ]) : (
            !coalesce(try(pipeline.stop_environment.enabled, null), false) || (
              try(length(trimspace(pipeline.variables.deploy_environment_name)) > 0, false) &&
              try(length(trimspace(pipeline.variables.deploy_environment_kubernetes_agent)) > 0, false) &&
              try(length(trimspace(pipeline.variables.kube_namespace)) > 0, false) &&
              try(length(trimspace(pipeline.variables.helm_release)) > 0, false)
            )
          )
        )
      ]
    ]))
    error_message = "When deploy_agent stop_environment.enabled is true, each affected job must set deploy_environment_name, deploy_environment_kubernetes_agent, kube_namespace, and helm_release in variables."
  }
}

variable "project_ids" {
  type        = map(number)
  description = "Map of project name to GitLab project ID (from modules/project)."
}
