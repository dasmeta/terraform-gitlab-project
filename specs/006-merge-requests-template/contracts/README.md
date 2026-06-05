# Contract: Merge Requests Template Support

This feature changes the Terraform module consumer contract.

## Input Contract

`gitlab_projects[]` accepts a new optional string field:

```hcl
merge_requests_template = optional(string)
```

Consumers may use it as:

```hcl
gitlab_projects = [
  {
    name                    = "example"
    group_key               = "example_group"
    merge_requests_template = "Describe the change, validation, and rollout notes."
  }
]
```

## Behavior Contract

- When `merge_requests_template` is set, the module forwards the value to the
  GitLab project resource.
- When omitted, the module does not force a value and preserves existing
  behavior.
- The module does not validate, parse, or transform template content beyond
  Terraform type checking.

## Non-Goals

- No unrelated GitLab project settings are added.
- No project template file resources are managed by this ticket.
- No provider version change is planned unless validation proves it necessary.
