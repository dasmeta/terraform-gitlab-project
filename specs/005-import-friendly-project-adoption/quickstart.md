# Quickstart: Import-Friendly Project Adoption

## Implementation Steps

1. Add optional project adoption fields to root `gitlab_projects` object typing
   in `variables.tf`.
2. Add `branch_protections_enabled` as an optional project flag that defaults to
   true.
3. Forward adoption fields from the root module into the child project resource
   in `modules/project/main.tf`.
4. Guard generated default branch protections in `modules/project/locals.tf`
   with the per-project opt-out flag.
5. Make root project validation tolerate omitted `group_key` for direct
   `namespace_id` workflows.
6. Remove token-like example placeholders from touched example content.

## Verification Steps

From `/Users/juliaaghamyan/Desktop/dasmeta/terraform-gitlab-project`:

```bash
terraform init -input=false
terraform validate
```

From `/Users/juliaaghamyan/Desktop/corify/workspace_module/gitlab_repos`:

```bash
terraform init -input=false
terraform validate
terraform plan -input=false -out=/tmp/gitlab_repos_dasmeta_local.tfplan
```

Expected consumer plan summary:

```text
Plan: 58 to import, 0 to add, 0 to change, 0 to destroy.
```

Expected warning:

```text
approvals_before_merge is deprecated
```

The warning is acceptable for this feature because the field is used only for
provider-18.x import compatibility.
