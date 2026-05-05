# basic

This example demonstrates the supported multi-group workflow:

- each project resolves its namespace through an explicit `group_key`
- each group is in managed-group mode with `create = true`
- project-level `env_variables` can replace a shared variable definition by
  reusing the same key
- field-level defaults and behavioral notes are documented inline in the root
  `variables.tf` schema rather than in a detached shared prose block

Use this example when you want multiple repositories spread across multiple
GitLab groups. If you have exactly one group, the root module also supports the
implicit single-group fallback described in the root README.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.8.2 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab"></a> [gitlab](#output\_gitlab) | All outputs from the terraform-gitlab-project module (gitlab\_group\_ids, gitlab\_project\_ids, …). |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
