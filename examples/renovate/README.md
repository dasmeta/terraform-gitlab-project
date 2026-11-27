# Standalone Renovate worker

Install one shared worker without GitLab project management. Configure Helm 3
with a kubeconfig for the intended cluster. The example declares and forwards a
sensitive `renovate_token` input. Supply it through `TF_VAR_renovate_token`, e.g.
`export TF_VAR_renovate_token="$RENOVATE_TOKEN"` when the GitLab token is already
loaded in your shell. The chart creates `renovate-secret` in namespace `renovate`
and the CronJob reads RENOVATE_TOKEN from it. No pre-created Secret is required.

The token is hidden in normal Terraform output but stored in Terraform state
and Helm release values. Do not commit it to YAML, HCL or tfvars files.
To use an existing Secret instead, remove the renovate_token argument and add
install.existing_secret="renovate-credentials". It must contain RENOVATE_TOKEN
and can also contain RENOVATE_HOST_RULES for private registries.

`terraform init -backend=false` and `terraform validate` validate this example.
Review a real plan in your deployment stack before applying. Enabled workers run
normally and can create update branches and MRs once repository configuration is
merged. CronJob schedule is in Etc/UTC; automerge remains disabled.

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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_renovate_token"></a> [renovate\_token](#input\_renovate\_token) | GitLab token forwarded to the worker to create its Kubernetes Secret. Supply through TF\_VAR\_renovate\_token. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_installation"></a> [installation](#output\_installation) | Shared worker installation coordinates. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
