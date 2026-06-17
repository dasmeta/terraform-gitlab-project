# Research: Merge Requests Template Support

## Decision: Add one optional root project field

**Decision**: Add `merge_requests_template = optional(string)` to the root
`gitlab_projects` object type.

**Rationale**: The root input owns the documented consumer contract. The
repository already exposes related project-level template fields, so one
additional optional string preserves the existing interface style and keeps
existing consumers compatible.

**Alternatives considered**:

- Use `any` at the root. Rejected because the root module currently validates
  and documents the project object shape.
- Add a grouped `merge_request_settings` object. Rejected for this ticket
  because it would change the established flat field pattern and risk broader
  interface churn.

## Decision: Forward through the existing normalized project object

**Decision**: Read the optional value in `modules/project/main.tf` with
`try(each.value.merge_requests_template, null)` and assign it to
`gitlab_project.this.merge_requests_template`.

**Rationale**: Root `locals.tf` forwards project objects after namespace
resolution, and the child project module intentionally uses `any` to avoid
duplicating the full root object type. This approach keeps the change narrow
and mirrors current optional template mappings.

**Alternatives considered**:

- Add explicit local normalization for the new field. Rejected because no
  derived value or validation is needed.
- Duplicate the full project object type in the child module. Rejected because
  existing child-module guidance says validation and normalization happen at
  the root.

## Decision: Use the GitLab provider 19.x major range

**Decision**: Use `gitlabhq/gitlab ~> 19.0` and Terraform `>= 1.3`.

**Rationale**: The module should start at GitLab provider 19.0.0 and accept
future 19.x minor and patch releases such as 19.1.0, 19.1.1, and 19.2.0 without
automatically crossing into the next major version. `~> 19.0` is the compact
Terraform constraint syntax for that 19.x range. The Terraform Registry
documentation for `gitlabhq/gitlab` lists `merge_requests_template` on
`gitlab_project` as the project setting for new merge request templates.

**Alternatives considered**:

- Use only `>= 19.0.0`. Rejected because it would also allow a future 20.x
  provider release, which may include breaking changes.

## Decision: Use example validation rather than a new test harness

**Decision**: Update `examples/basic` and validate the root module plus the
basic example.

**Rationale**: The repository currently relies on Terraform validation and
example coverage for this interface surface. The requested change is a narrow
optional field and does not require new runtime infrastructure.

**Alternatives considered**:

- Add a new dedicated fixture. Acceptable if validation gaps appear, but the
  existing basic example is enough to prove the consumer input shape and
  project module wiring for this feature.

## Verification Result: Provider startup blocks local validation

**Decision**: Treat local `terraform validate` failures as an environment
blocker unless validation can be rerun where the cached GitLab provider binary
can start successfully.

**Rationale**: Both root and `examples/basic` validation fail before HCL schema
checking with `Failed to load plugin schemas` and `Failed to read any lines
from plugin's stdout` for the cached `gitlabhq/gitlab` provider binary. The
error occurs before Terraform can evaluate whether the new argument is valid.

**Alternatives considered**:

- Change provider constraints. Rejected because the failure happens during
  provider process startup and not because Terraform reported an unsupported
  argument.
