# Renovate configuration for a repository fleet

Use only `gitlab_projects[].renovate.enabled = true` for ordinary projects.
The same generated base allows all native Renovate managers to discover their
standard files; no repository names, stack profiles, enabledManagers list or
broad Kubernetes/Helm file matching is embedded in the module.

Ordinary updates are grouped dynamically by Renovate manager using
`{{manager}} dependencies`; there is no manager list, repository-name mapping or
depCount threshold. Updates are separated into major, minor and patch groups
within each manager. For example, 100 ordinary Dockerfile updates create at most
three branch/MR groups, and Python/npm each have their own type groups when
present. A single update uses the same grouping scheme. Multiple target major
and minor streams stay together within each type. Grouping spans files from the
same manager. Native MR titles identify the type with (major), (minor) or (patch).
Renovate's replacement and lockfile-maintenance updates keep their special handling.

The generic rule precedes existing inline repository packageRules, which can
override grouping. It overrides grouping inherited from extends presets, including
built-in monorepo groups. Generated-file protection and forced manual merge still take priority.
No grouping setting enables automerge or creates updates for dependencies whose
versions cannot be resolved.

Root `renovate.defaults` supplies presets, ignore/include paths and custom
format extractors once for all opted-in projects. The standalone repository
module calls this `repository_defaults`. Per-project overrides remain optional.
Presets resolve in this order: recommended base (when selected), shared defaults,
existing presets, then explicit project presets. Later presets take precedence.
Ignore paths and custom managers combine with existing policy; nonempty project
include paths replace existing/shared include paths, otherwise existing paths
take priority over shared defaults.
Nonstandard source YAML still needs an explicit shared extraction rule; the
module does not infer chart/registry semantics or decrypt SOPS files.
Native Helm values discovery matches `values.yaml`/`values.yml`; files such as
`values-dev.yaml` need a shared preset or explicit format extractor.

Root automatically protects the exact paths exported by its CI generator,
dynamic-environment service generator and GitLab Agent configuration. A manually
owned file in the same directory stays eligible, including nested or suffixed
lookalikes. Anchored file rules disable updates to generated files; extraction
may still report their dependencies. Standalone callers can supply
`managed_file_paths`; protecting a lockfile also disables manifest updates that
would change that lockfile. Shared/manual `ignore_paths` retain Renovate's normal
substring/glob semantics; default dependency-directory exclusions are preserved.

## Existing configurations and repeated updates

