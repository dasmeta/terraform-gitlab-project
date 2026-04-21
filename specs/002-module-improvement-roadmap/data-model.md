# Data Model: Deduplicated Module Improvement Roadmap

## BacklogArtifact

- Purpose: Represent the published roadmap surface maintainers interact with.
- Fields:
  - `path`: `TODO.md` for the primary artifact, or a supporting spec path.
  - `role`: Primary backlog or supporting design context.
  - `owner`: Maintainers responsible for keeping it aligned.
  - `alignment_rule`: Statement describing how it must stay consistent with the
    other roadmap artifacts.
- Relationships:
  - Contains one or more `ImprovementTheme` records.
  - References the source `ScopeDecision` records captured in the supporting
    specification.

## ImprovementTheme

- Purpose: Group related Jira ideas into one prioritized GitLab-management work
  stream.
- Fields:
  - `name`: Stable theme label.
  - `priority`: First, second, third, or out-of-scope.
  - `intent`: Plain-language description of the goal.
  - `scope_boundary`: Statement of what belongs inside the theme and what does
    not.
  - `backlog_section`: Corresponding section in `TODO.md`.
- Relationships:
  - Contains one or more `RoadmapItem` records.
  - Belongs to one `BacklogArtifact`.
  - References one or more `ScopeDecision` records.

## RoadmapItem

- Purpose: Represent one deduplicated improvement outcome that can later become
  a feature spec, plan, ADR, or issue.
- Fields:
  - `title`: Short backlog item name.
  - `source_ideas`: One or more original Jira lines that feed the item.
  - `consumer_impact`: Summary of how the change would affect maintainers or
    downstream GitLab consumers.
  - `artifact_impact`: Required supporting updates when the item is eventually
    implemented.
  - `approval_needed`: Whether later explicit approval is required.
  - `status`: Prioritized, out-of-scope, or approval-required.
- Relationships:
  - Belongs to one `ImprovementTheme`.
  - May require one `ScopeDecision`.
  - May reference one `VerificationExpectation`.

## ScopeDecision

- Purpose: Record the ownership decision for a Jira idea or roadmap item.
- Fields:
  - `classification`: In-scope, duplicate, out-of-scope, or approval-required.
  - `reason`: Why the classification was chosen.
  - `follow_up_owner`: Module maintainers, platform team, or future discovery.
  - `approval_reference`: Link or note when clarification-approved expansion is
    required.
- Relationships:
  - Can apply to one or many `RoadmapItem` records.

## DeliveryPhase

- Purpose: Sequence the roadmap into manageable slices.
- Fields:
  - `name`: Phase 1, Phase 2, or Phase 3.
  - `goal`: Outcome expected from the phase.
  - `entry_criteria`: What must already be true before the phase starts.
  - `exit_criteria`: What must be produced before the phase is considered ready.
- Relationships:
  - Contains one or more `ImprovementTheme` records.

## VerificationExpectation

- Purpose: Capture the minimum evidence needed before a roadmap item or backlog
  artifact is treated as ready.
- Fields:
  - `review_type`: Traceability review, ordering review, or scope review.
  - `commands_or_checks`: Commands or manual checks to run.
  - `pass_condition`: Evidence that the item or artifact is ready to advance.
- Relationships:
  - Applies to one `RoadmapItem`, one `ImprovementTheme`, or one
    `BacklogArtifact`.
