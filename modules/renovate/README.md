# Shared Renovate worker

Helm-only wrapper around the [upstream Renovate chart](https://github.com/renovatebot/helm-charts).
Installs one CronJob, pinned to chart 46.440.2, with overlapping runs forbidden.
This self-hosted Helm worker is the supported runtime. CI-based bot execution,
hosted bot/app installation and bot membership in GitLab projects are not
provisioned by this wrapper.
Requires Kubernetes 1.27+ for CronJob time zones. Schedules use numeric five-field
cron with wildcards, lists, ranges and positive steps; named days/months and macros
are intentionally outside this bounded interface.
Deployment defaults disabled; enabling requires either `renovate_token` or an
existing Secret in the release namespace. Repositories use an explicit allowlist
with autodiscovery disabled. An empty allowlist keeps the release installed,
updates its configuration to `repositories=[]`, and forces the CronJob suspended,
even when `install.suspend=false`. Adding repositories honors `install.suspend`
again. `installation.suspend` reports this effective suspension state. See
[standalone example](../../examples/renovate).

Pass a sensitive `renovate_token` to let the upstream chart create
`<release_name>-secret` containing RENOVATE_TOKEN and connect it to the CronJob.
Namespace defaults to `renovate`; Helm creates it when create_namespace=true.
For the default release the Secret is `renovate-secret`. Supplying a token alone
does not enable installation. For example, in a Terraform caller:

```hcl
variable "renovate_token" {
  type      = string
  sensitive = true
}

module "renovate" {
  source         = "dasmeta/project/gitlab//modules/renovate"
  # Pin the released version containing managed token support.
  repositories   = ["example/platform"]
  renovate_token = var.renovate_token
  install        = { enabled = true }
}
```

Supply the caller variable through TF_VAR_renovate_token (or a protected variable
store). Terraform does not automatically forward an environment variable into a
child module; the caller must declare and pass it as shown. `sensitive` hides
CLI values, but the token is stored in Terraform state and Helm release values.
Do not commit token values to YAML, HCL or tfvars files. Rotating the input updates
the chart Secret; newly started Jobs use the updated token.

The token is passed using Helm set_sensitive so the provider also redacts it
from release metadata. The release resource uses Terraform JSON syntax to
support the different set_sensitive schemas in both Helm 2 and Helm 3.

Alternatively omit renovate_token and set install.existing_secret to reference
a Secret in the same namespace containing RENOVATE_TOKEN and optional
RENOVATE_HOST_RULES JSON for private registries. Exactly one credential source
is required for enabled installation. Bot needs GitLab Developer
membership and api scope for normal runs; registry access is configured through
host rules. The Helm provider is configured by the caller; no GitLab provider is
required. Root usage can derive the same repository allowlist from project opt-in.

When switching credential modes, use a separately named existing Secret.
Pointing existing_secret to the chart's own managed Secret makes Helm remove it
on upgrade. Switching to managed mode can also require reconciling ownership if
a Secret with the generated name already exists.

Enabled installations with repositories can create dependency branches and MRs.
The module no longer exposes an install.dry_run setting or configures dryRun.
Remove the retired setting from older YAML/HCL callers before applying updates.
Bot requires merged repository configuration and does not create onboarding MRs.
Global forced automerge=false/platformAutomerge=false keep reviews manual.

The worker defaults to prHourlyLimit=0, so new MRs are not limited to two per
hour. This does not change Renovate's concurrent MR/branch limits or grouping.
Explicit repository configuration may override this default with its own hourly
limit; it is not a forced setting. Apply the worker change to enable it; updating
repository renovate.json files is not required.

Inspect runs with `kubectl -n renovate get cronjobs,jobs` and the corresponding
Job logs. Run an immediate check with
`kubectl -n renovate create job --from=cronjob/renovate renovate-check-001`.
Manual jobs can create branches and MRs using the current repository allowlist.
Suspend with install.suspend=true to stop new scheduled runs; running
Jobs are unaffected. Avoid running manual checks concurrently with scheduled jobs.

Verify locally with `terraform init -backend=false`, `terraform validate`, and
`terraform test` (mocked Helm provider; no cluster contact).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | GitLab API endpoint used by the bot. | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_install"></a> [install](#input\_install) | Optional shared Renovate installation. Use renovate\_token to create a Secret or install.existing\_secret to reference one. Namespace defaults to renovate. Enabled workers can create update branches and merge requests. | <pre>object({<br/>    enabled          = optional(bool, false)<br/>    release_name     = optional(string, "renovate")<br/>    namespace        = optional(string, "renovate")<br/>    create_namespace = optional(bool, true)<br/>    existing_secret  = optional(string, "")<br/>    chart_version    = optional(string, "46.440.2")<br/>    schedule         = optional(string, "0 */6 * * *")<br/>    time_zone        = optional(string, "Etc/UTC")<br/>    suspend          = optional(bool, false)<br/>    resources = optional(object({<br/>      requests = optional(map(string), { cpu = "100m", memory = "512Mi" })<br/>      limits   = optional(map(string), { memory = "2Gi" })<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_renovate_token"></a> [renovate\_token](#input\_renovate\_token) | Optional GitLab token. When supplied, the chart creates a Kubernetes Secret. Stored in Terraform state and Helm release values; mutually exclusive with install.existing\_secret. | `string` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Explicit GitLab repository paths; autodiscovery is disabled. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_config"></a> [global\_config](#output\_global\_config) | Nonsecret worker configuration, also usable for validation. |
| <a name="output_installation"></a> [installation](#output\_installation) | Nonsecret installation coordinates and effective suspension state, or null when disabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
