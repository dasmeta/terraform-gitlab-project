# Data Model

- root renovate: endpoint, explicit repositories, optional install object.
- install: enabled, release_name, namespace, create_namespace, existing_secret,
  chart_version, schedule, time_zone, suspend, dry_run, resources.
- project renovate: enabled, source_branch, merge_request_title, extends,
  include_paths, ignore_paths, custom_managers.
- custom manager: regex/jsonata type, file patterns/extraction strings,
  optional file format and datasource/name/versioning/registry templates.
- allowlist: sorted distinct union of explicit paths and opted-in project paths.
- proposal: source branch -> config file -> open/reuse MR -> maintainer merge ->
  worker processes merged config; bot never merges automatically.
