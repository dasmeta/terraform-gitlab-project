# Research

- Use chart 46.440.2 (app 44.247.2), verified live 2026-11-17. Upstream implements
  CronJob and top-level existingSecret imported with envFrom. Alternative custom
  manifests duplicate upstream logic.
  https://github.com/renovatebot/helm-charts/releases/tag/renovate-46.440.2
- Explicit repositories, autodiscover=false, onboarding=false and
  requireConfig=required avoid duplicate onboarding proposals. dryRun="full"
  performs remote read-only verification. force.automerge=false and
  force.platformAutomerge=false preserve manual merging.
  https://docs.renovatebot.com/self-hosted-configuration/
- Existing Secret contains RENOVATE_TOKEN and optionally RENOVATE_HOST_RULES.
  Actual runs require bot Developer membership and api scope; no token values
  enter Terraform. https://docs.renovatebot.com/modules/platform/gitlab/
- Standard managers cover Helm/Docker/Terraform; source YAML DSL needs custom
  regex or JSONata extraction, and generated terramate/_terraform must be ignored.
  https://docs.renovatebot.com/modules/manager/jsonata/
- Separate Helm-only deployment avoids requiring GitLab on standalone users.
  Installed GitLab 19.0 schema has no MR resource; use tested Python API helper
  following existing repository convention, never token command-line arguments.
