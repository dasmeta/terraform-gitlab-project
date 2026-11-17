# Integrated root usage

The root example deploys one shared worker and proposes `renovate.json` through
an MR for the enabled project. The allowlist is derived from GitLab's actual
path_with_namespace; renovate.repositories adds separately managed repositories.
Use a group/project already managed in this stack, or import it before applying.

`terraform init -backend=false` and `terraform validate` verify the example.
GitLab provider authenticates through GITLAB_TOKEN. The MR helper uses the same
environment token (or GITLAB_API_TOKEN); Python 3 is required on the Terraform
runner. Helm requires the intended kubeconfig. The existing Secret must supply
RENOVATE_TOKEN and optional registry host rules. Values are never stored here.

For config-only use, omit renovate.install. For a separately deployed worker,
pass the root renovate_repositories output as its explicit allowlist.

The included custom JSONata manager demonstrates Terraform module source/version
in Terramate YAML. It does not claim to cover arbitrary nested chart/image keys:
add extraction queries for the actual source structure and verify with dry-run.
Ignore generated terramate/_terraform/** so regeneration does not erase updates.

## YAML DSL shape

Your generator must support nested module variables and Helm provider config.
Keep the existing module version until a release containing this feature exists;
then update the version to that release. Do not apply these fields to 1.4.1.

```yaml
source: dasmeta/project/gitlab
# version: use the release containing Renovate support
variables:
  renovate:
    install:
      enabled: true
      namespace: renovate
      existing_secret: renovate-credentials
      dry_run: true
  gitlab_projects:
    - name: infrastructure
      namespace_id: 12345
      default_branch: main
      renovate:
        enabled: true
        ignore_paths:
          - terramate/_terraform/**
providers:
  - name: gitlab
    source: gitlabhq/gitlab
    version: '~> 19.0'
  - name: helm
    source: hashicorp/helm
    version: '~> 3.0'
    variables:
      kubernetes:
        config_path: ~/.kube/config
```

For separate installation, use source
`dasmeta/project/gitlab//modules/renovate` in a separate YAML stack, with
`variables.repositories` and `variables.install`. Leave root installation
omitted so only one stack owns the worker.
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

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
