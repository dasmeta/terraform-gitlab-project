# Shared Renovate worker

Helm-only wrapper around the [upstream Renovate chart](https://github.com/renovatebot/helm-charts).
Installs one CronJob, pinned to chart 46.440.2, with overlapping runs forbidden.
Requires Kubernetes 1.27+ for CronJob time zones. Schedules use numeric five-field
cron with wildcards, lists, ranges and positive steps; named days/months and macros
are intentionally outside this bounded interface.
Deployment defaults disabled; enabling requires an explicit repository allowlist
and an existing Secret in the release namespace. See
[standalone example](../../examples/renovate).

Credentials are supplied by Secret environment keys RENOVATE_TOKEN and optionally
RENOVATE_HOST_RULES. Manage values outside Terraform. Bot needs GitLab Developer
membership and api scope for normal runs; registry access is configured through
host rules. The Helm provider is configured by the caller; no GitLab provider is
required. Root usage can derive the same repository allowlist from project opt-in.

Starts with full dry-run enabled; set install.dry_run=false to enable writes.
Bot requires merged repository configuration and does not create onboarding MRs.
Global forced automerge=false/platformAutomerge=false keep reviews manual.

Inspect runs with `kubectl -n renovate get cronjobs,jobs` and the corresponding
Job logs. Run an immediate check with
`kubectl -n renovate create job --from=cronjob/renovate renovate-check-001`.
The manual job inherits current dry-run policy; only run it after reviewing that
policy. Suspend with install.suspend=true to stop new scheduled runs; running
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
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.17.0 |

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
| <a name="input_install"></a> [install](#input\_install) | Optional shared Renovate installation. Credentials come only from an existing Secret. dry\_run defaults true. | <pre>object({<br/>    enabled          = optional(bool, false)<br/>    release_name     = optional(string, "renovate")<br/>    namespace        = optional(string, "renovate")<br/>    create_namespace = optional(bool, true)<br/>    existing_secret  = optional(string, "")<br/>    chart_version    = optional(string, "46.440.2")<br/>    schedule         = optional(string, "0 */6 * * *")<br/>    time_zone        = optional(string, "Etc/UTC")<br/>    suspend          = optional(bool, false)<br/>    dry_run          = optional(bool, true)<br/>    resources = optional(object({<br/>      requests = optional(map(string), { cpu = "100m", memory = "512Mi" })<br/>      limits   = optional(map(string), { memory = "2Gi" })<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Explicit GitLab repository paths; autodiscovery is disabled. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_config"></a> [global\_config](#output\_global\_config) | Nonsecret worker configuration, also usable for validation. |
| <a name="output_installation"></a> [installation](#output\_installation) | Nonsecret installation coordinates, or null when disabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
