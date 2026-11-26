terraform {
  required_version = ">= 1.7"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 19.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
