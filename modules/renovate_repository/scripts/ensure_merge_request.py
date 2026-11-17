"""Ensure one open configuration MR; GitLab credentials stay in the environment."""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


def main():
    token = os.environ.get('GITLAB_API_TOKEN') or os.environ.get('GITLAB_TOKEN')
    if not token:
        raise ValueError('Set GITLAB_API_TOKEN or GITLAB_TOKEN for configuration MR creation.')
    endpoint = os.environ['GITLAB_API_URL'].rstrip('/')
    project = urllib.parse.quote(os.environ['GITLAB_PROJECT'], safe='')
    path = f'/projects/{project}/merge_requests'
    source = os.environ['GITLAB_SOURCE_BRANCH']
    target = os.environ['GITLAB_TARGET_BRANCH']
    query = urllib.parse.urlencode({'state': 'opened', 'source_branch': source, 'target_branch': target})

    def request(method, suffix, body=None):
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(endpoint + suffix, data=data, method=method,
                                     headers={'PRIVATE-TOKEN': token, 'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)

    existing = request('GET', path + '?' + query)
    if existing:
        print(f'Reusing configuration MR !{existing[0]["iid"]}')
        return
    # Compare the file itself: merge-base diffs are misleading after squash
    # merges, while whole-tree diffs include unrelated target-branch changes.
    file_path = f'/projects/{project}/repository/files/renovate.json?'
    source_file = request('GET', file_path + urllib.parse.urlencode({'ref': source}))
    try:
        target_file = request('GET', file_path + urllib.parse.urlencode({'ref': target}))
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise
        target_file = None
    if target_file and source_file['content_sha256'] == target_file['content_sha256']:
        print('No configuration changes remain to propose.')
        return
    try:
        created = request('POST', path, {
            'source_branch': source,
            'target_branch': target,
            'title': os.environ['GITLAB_MR_TITLE'],
            'description': 'Adds Terraform-managed Renovate configuration. Review dependency coverage and CI, then merge to enable the shared bot. Automerge is disabled. Keep the source branch: Terraform manages its configuration file.',
            # Terraform owns this branch/file; removing it causes recreation on refresh.
            'remove_source_branch': False,
        })
    except urllib.error.HTTPError as exc:
        if exc.code != 409:
            raise
        existing = request('GET', path + '?' + query)
        if not existing:
            raise
        print(f'Reusing configuration MR !{existing[0]["iid"]}')
        return
    print(f'Created configuration MR !{created["iid"]}')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as exc:
        # Do not echo response bodies, request headers or credential values.
        print(f'GitLab MR request failed with HTTP {exc.code}; check endpoint, bot access and branches.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, KeyError, urllib.error.URLError, TimeoutError) as exc:
        detail = str(exc) if isinstance(exc, (ValueError, KeyError)) else type(exc).__name__
        print(f'Cannot ensure configuration MR: {detail}', file=sys.stderr)
        sys.exit(1)
