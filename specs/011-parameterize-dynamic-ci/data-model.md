# Data Model: Parameterize Dynamic Environment CI

## CI configuration

- `deploy_image`: image for dynamic deployment jobs
- `cleanup_image`: image for cleanup jobs
- `placeholder_image`: image for merge-request placeholder jobs
- `alpine_packages`: packages installed before deployment
- `python_packages`: Python packages installed before deployment
- `migration_job_name`: Kubernetes migration job to delete and await
- `migration_timeout`: kubectl wait duration
- `aws_access_key_id_variable`: GitLab variable name containing the access key
- `aws_secret_access_key_variable`: GitLab variable name containing the secret

All fields are optional and have compatibility defaults. Variable-name fields,
image fields, migration job name, and timeout must be non-empty.

## E2E configuration

- `enabled`: whether the downstream trigger job is emitted
- `project`: downstream GitLab project path; required when enabled
- `branch`: downstream branch
- `strategy`: GitLab trigger strategy
- `variables`: arbitrary string overrides merged over standard E2E variables
- `rules`: additional rules appended to the standard five E2E rules

When enabled, project and branch are also rendered as global `E2E_PROJECT` and
`E2E_BRANCH` variables. The trigger references those variable names.

## Central pipeline document

The final document merges mandatory deploy, placeholder, and cleanup jobs with
the optional E2E job, then serializes the result to YAML.
