# Quickstart: Deduplicated Module Improvement Roadmap

## Purpose

Use repo-root `TODO.md` as the primary actionable roadmap and the spec
directory as the supporting design package that explains scope boundaries,
priority order, and follow-up classification rules.

## Steps

1. Read [TODO.md](/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/TODO.md) first to see the three major improvement tracks and the explicit out-of-scope boundary.
2. Read [spec.md](/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/002-module-improvement-roadmap/spec.md) to understand why the tracks are ordered that way and where scope boundaries sit.
3. Read [research.md](/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/002-module-improvement-roadmap/research.md) to see the decisions behind the root backlog artifact, the broader GitLab-management framing, and the in-scope versus out-of-scope split.
4. Read [data-model.md](/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/002-module-improvement-roadmap/data-model.md) before turning any roadmap idea into a new spec or issue.
5. Use [roadmap-classification.md](/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-gitlab-project/specs/002-module-improvement-roadmap/contracts/roadmap-classification.md) as the required structure when classifying a follow-up backlog item.

## Review Checks

- Confirm `TODO.md` still lists the top three tracks in this order:
  service repository standardization, dynamic environments with end-to-end
  confidence, GitLab platform capability and DevEx.
- Confirm runners, monitoring, and related GitLab platform capability remain
  inside the third track rather than being separated from the core roadmap.
- Confirm client-specific and one-off operational work are still explicit
  out-of-scope items.
- Confirm any follow-up item still fits the broader GitLab-management roadmap
  and does not silently widen the runtime module interface.
- Confirm later implementation work identifies affected docs, examples, tests,
  and automation artifacts before coding starts.

## Suggested Verification Commands

```bash
sed -n '1,260p' TODO.md
sed -n '1,320p' specs/002-module-improvement-roadmap/spec.md
sed -n '1,260p' specs/002-module-improvement-roadmap/plan.md
sed -n '1,260p' specs/002-module-improvement-roadmap/research.md
sed -n '1,260p' specs/002-module-improvement-roadmap/data-model.md
sed -n '1,260p' specs/002-module-improvement-roadmap/quickstart.md
sed -n '1,260p' specs/002-module-improvement-roadmap/contracts/roadmap-classification.md
sed -n '1,420p' specs/002-module-improvement-roadmap/tasks.md
rg -n "service repository|dynamic environments|GitLab platform|client-specific" TODO.md specs/002-module-improvement-roadmap
```
