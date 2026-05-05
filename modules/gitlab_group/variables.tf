variable "create" {
  type        = bool
  description = "When true, create one Terraform-managed GitLab group. Existing-group references are resolved in the root module and do not instantiate this child module."
  default     = false
}

variable "name" {
  type        = string
  description = "Group display name (required when create is true)."
  default     = ""
}

variable "path" {
  type        = string
  description = "Group URL path / slug (required when create is true)."
  default     = ""
}

variable "description" {
  type        = string
  description = "Group description."
  default     = ""
}

variable "visibility_level" {
  type        = string
  description = "private | internal | public"
  default     = "private"
}

variable "parent_id" {
  type        = number
  description = "Optional parent group id for a managed subgroup."
  default     = null
  nullable    = true
}
