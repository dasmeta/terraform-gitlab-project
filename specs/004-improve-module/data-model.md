# Data Model: Improve Module Quality

## Overview

This feature does not introduce new persistent resources. It clarifies the
existing consumer data model that already drives the Terraform module and
identifies the validation and resolution rules that implementation must keep
consistent.

## Entities

### Project Configuration

- **Purpose**: Defines one GitLab project and the consumer-controlled settings
  that the module applies to it.
- **Key fields**:
  - `name`: unique project identifier within the module input
  - `description`
  - `namespace_id`
  - `group_key`
  - `default_branch`
  - `visibility_level`
  - `initialize_with_readme`
  - `request_access_enabled`
  - `lfs_enabled`
  - `packages_enabled`
  - `squash_option`
  - `merge_method`
  - `only_allow_merge_if_pipeline_succeeds`
  - `only_allow_merge_if_all_discussions_are_resolved`
  - `remove_source_branch_after_merge`
  - `ci_pipeline_variables_minimum_override_role`
  - `pages_access_level`
  - `branch_protections`
  - `approval_rule`
  - `push_rules`
  - `env_variables`
- **Relationships**:
  - May reference one **Group Configuration** through `group_key`
  - Produces one or more **Project Variable Assignment** records after global
    and project-level variable merging
- **Validation rules**:
  - Must be supplied as a list of project objects
  - Must provide `namespace_id` when no groups are supplied
  - Must provide either `namespace_id` or `group_key` when multiple groups are
    supplied
  - Must use an allowed override role value
- **Resolution rules**:
  - `namespace_id` wins when explicitly set
  - Otherwise, when groups exist, the module resolves the project namespace
    from `group_key` or falls back to the first group entry when only one
    group exists
  - Default project behavior is owned by variable definitions rather than
    embedded `locals.tf` defaults before child-module consumption

### Group Configuration

- **Purpose**: Describes either a GitLab group to create or an existing group
  to reference for project placement.
- **Key fields**:
  - `key`
  - `create`
  - `name`
  - `path`
  - `description`
  - `visibility_level`
  - `parent_id`
  - `existing_group_id`
- **Relationships**:
  - Can be referenced by many **Project Configuration** records through
    `group_key`
- **Validation rules**:
  - Every group `key` must be unique
  - `name` and `path` are required when `create = true`
- **Resolution rules**:
  - When `create = false`, `existing_group_id` may seed namespace resolution
  - When `create = true`, the created module output provides the namespace id
    used by downstream project resolution

### Variable Definition

- **Purpose**: Represents one CI/CD variable declared either globally or at
  the project level.
- **Key fields**:
  - `key`
  - `value`
  - `masked`
  - `protected`
- **Relationships**:
  - A set of global definitions can apply to many **Project Configuration**
    records
  - Project-level definitions can override global definitions with the same
    key for one project
- **Validation rules**:
  - Definitions must remain keyed by unique variable name within the effective
    merged set per project
- **Resolution rules**:
  - Global variables are loaded first
  - Project-level variables with the same key override the global definition
    for that project

### Project Variable Assignment

- **Purpose**: Effective per-project variable record produced after merge and
  used to create the final GitLab project variable resource.
- **Key fields**:
  - `project_name`
  - `key`
  - `env`
- **Relationships**:
  - Derived from one **Project Configuration**
  - Derived from zero or more **Variable Definition** records
- **State transitions**:
  - Declared in input
  - Merged into effective per-project variable set
  - Applied as a project variable resource when projects are enabled

## Cross-Entity Rules

- The root module is the authoritative place for consumer-facing validation of
  project and group object shape.
- Child modules should rely on the normalized data passed from the root module
  rather than redefine the full consumer contract.
- Documentation, examples, and validation must describe the same resolution
  rules for namespace selection and variable precedence.
- Default project settings must have one authoritative declaration path in
  variable definitions instead of split ownership across variables and locals.
