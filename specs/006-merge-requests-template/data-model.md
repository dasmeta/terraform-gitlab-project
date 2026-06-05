# Data Model: Merge Requests Template Support

## Project Configuration

- **Purpose**: Defines one GitLab project and consumer-controlled project
  settings.
- **New Field**:
  - `merge_requests_template`: optional string containing the default merge
    request description template for the GitLab project.
- **Validation Rules**:
  - The field is optional.
  - Omission must preserve current behavior.
  - The module does not parse or rewrite the string content.
- **Relationships**:
  - Root `gitlab_projects[]` entries are normalized for namespace resolution.
  - Normalized project objects are passed to `module.project`.
  - `module.project` maps the optional field to `gitlab_project.this`.

## GitLab Project Resource Mapping

- **Purpose**: Maps consumer project configuration to provider arguments.
- **New Mapping**:
  - `merge_requests_template = try(each.value.merge_requests_template, null)`
- **Validation Rules**:
  - No child-module object type duplication is needed because the root module
    owns the object schema and validation.
  - Null/omitted values must not force an empty template.
