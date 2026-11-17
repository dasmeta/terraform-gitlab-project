provider "gitlab" {}

provider "helm" {
  kubernetes = { config_path = "~/.kube/config" }
}

module "gitlab" {
  source = "../.."

  gitlab_groups = [{ key = "platform", existing_group_id = 12345 }]
  gitlab_projects = [{
    name           = "infrastructure"
    group_key      = "platform"
    default_branch = "main"
    renovate = {
      enabled      = true
      ignore_paths = ["terramate/_terraform/**"]
      custom_managers = [{
        custom_type           = "jsonata"
        file_format           = "yaml"
        manager_file_patterns = ["/terramate/.*\\.ya?ml$/"]
        match_strings         = ["{\"depName\": source, \"currentValue\": version, \"datasource\": \"terraform-module\"}"]
      }]
    }
  }]

  renovate = {
    install = {
      enabled         = true
      existing_secret = "renovate-credentials"
      dry_run         = true
    }
  }
}
