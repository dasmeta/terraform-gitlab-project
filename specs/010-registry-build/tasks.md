# Tasks: Selectable Container Build Target

- [x] T001 Add failing ECR and on-premises target tests in `modules/gitlab_ci_pipelines/tests/multi_job.tftest.hcl`
- [x] T002 Run targeted Terraform tests and confirm the pre-implementation test run was blocked by sandboxed provider startup
- [x] T003 Add `ci-templates/templates/build/onprem-build.gitlab-ci.yml`
- [x] T004 Add `target` to the root input schema and target-specific validation in `variables.tf`
- [x] T005 Add build target normalization and on-premises mapping in `modules/gitlab_ci_pipelines/main.tf`
- [x] T006 Update examples in `examples/basic/main.tf`
- [x] T007 Update usage documentation in `modules/gitlab_ci_pipelines/README.md` and root generated documentation
- [x] T008 Run Terraform formatting, tests, validation, and static template checks
- [x] T009 Define `variables.image_tags` as a list-only input and normalize it to `IMAGE_TAGS`
- [x] T010 Update ECR and on-premises templates to push one image reference per configured tag
