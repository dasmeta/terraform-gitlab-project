# Verification: Renovate

Date: 2026-11-17. No live GitLab/Kubernetes resources were created.

## Automated checks

| Check | Version / scope | Result |
| --- | --- | --- |
| terraform test | worker, Terraform 1.7.0 / Helm 3.3.0 | 8 passed |
| terraform test | repository config, Terraform 1.7.0 / GitLab 19.5.0 | 4 passed |
| terraform test | root, Terraform 1.9.8 / GitLab 19.0.0 / Helm 3.2.0 | 4 passed |
| terraform test | existing dynamic_environment, Terraform 1.17.1 | 2 passed |
| terraform test | existing gitlab_ci_pipelines, Terraform 1.17.1 | 10 passed |
| terraform test | existing project, Terraform 1.17.1 | 4 passed |
| Python unittest | MR lifecycle fake HTTP server | 7 passed |
| terraform validate | root, both new modules and both new examples | passed |
| terraform fmt -check -recursive | repository | passed |
| git diff --check | changed files | passed |
| pre-commit run --files | all 45 changed files | all hooks passed |
| helm template | chart 46.440.2 with actual module-generated values | passed |
| helm template suspend=true | generated CronJob.spec.suspend | true |
| renovate-config-validator --strict --no-global | actual repository config, Renovate 44.247.2 | passed |
| renovate-config-validator --strict | actual global config, Renovate 44.247.2 | passed |

Standalone Helm 2.17.0 compatibility was also checked using a temporary copy
with an exact provider constraint; worker contract tests passed. The Terraform
1.7.0 and 1.9.8 executables were downloaded from HashiCorp releases and SHA256
verified without replacing the system executable.

Existing root code already contains cross-variable validations unavailable in
Terraform 1.3-1.8; the declared >=1.3 bound is a pre-existing limitation, not a
new promise of support. Root CI now explicitly uses 1.9.8. Two existing null
validation defects exposed by that test were fixed in this change.

The npm installation's optional native RE2 binding was unavailable, so Renovate
reported a fallback to JavaScript RegExp. Configuration validation succeeded;
local extraction below succeeded under supported Node 24.11.1. This does not
replace verification inside the pinned deployment image.

## Dependency extraction evidence

Ran Renovate 44.247.2 with Node 24.11.1 in local platform, dry-run=extract,
against fixtures copied to a temporary directory with the actual generated
repository config. All credential-related environment variables were removed.
No GitLab bot token or cluster access was used.

| File | Manager | Dependency | Current version |
| --- | --- | --- | --- |
| Dockerfile | dockerfile | alpine | 3.20.0 |
| values-dev.yaml | helm-values | nginx | 1.26.0 |
| Chart.yaml | helmv3 | base | 0.3.15 |
| terramate/module.yaml | custom JSONata | dasmeta/project/gitlab | 1.4.1 |

The process exited 0; extracted dependency names and current versions were
programmatically asserted against all four expected tuples. Fixtures live in
modules/renovate_repository/tests/fixtures. This proves the generic manager
contract, not coverage of every client's nested YAML key.

## Review corrections

Independent review found and rechecked two issues: comparison of exact config
hashes avoids duplicate MRs even after squash merges; numeric cron ranges and
step syntax are validated before installation. Tests cover missing target
config, existing open MR, duplicate-create race, identical post-merge config,
API authentication failure, invalid ranges/weekdays/steps and dry-run/write mode.

## Pending client rollout

- Choose kubecontext/namespace and identify or provision the existing Secret.
- Release the module and update the consumer version/source.
- Enable the chosen repositories in the account YAML, preserving unrelated work.
- Review the configuration MR, inspect real full dry-run/registry lookup logs,
  enable writes, and verify a representative dependency MR and existing CI.
- Keep Jira In Progress until actual rollout evidence and review transition are
  explicitly approved. No live deployment success or completed ticket is claimed.