A read-only external data source discovers the active GitLab Renovate config.
It preserves existing schedule, labels, manager restrictions and package rules,
including configs under .gitlab, .renovaterc files and package.json's renovate
field. It does not create a second root config when another supported file exists.
Python 3 and GITLAB_TOKEN (or GITLAB_API_TOKEN) are needed during plan and apply.
For JSONC/JSON5 syntax install Python's optional json5 package in that runner.
The proposal serializes those documents as JSON with two-space indentation and
a trailing newline, preserving their settings and path. This also applies to
embedded package.json configurations. Comments and original whitespace are not
retained. Formatting runs locally per repository using the existing Python 3
runtime; it needs no additional provider or package. Discovery follows
[Renovate's GitLab file precedence](https://github.com/renovatebot/renovate/blob/44.247.2/lib/config/app-strings.ts);
custom worker `configFileNames` are outside this module's interface.
Malformed formats or existing literal credentials fail before configuration writes;
move credentials to the bot's existing Secret instead of Terraform state.

Generated descriptions contain a versioned ownership record for only the fields
Terraform changed. On later runs, prior generated additions are removed before
new defaults are merged, preserving distinct manual additions. This lets shared
presets, custom managers and generated-path exclusions be removed as well as added.
Do not edit/delete the ownership record by hand; malformed records fail safely.

Each effective config revision uses source_branch as a prefix plus a file-content hash.
Changed file bytes, including formatting changes, get a fresh branch from the
target, avoiding stale squash-merge ancestry. Unchanged files keep the same
revision. Terraform owns proposal
branches/files; configure MR source-branch retention. New revisions replace the
old proposal resources. Existing open MRs for the same branch are reused and an
identical already-merged file does not create an empty proposal.

Automerge is disabled at top level and by a final universal package rule, including
lock-file maintenance. The paired worker additionally forces manual merging.
Existing repository CI and approvals remain authoritative. No default branch is
written directly; review and merge the proposed configuration first.

`configurations` exposes effective Renovate settings; `source_branches` exposes
actual revision branches. Disabling opt-in removes proposal resources and the
root-derived allowlist entry, not the already merged default-branch config.

## Local verification

Run `terraform init -backend=false`, `terraform test`, and
`python3 -m unittest discover -s tests -p '*_test.py'`. Terraform tests mock GitLab
and null resources and override remote repository reads; the local JSON formatter
runs normally. Python tests use fixtures/local fake HTTP only.
No Git add, commit, push or live installation is part of these commands.

For an offline check against the chart's Renovate version (44.247.2), install
that version in a temporary directory and use its supported Node runtime:

```sh
terraform test -json -verbose > /tmp/renovate-tests.jsonl
node tests/verify_renovate.mjs /path/to/node_modules/renovate /tmp/renovate-tests.jsonl
node tests/verify_grouping.mjs /path/to/node_modules/renovate /tmp/renovate-tests.jsonl
python3 tests/verify_extraction.py --node /path/to/supported/node \
  --renovate-dir /path/to/node_modules/renovate --test-log /tmp/renovate-tests.jsonl
```

This checks actual file-rule matching, conflicting preset precedence and shared
extraction policy reuse across 125 differently named repositories.
The grouping check uses the pinned Renovate branch planner with 1/2/100 synthetic
updates per manager/type, Docker-only repositories, inherited preset
slugs, explicit repository overrides and protected generated paths.
The extraction check runs the CLI on two temporary fixture repositories with
the same generated policy and checks native and custom dependencies. It uses
local platform and extract-only dry-run without inherited bot/cloud credentials.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | ~> 19.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.2 |
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | 19.5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [gitlab_repository_file.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [null_resource.merge_request](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.existing](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.formatted](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | GitLab API endpoint for configuration merge requests. | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Projects whose Renovate configuration should be proposed through merge requests. | <pre>list(object({<br/>    name           = string<br/>    default_branch = optional(string, "main")<br/>    renovate = optional(object({<br/>      enabled             = optional(bool, false)<br/>      source_branch       = optional(string, "terraform/renovate")<br/>      merge_request_title = optional(string, "chore: configure Renovate")<br/>      extends             = optional(list(string), ["config:recommended"])<br/>      include_paths       = optional(list(string), [])<br/>      ignore_paths        = optional(list(string), [])<br/>      custom_managers = optional(list(object({<br/>        custom_type           = optional(string, "regex")<br/>        manager_file_patterns = list(string)<br/>        match_strings         = list(string)<br/>        file_format           = optional(string)<br/>        datasource_template   = optional(string)<br/>        dep_name_template     = optional(string)<br/>        package_name_template = optional(string)<br/>        versioning_template   = optional(string)<br/>        registry_url_template = optional(string)<br/>      })), [])<br/>    }), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_managed_file_paths"></a> [managed\_file\_paths](#input\_managed\_file\_paths) | Exact Terraform-owned repository paths, indexed by project name, protected from updates through anchored file rules. Protecting a lockfile also disables updates that would change it. | `map(list(string))` | `{}` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Managed project IDs indexed by gitlab\_projects[].name. | `map(string)` | `{}` | no |
| <a name="input_repository_defaults"></a> [repository\_defaults](#input\_repository\_defaults) | Shared presets, path rules and custom format extractors inherited by all opted-in repositories. | <pre>object({<br/>    extends       = optional(list(string), [])<br/>    include_paths = optional(list(string), [])<br/>    ignore_paths  = optional(list(string), [])<br/>    custom_managers = optional(list(object({<br/>      custom_type           = optional(string, "regex")<br/>      manager_file_patterns = list(string)<br/>      match_strings         = list(string)<br/>      file_format           = optional(string)<br/>      datasource_template   = optional(string)<br/>      dep_name_template     = optional(string)<br/>      package_name_template = optional(string)<br/>      versioning_template   = optional(string)<br/>      registry_url_template = optional(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configurations"></a> [configurations](#output\_configurations) | Generated nonsecret Renovate repository configurations indexed by project name. |
| <a name="output_source_branches"></a> [source\_branches](#output\_source\_branches) | Content-revision branches holding configuration proposals, created from the current target for each policy revision. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
