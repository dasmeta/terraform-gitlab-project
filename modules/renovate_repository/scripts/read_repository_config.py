"""Read an existing Renovate config for Terraform without modifying GitLab."""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

# Renovate's GitLab config discovery order, not a list of customer repositories.
CONFIG_FILES = (
    'renovate.json', 'renovate.jsonc', 'renovate.json5',
    '.gitlab/renovate.json', '.gitlab/renovate.jsonc', '.gitlab/renovate.json5',
    '.renovaterc', '.renovaterc.json', '.renovaterc.jsonc', '.renovaterc.json5',
    'package.json',
)


def parse_document(text, path):
    try:
        result = json.loads(text)
    except json.JSONDecodeError:
        try:
            import json5
        except ImportError:
            raise ValueError(f'{path} is not strict JSON. Install the optional json5 package in the Terraform runner to preserve JSONC/JSON5 configurations.') from None
        try:
            result = json5.loads(text)
        except ValueError:
            raise ValueError(f'{path} contains invalid configuration; it will not be replaced.') from None
    if not isinstance(result, dict):
        raise ValueError(f'{path} must contain an object; it will not be replaced.')
    return result


def reject_credentials(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key.lower() in {'token', 'password', 'apikey', 'privatekey'} and item:
                raise ValueError('Move existing Renovate credentials to the bot Secret before Terraform manages this configuration.')
            reject_credentials(item)
    elif isinstance(value, list):
        for item in value:
            reject_credentials(item)


OWNERSHIP_PREFIX = 'Managed by terraform-gitlab-project: '
MANAGED_FIELDS = {'extends', 'includePaths', 'ignorePaths', 'customManagers', 'packageRules'}


def restore_original_policy(config):
    """Subtract our previous changes without dropping subsequent manual additions."""
    description = config.get('description', [])
    descriptions = [description] if isinstance(description, str) else description
    if not isinstance(descriptions, list) or not all(isinstance(item, str) for item in descriptions):
        raise ValueError('Existing description must be text or a list of strings.')
    markers = [item for item in descriptions if item.startswith(OWNERSHIP_PREFIX)]
    if not markers:
        return config
    if len(markers) != 1:
        raise ValueError('Conflicting Terraform ownership records; configuration will not be replaced.')
    try:
        record = json.loads(markers[0][len(OWNERSHIP_PREFIX):])
        if record['version'] != 1 or not isinstance(record['fields'], dict) or not set(record['fields']).issubset(MANAGED_FIELDS):
            raise ValueError()
        for field, change in record['fields'].items():
            before, after = change['before'], change['after']
            current = config.get(field)
            if current == after:
                if before is None:
                    config.pop(field, None)
                else:
                    config[field] = before
            elif isinstance(current, list) and isinstance(after, list):
                original = before if isinstance(before, list) else []
                added = [item for item in after if item not in original]
                removed = [item for item in original if item not in after]
                restored = [item for item in current if item not in added]
                restored.extend(item for item in removed if item not in restored)
                config[field] = restored
        remaining = [item for item in descriptions if not item.startswith(OWNERSHIP_PREFIX)]
        previous_description = record.get('description')
        previous_list = [previous_description] if isinstance(previous_description, str) else (previous_description or [])
        if remaining == previous_list:
            if previous_description is None:
                config.pop('description', None)
            else:
                config['description'] = previous_description
        else:
            config['description'] = remaining
    except (ValueError, KeyError, TypeError):
        raise ValueError('Invalid Terraform ownership record; configuration will not be replaced.') from None
    return config


def discover(tree, raw):
    paths = {item['path'] for item in tree('')}
    listed_directories = set()
    for path in CONFIG_FILES:
        directory = path.split('/')[0] if '/' in path else ''
        if directory and directory in paths and directory not in listed_directories:
            paths.update(item['path'] for item in tree(directory))
            listed_directories.add(directory)
        if path not in paths:
            continue
        document = parse_document(raw(path), path)
        embedded = path == 'package.json'
        if embedded and 'renovate' not in document:
            continue
        config = document['renovate'] if embedded else document
        if not isinstance(config, dict):
            raise ValueError(f'{path} has unsupported Renovate configuration; it will not be replaced.')
        reject_credentials(config)
        config = restore_original_policy(config.copy())
        reject_credentials(config)
        return {
            'file_path': path,
            'config': json.dumps(config, allow_nan=False),
            'document': json.dumps(document if embedded else {}, allow_nan=False),
            'embedded': 'true' if embedded else 'false',
        }
    return {'file_path': 'renovate.json', 'config': '{}', 'document': '{}', 'embedded': 'false'}


def main():
    query = json.load(sys.stdin)
    token = os.environ.get('GITLAB_API_TOKEN') or os.environ.get('GITLAB_TOKEN')
    if not token:
        raise ValueError('Set GITLAB_API_TOKEN or GITLAB_TOKEN for read-only Renovate configuration discovery.')
    project = urllib.parse.quote(query['project'], safe='')
    endpoint = query['endpoint'].rstrip('/')
    ref = query['ref']

    def get(suffix, decode_json=True):
        request = urllib.request.Request(endpoint + f'/projects/{project}' + suffix,
                                         headers={'PRIVATE-TOKEN': token})
        with urllib.request.urlopen(request, timeout=30) as response:
            content = response.read().decode('utf-8')
        return json.loads(content) if decode_json else content

    def tree(path):
        entries = []
        page = 1
        while True:
            args = urllib.parse.urlencode({'ref': ref, 'path': path, 'per_page': 100, 'page': page})
            batch = get('/repository/tree?' + args)
            entries.extend(batch)
            if len(batch) < 100:
                return entries
            page += 1

    def raw(path):
        encoded = urllib.parse.quote(path, safe='')
        args = urllib.parse.urlencode({'ref': ref})
        return get(f'/repository/files/{encoded}/raw?' + args, decode_json=False)

    print(json.dumps(discover(tree, raw)))


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as exc:
        print(f'Renovate config discovery failed with HTTP {exc.code}; check project access and default branch. No files were written.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, KeyError, urllib.error.URLError, TimeoutError) as exc:
        detail = str(exc) if isinstance(exc, (ValueError, KeyError)) else type(exc).__name__
        print(f'Cannot read Renovate config: {detail}', file=sys.stderr)
        sys.exit(1)
