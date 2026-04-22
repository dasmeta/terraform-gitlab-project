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
  dynamic environments with end-to-end confidence second, and broader GitLab
  platform capability plus DevEx third.
- Rationale: This sequencing matches the clarified user priorities and creates a
  dependency-aware path where developer experience improvements build on a
  standardized repository baseline.
- Alternatives considered:
  - Treat all tracks as equal priority: rejected because it weakens execution
    order and makes `TODO.md` less actionable.
  - Put Kubernetes first: rejected because the user framed repository
    standardization and review-app DevEx as stronger immediate priorities.

## Decision 4: Move reusable GitLab platform capability in scope and keep only
client-specific or one-off operational work out of scope

- Decision: Treat runner lifecycle, monitoring, and reusable performance testing
  via pipeline as in-scope GitLab platform capability, while keeping only
  client-specific planning and one-off operational incident remediation out of
  scope.
- Rationale: The refined epic now includes runners, agents, monitoring, and
  related GitLab delivery observability as core capability. The ownership
  boundary is no longer "operational versus roadmap"; it is "reusable GitLab
  delivery capability versus client-specific or ad hoc work."
- Alternatives considered:
  - Keep runners and monitoring separate from the roadmap: rejected because it
    conflicts with the refined epic scope.
  - Pull all operational items into scope: rejected because client-specific
    planning and one-off incident remediation do not create reusable GitLab
    capability.

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
