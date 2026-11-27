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
The API endpoint must match the project's URL returned by the configured GitLab
provider and, when set, GITLAB_BASE_URL. These checks run before reading the
helper token; HTTP redirects are rejected. For self-managed GitLab, set endpoint
to that server's API URL rather than leaving the GitLab.com default.
For JSONC/JSON5 syntax install Python's optional json5 package in that runner.
The proposal serializes those documents as JSON with two-space indentation and
a trailing newline, preserving their settings and path. This also applies to
embedded package.json configurations. Comments and original whitespace are not
retained. Formatting itself uses the existing Python 3 runtime locally per
repository. Discovery follows
[Renovate's GitLab file precedence](https://github.com/renovatebot/renovate/blob/44.247.2/lib/config/app-strings.ts);
custom worker `configFileNames` are outside this module's interface.
Malformed formats or existing literal credentials fail before configuration writes;
move credentials to the bot's existing Secret instead of Terraform state.

Generated descriptions contain a versioned ownership record for only the fields
Terraform changed. On later runs, prior generated additions are removed before
new defaults are merged, preserving distinct manual additions. This lets shared
presets, custom managers and generated-path exclusions be removed as well as added.
Do not edit/delete the ownership record by hand; malformed records fail safely.

Each proposal uses source_branch as a prefix plus a hash of the desired content,
the original raw file hash, its path and the target branch. Source edits, including formatting-only
changes, get a fresh branch from the exact target commit inspected during
discovery. A new plan after a rejected stale plan can therefore recover even
when the generated JSON is identical. Merging a proposal can also change this
snapshot revision once. Unrelated target commits keep the same revision when
the source bytes/path and desired content are unchanged. Every discovery request
uses the captured commit SHA.

Before publishing, the helper checks the current active config path and exact
original document bytes against the plan, including the whole package.json for
embedded configurations. If either changed, apply fails with a request for a new
plan before writing. The pinned branch baseline also protects changes made after
that check through Git's merge ancestry. Source-file updates use last_commit_id
to reject concurrent changes. Manual edits to a proposal file are not overwritten.

Terraform owns proposal branches; a helper publishes files only when their bytes
differ. Existing open MRs are reused. An identical already-merged config returns
success before attempting any write, including after a deleted source branch is
recreated. Deleting an unmerged source branch reruns publication. New revisions
replace old proposal branches.

Publication content is materialized during apply by hashicorp/local (~>2.5), with
0600 file and 0700 directory permissions under path.root/.terraform/renovate.
The create-time helper runs on that local_file after it is written, receiving
only the file path and checksum in its environment. Large embedded package.json
documents therefore do not enter exec argv/environment. The payload checksum is
verified before API requests. The local_file is replaced whenever its
null_resource publication marker is replaced, ensuring that retries, script
changes and branch recreation materialize the payload before publishing.
Run terraform init when upgrading to install the new provider. Existing proposal
branches are replaced once to adopt snapshot-aware names. These local artifacts
are disposable; a new plan detects missing files and recreates them on apply.

This submodule requires Terraform 1.7 or newer. Upgrading from the native
gitlab_repository_file implementation automatically forgets its legacy state
instances using a removed block with destroy = false: remote files are retained.
Review the plan's "no longer managed" actions; no manual state removal is needed.
File-only drift on an existing proposal is checked when publication runs; it is
not continuously reconciled by a gitlab_repository_file resource.

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
and null/local resources and override remote repository reads; the local JSON
formatter runs normally. Python tests use fixtures/local fake HTTP and isolated
Terraform plans/local-file applies in temporary directories. Those resource
tests use offline installed providers and skip when prerequisites are absent.
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | ~> 19.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.2 |
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | 19.5.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_branch.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/branch) | resource |
| [local_file.proposal](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.merge_request](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.existing](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.formatted](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [gitlab_project.authority](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | GitLab API endpoint for configuration discovery and merge requests. Must match the configured GitLab provider's project URL and GITLAB\_BASE\_URL when set. | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_gitlab_projects"></a> [gitlab\_projects](#input\_gitlab\_projects) | Projects whose Renovate configuration should be proposed through merge requests. | <pre>list(object({<br/>    name           = string<br/>    default_branch = optional(string, "main")<br/>    renovate = optional(object({<br/>      enabled             = optional(bool, false)<br/>      source_branch       = optional(string, "terraform/renovate")<br/>      merge_request_title = optional(string, "chore: configure Renovate")<br/>      extends             = optional(list(string), ["config:recommended"])<br/>      include_paths       = optional(list(string), [])<br/>      ignore_paths        = optional(list(string), [])<br/>      custom_managers = optional(list(object({<br/>        custom_type           = optional(string, "regex")<br/>        manager_file_patterns = list(string)<br/>        match_strings         = list(string)<br/>        file_format           = optional(string)<br/>        datasource_template   = optional(string)<br/>        dep_name_template     = optional(string)<br/>        package_name_template = optional(string)<br/>        versioning_template   = optional(string)<br/>        registry_url_template = optional(string)<br/>      })), [])<br/>    }), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_managed_file_paths"></a> [managed\_file\_paths](#input\_managed\_file\_paths) | Exact Terraform-owned repository paths, indexed by project name, protected from updates through anchored file rules. Protecting a lockfile also disables updates that would change it. | `map(list(string))` | `{}` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Managed project IDs indexed by gitlab\_projects[].name. | `map(string)` | `{}` | no |
| <a name="input_repository_defaults"></a> [repository\_defaults](#input\_repository\_defaults) | Shared presets, path rules and custom format extractors inherited by all opted-in repositories. | <pre>object({<br/>    extends       = optional(list(string), [])<br/>    include_paths = optional(list(string), [])<br/>    ignore_paths  = optional(list(string), [])<br/>    custom_managers = optional(list(object({<br/>      custom_type           = optional(string, "regex")<br/>      manager_file_patterns = list(string)<br/>      match_strings         = list(string)<br/>      file_format           = optional(string)<br/>      datasource_template   = optional(string)<br/>      dep_name_template     = optional(string)<br/>      package_name_template = optional(string)<br/>      versioning_template   = optional(string)<br/>      registry_url_template = optional(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configurations"></a> [configurations](#output\_configurations) | Generated nonsecret Renovate repository configurations indexed by project name. |
| <a name="output_source_branches"></a> [source\_branches](#output\_source\_branches) | Snapshot-revision proposal branches derived from desired content, original source hash, file path and target branch, created from the captured target commit. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
