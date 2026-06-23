# Quickstart: Parameterized Dynamic Environment CI

```hcl
dynamic_environments_project = {
  enabled = true
  name    = "dynamic-environments"

  ci_config = {
    deploy_image               = "alpine/k8s:1.30.3"
    cleanup_image              = "alpine/k8s:1.30.3"
    migration_job_name         = "database-migration"
    migration_timeout          = "900s"
    aws_access_key_id_variable = "AWS_ACCESS_KEY_ID"
  }

  e2e_config = {
    enabled = true
    project = "platform/e2e-tests"
    branch  = "main"
    variables = {
      APP_BASE_URL = "https://app-$DYNAMIC_ENV_HOST"
      CUSTOM_WS_URL = "wss://app-$DYNAMIC_ENV_HOST/ws"
      DATABASE_URL = "$DYNAMIC_DATABASE_URL"
    }
    rules = [{
      if   = "$CI_PIPELINE_SOURCE == \"schedule\""
      when = "manual"
    }]
  }
}
```

Verification:

```shell
terraform fmt -check -recursive
terraform -chdir=modules/dynamic_environment test
terraform validate
terraform -chdir=examples/basic validate
```
