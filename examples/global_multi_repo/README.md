# Global multi-repo example (file-based config)

Creates many GitLab projects (e.g. 30) with:

- **Global env variables** — same variables on every project (e.g. `NPM_TOKEN`, `GITLAB_TOKEN`).
- **Global pipeline and semantic-release** — same `.gitlab-ci.yml` and `.releaserc.json` in every repo, loaded from **files** under `templates/` (no inline content in Terraform).

## Usage

1. Copy or symlink the module, then from this directory:

   ```bash
   terraform init
   ```

2. Set tokens (e.g. via env or tfvars):

   ```bash
   export TF_VAR_gitlab_token="glpat-..."
   export TF_VAR_npm_token="..."
   ```

3. Optionally override repo list in `repo_names` (default: 30 names `my-app-01` … `my-app-30`).

4. Apply:

   ```bash
   terraform plan
   terraform apply
   ```

## Files

- `templates/.gitlab-ci.yml` — pipeline used for all repos.
- `templates/.releaserc.json` — semantic-release config used for all repos.
- Edit these files to change CI/release for every repo at once.

## Repository automation note

This example manages GitLab CI and semantic-release files for downstream GitLab
projects. The current repository's own validation, commit-policy, and release
automation lives under `.github/workflows/` and is separate from these managed
template files.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.9.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab_repos"></a> [gitlab\_repos](#module\_gitlab\_repos) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
