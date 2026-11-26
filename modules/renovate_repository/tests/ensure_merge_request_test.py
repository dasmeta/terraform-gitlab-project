"""Proposal lifecycle regressions against a synthetic GitLab HTTP server."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'ensure_merge_request.py'
ORIGINAL = '{"extends":["local>example/preset"]}\n'
DESIRED = '{"extends":["config:recommended"],"automerge":false}\n'
SHA = 'a' * 40


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest() if value is not None else ''


class MergeRequestTests(unittest.TestCase):
    def invoke(self, target=ORIGINAL, expected=ORIGINAL, source=ORIGINAL,
               desired=DESIRED, target_path='renovate.json', config_path='renovate.json',
               existing=False, race=False, status=200, update_status=200, mismatch=False):
        calls = []
        state = {'mr_posts': 0}

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def respond(self, code, body):
                self.send_response(code)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(body).encode())

            def do_GET(self):
                calls.append(('GET', self.path, None))
                path = urlsplit(self.path).path
                query = parse_qs(urlsplit(self.path).query)
                if status != 200:
                    self.respond(status, {'message': 'unit-test-token'})
                elif '/repository/branches/' in path:
                    self.respond(200, {'commit': {'id': SHA}})
                elif path.endswith('/repository/tree'):
                    self.respond(200, [] if target is None else [{'type': 'blob', 'path': target_path}])
                elif '/repository/files/' in path and path.endswith('/raw'):
                    if query.get('ref') != [SHA]:
                        self.respond(400, {'error': 'Must read immutable snapshot'})
                        return
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(target.encode())
                elif '/repository/files/' in path:
                    if source is None:
                        self.respond(404, {})
                    else:
                        self.respond(200, {'content_sha256': digest(source), 'last_commit_id': 'b' * 40})
                elif path.endswith('/merge_requests'):
                    self.respond(200, [{'iid': 7}] if existing or (race and state['mr_posts']) else [])
                else:
                    self.respond(404, {})

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                calls.append(('POST', self.path, body))
                if self.path.endswith('/merge_requests'):
                    state['mr_posts'] += 1
                    self.respond(409 if race else 201, {} if race else {'iid': 42})
                else:
                    self.respond(201, {'file_path': config_path})

            def do_PUT(self):
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                calls.append(('PUT', self.path, body))
                self.respond(update_status, {'message': 'unit-test-token'} if update_status != 200 else {})

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        env = {key: value for key, value in os.environ.items() if not key.startswith('GITLAB_')}
        endpoint = f'http://127.0.0.1:{server.server_port}'
        env.update({
            'GITLAB_TOKEN': 'unit-test-token',
            'GITLAB_API_URL': endpoint + '/api/v4',
            'GITLAB_PROJECT_URL': ('https://gitlab.example' if mismatch else endpoint) + '/example/project',
            'GITLAB_PROJECT': 'example/project',
            'GITLAB_SOURCE_BRANCH': 'terraform/renovate',
            'GITLAB_TARGET_BRANCH': 'master',
            'GITLAB_MR_TITLE': 'chore: configure Renovate',
            'GITLAB_CONFIG_PATH': config_path,
            'GITLAB_CONFIG_CONTENT': desired,
            'GITLAB_EXPECTED_CONTENT_SHA256': digest(expected),
        })
        try:
            result = subprocess.run(['python3', str(SCRIPT)], env=env, capture_output=True, text=True)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()
        self.assertNotIn('unit-test-token', result.stdout + result.stderr)
        return result, calls

    def test_updates_file_with_optimistic_lock_then_creates_mr(self):
        result, calls = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        writes = [call for call in calls if call[0] != 'GET']
        self.assertEqual([call[0] for call in writes], ['PUT', 'POST'])
        self.assertEqual(writes[0][2]['last_commit_id'], 'b' * 40)
        self.assertEqual(writes[0][2]['content'], DESIRED)
        self.assertEqual(writes[1][2]['target_branch'], 'master')
        self.assertFalse(writes[1][2]['remove_source_branch'])

    def test_reuses_open_mr_after_skipping_identical_source(self):
        result, calls = self.invoke(source=DESIRED, existing=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all(call[0] == 'GET' for call in calls))
        self.assertIn('!7', result.stdout)

    def test_recovers_duplicate_mr_creation_race(self):
        result, calls = self.invoke(source=DESIRED, race=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[0] for call in calls if call[0] != 'GET'], ['POST'])
        self.assertIn('!7', result.stdout)

    def test_merged_config_with_deleted_source_requires_no_write(self):
        result, calls = self.invoke(target=DESIRED, source=None)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all(call[0] == 'GET' for call in calls))
        self.assertFalse(any('/merge_requests' in call[1] for call in calls))
        self.assertIn('No configuration changes', result.stdout)

    def test_new_config_is_created(self):
        result, calls = self.invoke(target=None, expected=None, source=None)
        self.assertEqual(result.returncode, 0, result.stderr)
        writes = [call for call in calls if call[0] != 'GET']
        self.assertEqual([call[0] for call in writes], ['POST', 'POST'])
        self.assertIn('/repository/files/renovate.json', writes[0][1])

    def test_changed_target_stops_before_file_or_mr_write(self):
        result, calls = self.invoke(target='{"extends":["new-manual-preset"]}\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('new Terraform plan', result.stderr)
        self.assertTrue(all(call[0] == 'GET' for call in calls))

    def test_changed_embedded_package_fields_stop_stale_plan(self):
        old = '{"name":"app","version":"1","renovate":{}}\n'
        new = '{"name":"app","version":"2","renovate":{}}\n'
        result, calls = self.invoke(target= new, expected=old, source=old, target_path='package.json', config_path='package.json')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('new Terraform plan', result.stderr)
        self.assertTrue(all(call[0] == 'GET' for call in calls))

    def test_moved_active_config_stops_stale_plan(self):
        result, calls = self.invoke(target_path='.gitlab/renovate.json')
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(all(call[0] == 'GET' for call in calls))

    def test_unrelated_target_commit_allows_unchanged_config(self):
        # Captured target SHA is arbitrary/new; freshness compares exact file bytes.
        result, calls = self.invoke(source=DESIRED)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[0] for call in calls if call[0] != 'GET'], ['POST'])

    def test_manual_source_edits_are_not_overwritten(self):
        result, calls = self.invoke(source='{"description":"manual edit"}\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('source branch', result.stderr)
        self.assertTrue(all(call[0] == 'GET' for call in calls))

    def test_empty_commit_or_concurrent_put_error_is_not_swallowed(self):
        result, calls = self.invoke(update_status=400)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('400', result.stderr)
        self.assertFalse(any('/merge_requests' in call[1] for call in calls))

    def test_alternate_config_path_is_url_encoded(self):
        result, calls = self.invoke(target_path='.gitlab/renovate.json', config_path='.gitlab/renovate.json')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any('.gitlab%2Frenovate.json' in call[1] for call in calls))

    def test_auth_failure_is_actionable_and_sanitized(self):
        result, calls = self.invoke(status=401)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('401', result.stderr)
        self.assertEqual(len(calls), 1)

    def test_wrong_authority_stops_before_network(self):
        result, calls = self.invoke(mismatch=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])
        self.assertIn('origin', result.stderr)


if __name__ == '__main__':
    unittest.main()
