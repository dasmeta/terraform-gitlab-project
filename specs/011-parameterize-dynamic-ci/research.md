# Research: Parameterize Dynamic Environment CI

## Decision: Encode the complete pipeline with Terraform

- **Decision**: Construct the GitLab CI document as Terraform maps/lists and
  serialize it with `yamlencode`.
- **Rationale**: Removes split ownership between Terraform defaults and template
  logic while guaranteeing valid YAML serialization.
- **Alternatives considered**: Passing more values into the existing template
  leaves control flow duplicated; accepting raw CI maps broadens the wrapper
  interface too far.

## Decision: Disable E2E unless explicitly configured

- **Decision**: Default `e2e_config.enabled` to `false` and require `project`
  when enabled.
- **Rationale**: There is no valid universal downstream project. Emitting
  `example/e2e-tests` creates a predictably broken pipeline.
- **Alternatives considered**: Preserve the placeholder or make project
  required for all consumers; both harm default usability.

## Decision: Keep only generic E2E defaults in the module

- **Decision**: Keep only `E2E_DYNAMIC_STACK` as a module default. Application,
  WebSocket, and database URLs must be supplied through `e2e_config.variables`.
- **Rationale**: URL and database values are environment-specific and do not
  belong in reusable module defaults.
- **Alternatives considered**: Require consumers to repeat the full map or use a
  raw CI object; both make the wrapper harder to use.

## Decision: Reference project and branch through global variables

- **Decision**: Add `E2E_PROJECT` and `E2E_BRANCH` to global CI variables when
  E2E is enabled and reference them from the trigger.
- **Rationale**: Matches the existing `GITLAB_AGENT_PATH` and
  `DYNAMIC_NAMESPACE` variable-reference pattern.
- **Alternatives considered**: Put literal configured values directly in the
  trigger; this makes the generated trigger inconsistent with the rest of CI.
