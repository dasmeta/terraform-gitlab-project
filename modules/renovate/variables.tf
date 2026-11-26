variable "repositories" {
  type        = list(string)
  default     = []
  description = "Explicit GitLab repository paths; autodiscovery is disabled."
  validation {
    condition     = alltrue([for path in var.repositories : can(regex("^[^/\\s]+/[^\\s]+$", path))])
    error_message = "repositories must contain namespace/project paths without whitespace."
  }
}

variable "endpoint" {
  type        = string
  default     = "https://gitlab.com/api/v4"
  description = "GitLab API endpoint used by the bot."
  validation {
    condition     = can(regex("^https?://", var.endpoint))
    error_message = "endpoint must be an HTTP(S) GitLab API URL."
  }
}

variable "renovate_token" {
  type        = string
  default     = null
  description = "Optional GitLab token. When supplied, the chart creates a Kubernetes Secret. Stored in Terraform state and Helm release values; mutually exclusive with install.existing_secret."
  sensitive   = true
  validation {
    condition     = var.renovate_token == null ? true : trimspace(var.renovate_token) != ""
    error_message = "renovate_token must be null or a nonempty token."
  }
}

variable "install" {
  type = object({
    enabled          = optional(bool, false)
    release_name     = optional(string, "renovate")
    namespace        = optional(string, "renovate")
    create_namespace = optional(bool, true)
    existing_secret  = optional(string, "")
    chart_version    = optional(string, "46.440.2")
    schedule         = optional(string, "0 */6 * * *")
    time_zone        = optional(string, "Etc/UTC")
    suspend          = optional(bool, false)
    resources = optional(object({
      requests = optional(map(string), { cpu = "100m", memory = "512Mi" })
      limits   = optional(map(string), { memory = "2Gi" })
    }), {})
  })
  default     = {}
  description = "Optional shared Renovate installation. Use renovate_token to create a Secret or install.existing_secret to reference one. Namespace defaults to renovate. Enabled workers can create update branches and merge requests."
  validation {
    condition     = alltrue([for value in [var.install.release_name, var.install.namespace, var.install.chart_version, var.install.time_zone] : trimspace(value) != ""]) && length(regexall("[^\\s]+", var.install.schedule)) == 5
    error_message = "Release, namespace, chart version and time zone must be nonempty; schedule must have five cron fields."
  }
}
