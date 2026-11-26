# Fleet-wide root usage

Enable ordinary projects with `renovate: { enabled: true }`. Renovate discovers
native dependencies itself. Declare shared presets/extractors only once in
`renovate.defaults`; per-project configuration is optional. No repository-name
condition or per-stack profile is required.

The local example uses the root module from `../..`. Use imported/already-managed
GitLab projects, or allow initialization for a new project so a target branch
exists. Configure the intended Helm provider if installing the optional worker.
This example forwards the sensitive root `renovate_token` input from
TF_VAR_renovate_token. The chart creates `renovate-secret` in namespace `renovate`.
Alternatively omit that input and set renovate.install.existing_secret to a
pre-created Secret containing RENOVATE_TOKEN and optional registry rules.
The token is stored in Terraform state and Helm release values; sensitive hides
normal CLI output only. Do not store the token in committed YAML or tfvars.
The Terraform runner needs Python 3 and GitLab environment authentication even
for plan, to read and preserve existing repository configuration.

The example's one shared JSONata manager illustrates source/version pairs in
Terramate YAML. Nested Helm chart fields require an extractor for that schema;
unknown YAML is not guessed. SOPS files should not be updated without a matching
secret-management workflow. Generated source/output ownership must be respected.

## Account YAML shape (after a release, or your local source override)

```yaml
source: dasmeta/project/gitlab
# Set the released version containing this feature, or use the local module source.
variables:
  renovate:
    defaults:
      ignore_paths:
        - terramate/_terraform/**
      # extends/custom_managers can be shared across the whole fleet here.
    install:
      enabled: true
      existing_secret: renovate-credentials
  gitlab_projects:
    - name: service-one
      namespace_id: 12345
      renovate:
        enabled: true
    - name: service-two
      namespace_id: 12345
      renovate:
        enabled: true
```

The YAML above intentionally uses an existing Secret. The installed DSL renderer
emits literal module arguments and does not declare/forward shell inputs.
Setting TF_VAR_renovate_token alone in a generated stack does not pass it into
module.this. Use a Terraform caller that declares and forwards the input (as in
main.tf) for managed credentials; never paste the token into source YAML.

Keep the existing group/CI/approval definitions alongside these opt-ins. The root
uses actual generator outputs to exclude its owned CI paths, including customized
file names, while retaining manually owned CI. Existing Renovate configuration
is merged rather than reset. Identical generated policies have stable proposal
revisions; subsequent changes branch from the current target.

For config-only use omit renovate.install; for independent worker installation
use modules/renovate and pass the root renovate_repositories output explicitly.
The local example runs normally when enabled and can create update branches and
MRs once repository configuration is merged. Validate configuration and registry
access before rollout; automerge remains disabled.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | ~> 19.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_renovate_token"></a> [renovate\_token](#input\_renovate\_token) | GitLab token forwarded through the root module to create the worker Secret. Supply through TF\_VAR\_renovate\_token. | `string` | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
