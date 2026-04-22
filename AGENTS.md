# terraform-gitlab-project Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-10

## Active Technologies
- HCL/Terraform module repository with Markdown planning artifacts; Terraform CLI version is repository-managed rather than declared in `version.tf` + `gitlabhq/gitlab >= 18.8.2`, `pre-commit`, `pre-commit-terraform`, Node-based repository automation (002-module-improvement-roadmap)

- Terraform module repository (HCL) with YAML, JSON, shell, and Node-based repository automation; Terraform CLI is used, but `version.tf` does not declare a `required_version` + `gitlabhq/gitlab >= 18.8.2`, `pre-commit`, `pre-commit-terraform`, reusable GitHub Actions workflows, `@commitlint/*`, `semantic-release` (001-align-repo-configs)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Terraform module repository (HCL) with YAML, JSON, shell, and Node-based repository automation; Terraform CLI is used, but `version.tf` does not declare a `required_version`

## Code Style

Terraform module repository (HCL) with YAML, JSON, shell, and Node-based repository automation; Terraform CLI is used, but `version.tf` does not declare a `required_version`: Follow standard conventions

## Recent Changes
- 002-module-improvement-roadmap: Added HCL/Terraform module repository with Markdown planning artifacts; Terraform CLI version is repository-managed rather than declared in `version.tf` + `gitlabhq/gitlab >= 18.8.2`, `pre-commit`, `pre-commit-terraform`, Node-based repository automation

- 001-align-repo-configs: Added Terraform module repository (HCL) with YAML, JSON, shell, and Node-based repository automation; Terraform CLI is used, but `version.tf` does not declare a `required_version` + `gitlabhq/gitlab >= 18.8.2`, `pre-commit`, `pre-commit-terraform`, reusable GitHub Actions workflows, `@commitlint/*`, `semantic-release`

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
