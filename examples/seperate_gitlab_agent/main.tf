module "gitlab_agent_prod" {
  source  = "../../modules/gitlab_agent_config"
  enabled = true
  gitlab_agent = {
    enabled             = true
    name                = "eks-prod"
    config_project_id   = "82444509"
    config_project_path = "platform/gitlab-agents"
    source_branch       = "feature/gitlab-agent-prod"
    target_branch       = "main"
    register_agent      = true

    install = {
      enabled     = true
      namespace   = "gitlab-agent-prod"
      kas_address = "wss://kas.gitlab.com"
    }

    ci_access = {
      projects = [
        { id = "terraform-gitlab-module/example-team-a-tf/example-dynamic-environments" },
        { id = "terraform-gitlab-module/example-team-a-tf/service-one" },
        { id = "terraform-gitlab-module/example-team-b-tf/service-two" },
        { id = "terraform-gitlab-module/example-team-b-tf/service-three" },
      ]
    }
    user_access = {
      access_as_agent = true
      projects = [
        { id = "terraform-gitlab-module/example-team-a-tf/example-dynamic-environments" },
        { id = "terraform-gitlab-module/example-team-a-tf/service-one" },
        { id = "terraform-gitlab-module/example-team-b-tf/service-two" },
        { id = "terraform-gitlab-module/example-team-b-tf/service-three" },
      ]
    }
  }
}
