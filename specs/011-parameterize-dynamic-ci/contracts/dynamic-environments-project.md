# `dynamic_environments_project` CI Contract

```hcl
dynamic_environments_project = {
  ci_config = {
    deploy_image                   = optional(string)
    cleanup_image                  = optional(string)
    placeholder_image              = optional(string)
    alpine_packages                = optional(list(string))
    python_packages                = optional(list(string))
    migration_job_name             = optional(string)
    migration_timeout              = optional(string)
    aws_access_key_id_variable     = optional(string)
    aws_secret_access_key_variable = optional(string)
  }

  e2e_config = {
    enabled   = optional(bool)
    project   = optional(string)
    branch    = optional(string)
    strategy  = optional(string)
    variables = optional(map(string))
    rules = optional(list(object({
      if   = string
      when = optional(string)
    })))
  }
}
```

When E2E is disabled, no E2E job is generated. When enabled, `project` must be a
non-empty string. Variables are merged over the standard E2E variables and
rules are appended to the standard rule list.
