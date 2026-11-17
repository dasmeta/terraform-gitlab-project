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
    dry_run          = optional(bool, true)
    resources = optional(object({
      requests = optional(map(string), { cpu = "100m", memory = "512Mi" })
      limits   = optional(map(string), { memory = "2Gi" })
    }), {})
  })
  default     = {}
  description = "Optional shared Renovate installation. Credentials come only from an existing Secret. dry_run defaults true."
  validation {
    condition     = !var.install.enabled || trimspace(var.install.existing_secret) != ""
    error_message = "Enabled installation requires install.existing_secret containing RENOVATE_TOKEN."
  }
  validation {
    condition     = alltrue([for value in [var.install.release_name, var.install.namespace, var.install.chart_version, var.install.time_zone] : trimspace(value) != ""]) && length(regexall("[^\\s]+", var.install.schedule)) == 5
    error_message = "Release, namespace, chart version and time zone must be nonempty; schedule must have five cron fields."
  }
}
