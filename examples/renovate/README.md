# Standalone Renovate worker

Install one shared worker without GitLab project management. Configure Helm 3
with a kubeconfig for the intended cluster and provide an existing Secret named
`renovate-credentials` in namespace `renovate`. The Secret supplies RENOVATE_TOKEN
and optional RENOVATE_HOST_RULES JSON for private chart/container registries.
Provision it through your existing secret-management system; do not put token
values in Terraform variables, chart values or committed YAML.

`terraform init -backend=false` and `terraform validate` validate this example.
Review a real plan in your deployment stack before applying. The example starts
in full dry-run mode; set dry_run=false only after inspecting extracted versions
and registry lookup results. CronJob schedule is in Etc/UTC.

Each repository must have a reviewed Renovate config on its default branch.
Pass paths explicitly here; the deployment submodule does not discover projects.
Use the root module per-project opt-in independently to propose those configs.

For registry use after release, source becomes
`dasmeta/project/gitlab//modules/renovate` with an explicit released version.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_renovate"></a> [renovate](#module\_renovate) | ../../modules/renovate | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_installation"></a> [installation](#output\_installation) | Shared worker installation coordinates. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
