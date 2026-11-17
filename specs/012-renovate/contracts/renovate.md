# Renovate Contract

Standalone deployment takes repositories, endpoint and install. Root exposes
renovate with the same fields and derives enabled managed project paths.
Installation defaults disabled; enabled deployment requires an existing Secret
name and nonempty explicit/derived repository allowlist.

Project renovate.enabled proposes renovate.json on terraform/renovate into its
default branch. Source branch and MR title are tunable; file path is fixed.
Config uses config:recommended, automerge=false, platformAutomerge=false and
optional includePaths/ignorePaths/customManagers. Root can configure repositories
without deploying. Standalone deployment has no GitLab provider requirement.
