provider "gitlab" {}

provider "helm" {
  kubernetes = { config_path = "~/.kube/config" }
}

module "gitlab" {
  source = "../.."

  renovate_token = var.renovate_token

  gitlab_groups = [{ key = "platform", existing_group_id = 12345 }]
  gitlab_projects = [{
    name           = "infrastructure"
    group_key      = "platform"
    default_branch = "main"
    renovate       = { enabled = true }
  }]

  renovate = {
    # Configure shared formats once for the fleet. Native managers need no list.
    defaults = {
      ignore_paths = ["terramate/_terraform/**"]
      custom_managers = [{
        custom_type           = "jsonata"
        file_format           = "yaml"
        manager_file_patterns = ["/terramate/.*\\.ya?ml$/"]
        match_strings         = ["$[source and version].{\"depName\": source, \"currentValue\": version, \"datasource\": \"terraform-module\"}"]
      }]
    }
    install = {
      enabled = true
    }
  }
}
