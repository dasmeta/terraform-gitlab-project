"""Publish a fresh configuration proposal, avoiding stale or identical writes."""
import hashlib
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse


def digest(content):
    return hashlib.sha256(content.encode('utf-8')).hexdigest()


def main():
    from gitlab_api import GitLabAPI
    from read_repository_config import read_snapshot

    api = GitLabAPI(os.environ['GITLAB_API_URL'], os.environ['GITLAB_PROJECT_URL'])
    project_id = os.environ['GITLAB_PROJECT']
    project = urllib.parse.quote(project_id, safe='')
    source = os.environ['GITLAB_SOURCE_BRANCH']
    target = os.environ['GITLAB_TARGET_BRANCH']
    config_path = os.environ['GITLAB_CONFIG_PATH']
    # Large embedded package.json files must never enter exec argv/environment.
    try:
        raw_content = Path(os.environ['GITLAB_CONFIG_CONTENT_FILE']).read_bytes()
        if hashlib.sha256(raw_content).hexdigest() != os.environ['GITLAB_CONFIG_CONTENT_SHA256']:
            raise ValueError('Publication payload checksum mismatch; create a new Terraform plan.')
        content = raw_content.decode('utf-8')
    except (OSError, UnicodeError):
        raise ValueError('Cannot read the publication payload; create a new Terraform plan.') from None
    expected_digest = os.environ['GITLAB_EXPECTED_CONTENT_SHA256']
    desired_digest = digest(content)

    current = read_snapshot(api, project_id, target)
    # This check must precede even the source-file lookup: the source branch may
    # have been deleted after merging and recreated by Terraform from the target.
    if current['file_path'] == config_path and current['source_sha256'] == desired_digest:
        print('No configuration changes remain to propose.')
        return
    if current['file_path'] != config_path or current['source_sha256'] != expected_digest:
        raise ValueError('Target configuration changed since plan; create a new Terraform plan before applying.')

    file_path = f'/projects/{project}/repository/files/{urllib.parse.quote(config_path, safe="")}'
    try:
        source_file = api.request('GET', file_path + '?' + urllib.parse.urlencode({'ref': source}))
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise
        source_file = None
    if source_file is None or source_file['content_sha256'] != desired_digest:
        if source_file is not None and source_file['content_sha256'] != expected_digest:
            raise ValueError('Configuration on the source branch changed outside Terraform; review it before retrying.')
        body = {
            'branch': source,
            'content': content,
            'encoding': 'text',
            'commit_message': 'chore: configure Renovate',
        }
        if source_file is not None:
            # GitLab rejects a concurrent modification instead of overwriting it.
            body['last_commit_id'] = source_file['last_commit_id']
        api.request('POST' if source_file is None else 'PUT', file_path, body)

    path = f'/projects/{project}/merge_requests'
    query = urllib.parse.urlencode({'state': 'opened', 'source_branch': source, 'target_branch': target})
    existing = api.request('GET', path + '?' + query)
    if existing:
        print(f'Reusing configuration MR !{existing[0]["iid"]}')
        return
    try:
        created = api.request('POST', path, {
            'source_branch': source,
            'target_branch': target,
            'title': os.environ['GITLAB_MR_TITLE'],
            'description': 'Adds Terraform-managed Renovate configuration. Review dependency coverage and CI, then merge to enable the shared bot. Automerge is disabled.',
            'remove_source_branch': False,
        })
    except urllib.error.HTTPError as exc:
        if exc.code != 409:
            raise
        existing = api.request('GET', path + '?' + query)
        if not existing:
            raise
        print(f'Reusing configuration MR !{existing[0]["iid"]}')
        return
    print(f'Created configuration MR !{created["iid"]}')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as exc:
        print(f'GitLab proposal request failed with HTTP {exc.code}; check endpoint, bot access and branches.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, KeyError, urllib.error.URLError, TimeoutError) as exc:
        detail = str(exc) if isinstance(exc, (ValueError, KeyError)) else type(exc).__name__
        print(f'Cannot ensure configuration MR: {detail}', file=sys.stderr)
        sys.exit(1)
