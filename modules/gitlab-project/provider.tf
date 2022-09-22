terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">3.0.0"
    }
  }
}

provider "gitlab" {
  token = "glpat-sj3DMGaoDxrRWFxzwett" // your gitlab Personal access token
}
