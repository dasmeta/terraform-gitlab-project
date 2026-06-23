# Implementation Plan: Deploy Job Rules

**Branch**: `006-merge-requests-template` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## Summary

Extend normalized generated jobs with ordered rule objects and render supported GitLab CI rule attributes after job variables.

## Technical Context

**Terraform Runtime**: `>= 1.3`  
**Provider Constraints**: unchanged  
**Testing Strategy**: Terraform mock-provider tests plus validation and formatting  
**Scope**: root job schema, CI pipeline renderer, example, and docs

## Constitution Check

- Scope: Pass; narrow generated CI enhancement.
- Wrapper: Pass; typed common rule fields instead of arbitrary YAML.
- Approval: Pass; additive and backward compatible.
- Provider/version: Pass; no changes.
- Verification: Extend executable Terraform tests and run root/example validation.
