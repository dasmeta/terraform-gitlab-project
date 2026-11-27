"""Read-only config discovery against a fake GitLab API."""
import importlib.util
import hashlib
import json
import os
import secrets
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'read_repository_config.py'


class ReadConfigTests(unittest.TestCase):
    def read(self, documents):
        spec = importlib.util.spec_from_file_location('read_repository_config', SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        reads = []

        def tree(path):
            reads.append(('tree', path))
            prefix = path + '/' if path else ''
            found = {}
            for name in documents:
                if name.startswith(prefix):
                    tail = name[len(prefix):]
                    first = tail.split('/')[0]
                    found[prefix + first] = {'path': prefix + first, 'type': 'tree' if '/' in tail else 'blob'}
            return list(found.values())

        def raw(path):
            reads.append(('file', path))
            return documents[path]

        return module.discover(tree, raw), reads

    def test_empty_repository_gets_generic_new_file(self):
        result, reads = self.read({'README.md': '# Example'})
        self.assertEqual(result['file_path'], 'renovate.json')
        self.assertEqual(json.loads(result['config']), {})
        self.assertEqual(result['source_sha256'], '')
        self.assertFalse(any(r[0] == 'file' for r in reads))

    def test_existing_schedule_and_rules_are_returned(self):
        config = {'schedule': ['before 5am'], 'packageRules': [{'groupName': 'existing'}]}
        result, _ = self.read({'renovate.json': json.dumps(config)})
        self.assertEqual(json.loads(result['config']), config)

    def test_source_digest_preserves_original_document_bytes(self):
        documents = (
            ('renovate.json', '{\n  "labels": ["existing"]\n}\n'),
            ('package.json', '{ "name": "café", "renovate": {"labels": ["existing"]} }\n'),
        )
        for path, source in documents:
            with self.subTest(path=path):
                result, _ = self.read({path: source})
                self.assertEqual(result['source_sha256'], hashlib.sha256(source.encode('utf-8')).hexdigest())

    def test_alternate_location_is_retained(self):
        result, _ = self.read({'.gitlab/renovate.json': '{"dependencyDashboard": true}'})
        self.assertEqual(result['file_path'], '.gitlab/renovate.json')

    def test_all_gitlab_alternate_locations_are_retained(self):
        for directory in ('', '.gitlab/'):
            for suffix in ('json', 'jsonc', 'json5'):
                path = directory + 'renovate.' + suffix
                with self.subTest(path=path):
                    result, _ = self.read({path: '{"labels": ["existing"]}'})
                    self.assertEqual(result['file_path'], path)

    def test_discovery_uses_gitlab_platform_precedence(self):
        result, reads = self.read({
            '.github/renovate.json': '{"labels": ["first"]}',
            '.gitlab/renovate.json': '{"labels": ["second"]}',
        })
        self.assertEqual(result['file_path'], '.gitlab/renovate.json')
        self.assertEqual([path for kind, path in reads if kind == 'file'], ['.gitlab/renovate.json'])

    def test_package_json_embedded_config_preserves_manifest(self):
        document = {'name': 'example', 'dependencies': {'example': '1.0.0'}, 'renovate': {'labels': ['dependencies']}}
        result, _ = self.read({'package.json': json.dumps(document)})
        self.assertEqual(result['file_path'], 'package.json')
        self.assertEqual(result['embedded'], 'true')
        self.assertEqual(json.loads(result['document']), document)

    def test_plain_package_json_does_not_become_config(self):
        result, _ = self.read({'package.json': '{"name": "example"}'})
        self.assertEqual(result['file_path'], 'renovate.json')
        self.assertEqual(result['embedded'], 'false')
        self.assertEqual(result['source_sha256'], '')

    def test_snapshot_pins_directory_and_file_reads_to_initial_branch_commit(self):
        spec = importlib.util.spec_from_file_location('read_repository_config', SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        calls = []
        snapshot_sha = 'a' * 40

        class MovingBranchAPI:
            def request(self, method, suffix, body=None, decode_json=True):
                calls.append((method, suffix))
                parsed = urlsplit(suffix)
                if '/repository/branches/' in parsed.path:
                    # Every subsequent symbolic read would observe another commit.
                    return {'commit': {'id': snapshot_sha}}
                if parse_qs(parsed.query).get('ref') != [snapshot_sha]:
                    raise AssertionError('Read followed moving branch instead of captured commit')
                if '/repository/tree?' in suffix:
                    if parse_qs(parsed.query, keep_blank_values=True)['path'] == ['.gitlab']:
                        return [{'path': '.gitlab/renovate.json', 'type': 'blob'}]
                    return [{'path': '.gitlab', 'type': 'tree'}]
                return '{"labels": ["captured"]}'

        result = module.read_snapshot(MovingBranchAPI(), 'example/platform', 'release/main')
        self.assertEqual(result['commit_sha'], snapshot_sha)
        self.assertEqual(json.loads(result['config'])['labels'], ['captured'])
        self.assertEqual(calls[0], ('GET', '/projects/example%2Fplatform/repository/branches/release%2Fmain'))
        self.assertEqual(len(calls), 4)

    def test_malformed_existing_config_fails(self):
        with self.assertRaises(ValueError):
            self.read({'renovate.json': '{invalid'})

    def test_previous_managed_entries_are_removed_but_manual_additions_remain(self):
        marker = 'Managed by terraform-gitlab-project: '
        metadata = {'version': 1, 'description': None, 'fields': {
            'extends': {'before': ['original'], 'after': ['original', 'old-shared']},
            'ignorePaths': {'before': None, 'after': ['generated/old.yml']}
        }}
        config = {'extends': ['original', 'old-shared', 'manual-preset'], 'ignorePaths': ['generated/old.yml', 'manual/**'], 'description': [marker + json.dumps(metadata)]}
        result, _ = self.read({'renovate.json': json.dumps(config)})
        restored = json.loads(result['config'])
        self.assertEqual(restored['extends'], ['original', 'manual-preset'])
        self.assertEqual(restored['ignorePaths'], ['manual/**'])
        self.assertNotIn('description', restored)

    def test_exact_previous_managed_fields_restore_original(self):
        marker = 'Managed by terraform-gitlab-project: '
        metadata = {'version': 1, 'description': 'Original description', 'fields': {'ignorePaths': {'before': None, 'after': ['generated/old.yml']}}}
        config = {'ignorePaths': ['generated/old.yml'], 'description': ['Original description', marker + json.dumps(metadata)]}
        result, _ = self.read({'renovate.json': json.dumps(config)})
        restored = json.loads(result['config'])
        self.assertNotIn('ignorePaths', restored)
        self.assertEqual(restored['description'], 'Original description')

    def test_literal_credentials_do_not_enter_terraform_state(self):
        with self.assertRaisesRegex(ValueError, 'Secret'):
            self.read({'renovate.json': json.dumps({'hostRules': [{'password': secrets.token_urlsafe(24)}]})})

    def test_malformed_ownership_record_fails_safely(self):
        for record in ({'version': 1, 'fields': []}, {'version': 1, 'fields': {'ignorePaths': None}}):
            with self.subTest(record=record):
                config = {'description': ['Managed by terraform-gitlab-project: ' + json.dumps(record)]}
                with self.assertRaisesRegex(ValueError, 'ownership record'):
                    self.read({'renovate.json': json.dumps(config)})


class ReadConfigHttpTests(unittest.TestCase):
    def invoke(self, auth_failure=False, mismatch=False):
        calls = []

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def do_GET(self):
                calls.append(self.path)
                if auth_failure:
                    code, body = 401, 'fixture-token-never-log'
                elif '/repository/branches/' in self.path:
                    code, body = 200, json.dumps({'commit': {'id': 'a' * 40}})
                elif '/repository/tree?' in self.path:
                    page = parse_qs(urlsplit(self.path).query)['page'][0]
                    entries = [{'path': f'file-{i}', 'type': 'blob'} for i in range(100)] if page == '1' else [{'path': 'renovate.json', 'type': 'blob'}]
                    code, body = 200, json.dumps(entries)
                else:
                    code, body = 200, '{"schedule":["before 5am"],"labels":["existing"]}'
                self.send_response(code)
                self.end_headers()
                self.wfile.write(body.encode())

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        env = {k: v for k, v in os.environ.items() if not k.startswith('GITLAB_')}
        env['GITLAB_TOKEN'] = 'fixture-token-never-log'
        query = {'endpoint': f'http://127.0.0.1:{server.server_port}/api/v4', 'project': 'example/platform', 'ref': 'main'}
        query['project_url'] = f'http://{"localhost" if mismatch else "127.0.0.1"}:{server.server_port}/example/platform'
        try:
            result = subprocess.run(['python3', str(SCRIPT)], input=json.dumps(query), env=env, capture_output=True, text=True)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()
        self.assertNotIn('fixture-token-never-log', result.stdout + result.stderr)
        return result, calls

    def test_paginated_discovery_reads_only_expected_file(self):
        result, calls = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(json.loads(result.stdout)['config'])['labels'], ['existing'])
        self.assertEqual(len(calls), 4)
        self.assertIn('page=2', calls[2])
        self.assertIn('example%2Fplatform', calls[3])
        self.assertEqual(json.loads(result.stdout)['commit_sha'], 'a' * 40)
        for path in calls[1:]:
            self.assertEqual(parse_qs(urlsplit(path).query)['ref'], ['a' * 40])

    def test_untrusted_endpoint_is_rejected_before_any_request(self):
        result, calls = self.invoke(mismatch=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('origin', result.stderr)
        self.assertEqual(calls, [])

    def test_auth_failure_fails_without_response_body(self):
        result, calls = self.invoke(auth_failure=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('401', result.stderr)
        self.assertEqual(len(calls), 1)


if __name__ == '__main__':
    unittest.main()
