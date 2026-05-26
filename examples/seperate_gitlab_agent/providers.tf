terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "= 18.8.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
  }
}

variable "kubeconfig_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Kubeconfig path used by the Helm provider to install the GitLab Agent chart."
}

variable "kubeconfig_context" {
  type        = string
  default     = "kind-gitlab-agent-dev"
  description = "Optional kubeconfig context used by the Helm provider. Leave null to use the current context."
}

provider "gitlab" {
  # GitLab.com is the default; set GITLAB_TOKEN in the environment.
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand(var.kubeconfig_path)
    config_context = var.kubeconfig_context
  }
}
