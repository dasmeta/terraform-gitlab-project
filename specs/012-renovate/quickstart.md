# Rollout

1. Run local mocked verification and validate generated config/chart rendering.
2. Provision bot membership and existing Secret using current secret management.
3. Propose repository config through per-project renovate.enabled, inspect
   coverage/CI/existing config and merge the configuration MR.
4. Deploy shared worker in full dry-run mode with an explicit allowlist.
5. Configure extraction on source YAML and ignore generated output; verify
   dependency names/current versions in logs before allowing writes.
6. Set dry_run=false, review a dependency MR and its existing CI/GitOps checks.
7. Rollback by suspending CronJob; keep automerge disabled.

Client YAML, actual installation, registry access, run logs and dependency MR/CI
are rollout evidence, separate from local module tests.
