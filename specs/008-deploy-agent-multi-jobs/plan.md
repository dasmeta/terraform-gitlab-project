# Implementation Plan: Deploy Agent Multi-Job Pipeline

**Branch**: `006-merge-requests-template` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## Summary

Extend each generated pipeline entry with an optional list of jobs. Normalize either the new multi-job shape or the legacy single-job fields into one internal jobs list, then render one shared include followed by all normalized jobs.

## Technical Context

**Terraform Runtime**: `>= 1.3`  
**Primary Provider Constraints**: unchanged  
**Module Scope**: root input schema and `modules/gitlab_ci_pipelines`  
**Testing Strategy**: Terraform tests with mock providers, static schema/default/renderer checks, `terraform fmt -check`, and `git diff --check`  
**Constraints**: preserve legacy single-job behavior; approved default-path change for `deploy_agent`

## Constitution Check

- Scope check: Pass; limited to generated reusable CI pipeline behavior.
- Wrapper check: Pass; adds a narrow jobs list instead of exposing arbitrary YAML.
- Approval check: Pass; user approved the default-path breaking change.
- File coverage check: Pass; schema, generator, example, and docs are included.
- Provider/version check: Pass; no provider changes.
- Verification check: Check schema, normalization, output structure, formatting, and diff.

## Project Structure

```text
variables.tf
modules/gitlab_ci_pipelines/main.tf
modules/gitlab_ci_pipelines/tests/multi_job.tftest.hcl
modules/gitlab_ci_pipelines/README.md
examples/basic/main.tf
README.md
```

**Structure Decision**: Normalize new and legacy inputs into `jobs`, then use one renderer for all jobs.
