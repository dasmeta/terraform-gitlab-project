variable "renovate_token" {
  type        = string
  default     = null
  description = "GitLab token forwarded to the worker to create its Kubernetes Secret. Supply through TF_VAR_renovate_token."
  sensitive   = true
}
