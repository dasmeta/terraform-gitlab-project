variable "create" {
  type        = bool
  description = "When true, create one GitLab group. When false, no resources are created and outputs are null."
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
  description = "Optional parent group id for a subgroup."
  default     = null
  nullable    = true
}
