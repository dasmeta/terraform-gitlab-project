# Implementation Plan: Shared Renovate

**Branch**: `DMVP-10881` | **Date**: 2026-11-17 | **Spec**: [spec.md](spec.md)

## Summary

Add Helm-only `modules/renovate` plus `modules/renovate_repository` for reviewed
configuration proposals. Root composes both independently and derives opted-in
repository paths. Existing callers retain disabled defaults.

## Technical Context

- Declared Terraform >=1.3; new submodule tests verified on 1.7.0. Existing
  root cross-variable validations require 1.9+, so root CI uses verified 1.9.8;
  local CLI is 1.17.1. No runtime constraint is widened in this feature.
- Existing providers: gitlabhq/gitlab ~>19.0, hashicorp/null ~>3.2,
  hashicorp/helm >=2.17.0. No root constraint changes; use common Helm arguments.
- Upstream chart 46.440.2 at oci://ghcr.io/renovatebot/charts.
- GitLab 19.0 provider schema has no MR creation resource: use existing
  null_resource/local-exec convention with a tested Python API helper.
- Scope: reusable module implementation and generic YAML examples; actual
  client installation requires released source, selected cluster and Secret.

## Constitution Check

- Scope and interface widening: explicitly approved in conversation; user
  requested standalone/root installation plus project opt-in and said start.
- Wrapper: upstream chart, typed grouped inputs, no arbitrary Helm values or
  raw Renovate JSON passthrough. Existing requiredness preserved.
- Modern capabilities: supported CronJob chart and Secret references; native MR
  resource unavailable at minimum provider, bounded API helper fallback.
- Coverage: root renovate.tf/variables.tf/outputs.tf; two submodules; examples;
  READMEs; tests; Terraform test CI matrix. No unrelated refactoring.
- Speckit evidence: spec/plan/tasks before source changes; scripts use
  SPECIFY_FEATURE=012-renovate to retain actual Jira branch DMVP-10881.
- Verification: terraform fmt -check -recursive; init -backend=false and validate
  at root/new modules/examples; terraform test in all existing/new test modules;
  Python MR helper tests; helm template pinned chart; config validator.

## Project Structure

- modules/renovate/{main,variables,locals,outputs,versions}.tf and tests/
- modules/renovate_repository/{main,variables,locals,outputs,versions}.tf,
  scripts/ensure_merge_request.py and tests/
- renovate.tf, variables.tf, outputs.tf, tests/renovate.tftest.hcl
- examples/renovate, examples/renovate_root; READMEs and CI matrix

## Delivery Boundary

Mock tests must not invoke live local-exec, GitLab writes or Kubernetes changes.
Live rollout requires selected kubecontext, Secret and released module. Record
actual dry-run, dependency MR and CI evidence separately before Jira closeout.

Root CI exposed two existing null-unsafe validation expressions (optional E2E
project and pipeline retention); guard these values so default callers pass
with Terraform 1.9 as well as 1.17. This is covered by root default-input tests.
