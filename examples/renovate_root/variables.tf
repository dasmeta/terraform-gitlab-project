variable "renovate_token" {
  type        = string
  default     = null
  description = "GitLab token forwarded through the root module to create the worker Secret. Supply through TF_VAR_renovate_token."
  sensitive   = true
}
