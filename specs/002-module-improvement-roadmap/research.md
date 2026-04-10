# Research: Deduplicated Module Improvement Roadmap

## Decision 1: Make repo-root `TODO.md` the primary backlog artifact

- Decision: Use repo-root `TODO.md` as the primary actionable deliverable and
  keep the `specs/002-module-improvement-roadmap/` files as supporting design
  context.
- Rationale: The user explicitly requested a root-level todo list, and the
  roadmap is only useful if maintainers can see the prioritized backlog without
  opening the spec directory first.
- Alternatives considered:
  - Keep only spec-kit artifacts: rejected because it would not satisfy the
    requested output format.
  - Replace all spec artifacts with only `TODO.md`: rejected because the
    supporting docs still provide traceability, classification rules, and
    planning context.

## Decision 2: Broaden roadmap ownership to GitLab-related management

- Decision: Treat the roadmap as planning for broader GitLab-related
  management, not only project lifecycle management.
- Rationale: The user clarified that the repository name is probably too
  narrow, and the main improvements now extend into service repository
  standardization, dynamic environments, and GitLab DevEx capabilities.
- Alternatives considered:
  - Keep the roadmap project-only: rejected because it would conflict with the
    explicit clarification and leave the main priorities misclassified.
  - Split the roadmap immediately into separate repositories: rejected because
    the current feature is only organizing backlog direction, not deciding final
    repo extraction work.

## Decision 3: Prioritize three explicit roadmap tracks

- Decision: Order the backlog as service repository standardization first,
  dynamic environments with end-to-end confidence second, and Kubernetes or
  broader GitLab DevEx integration third.
- Rationale: This sequencing matches the clarified user priorities and creates a
  dependency-aware path where developer experience improvements build on a
  standardized repository baseline.
- Alternatives considered:
  - Treat all tracks as equal priority: rejected because it weakens execution
    order and makes `TODO.md` less actionable.
  - Put Kubernetes first: rejected because the user framed repository
    standardization and review-app DevEx as stronger immediate priorities.

## Decision 4: Keep operational work visible but separate

- Decision: Maintain an adjacent operational track for runner lifecycle,
  monitoring, connection issues, client-specific planning, and performance
  operations unless a later feature narrows them to GitLab-managed repository
  wiring.
- Rationale: The broader roadmap still needs ownership boundaries. Keeping these
  items visible but separate reduces scope drift while preserving source
  traceability.
- Alternatives considered:
  - Fold operational work into the third DevEx track: rejected because it
    blurs ownership and delivery focus.
  - Drop adjacent items from the roadmap entirely: rejected because source
    traceability matters.

## Decision 5: Record roadmap-level scope expansion as approved exception

- Decision: Treat the broader GitLab-management framing as a justified,
  clarification-approved roadmap exception rather than an unresolved gate
  failure.
- Rationale: The constitution requires explicit approval for scope expansion.
  The user provided that approval during clarification on 2026-04-10, so the
  plan can proceed while still flagging that later runtime interface widening
  needs separate approval.
- Alternatives considered:
  - Block planning until a separate approval artifact exists: rejected because
    the user has already given explicit direction in the conversation.
