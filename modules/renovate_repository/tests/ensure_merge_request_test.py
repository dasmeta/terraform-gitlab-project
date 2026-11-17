"""Exercise the MR helper over HTTP without GitLab access or credentials."""
import json
import os
from pathlib import Path
import subprocess
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'ensure_merge_request.py'


class MergeRequestTests(unittest.TestCase):
    def invoke(self, existing=None, status=200, race=False, merged=False, missing_target=False):
        calls = []

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
                if '/repository/files/renovate.json?' in self.path:
                    if missing_target and 'ref=master' in self.path:
                        self.respond(404, {})
                        return
                    self.respond(status, {'content_sha256': 'config-digest'} if merged or 'terraform%2Frenovate' in self.path else {'content_sha256': 'previous-digest'})
                else:
                    found = [{'iid': 7}] if existing or (race and len(calls) > 4) else []
                    self.respond(status, found)

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                calls.append(('POST', self.path, body))
                self.respond(409 if race else 201, {} if race else {'iid': 42})

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        env = {k: v for k, v in os.environ.items() if not k.startswith('GITLAB_')}
        env.update({
            'GITLAB_TOKEN': 'unit-test-token',
            'GITLAB_API_URL': f'http://127.0.0.1:{server.server_port}/api/v4',
            'GITLAB_PROJECT': 'example/project',
            'GITLAB_SOURCE_BRANCH': 'terraform/renovate',
            'GITLAB_TARGET_BRANCH': 'master',
            'GITLAB_MR_TITLE': 'chore: configure Renovate',
        })
        try:
            result = subprocess.run(['python3', str(SCRIPT)], env=env, capture_output=True, text=True)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()
        self.assertNotIn('unit-test-token', result.stdout + result.stderr)
        return result, calls

    def test_creates_targeted_mr(self):
        result, calls = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1][0], 'POST')
        self.assertIn('/projects/example%2Fproject/merge_requests', calls[-1][1])
        self.assertEqual(calls[-1][2]['target_branch'], 'master')
        self.assertFalse(calls[-1][2]['remove_source_branch'])

    def test_reuses_open_mr_without_another_write(self):
        result, calls = self.invoke(existing=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 1)
        self.assertIn('!7', result.stdout)

    def test_recovers_duplicate_creation_race(self):
        result, calls = self.invoke(race=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([c[0] for c in calls], ['GET', 'GET', 'GET', 'POST', 'GET'])

    def test_squash_merged_config_does_not_create_empty_mr(self):
        result, calls = self.invoke(merged=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([c[0] for c in calls], ['GET', 'GET', 'GET'])
        self.assertIn('No configuration changes', result.stdout)

    def test_missing_target_file_is_a_new_configuration(self):
        result, calls = self.invoke(missing_target=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1][0], 'POST')

    def test_auth_failure_is_actionable(self):
        result, calls = self.invoke(status=401)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('401', result.stderr)
        self.assertEqual(len(calls), 1)

    def test_missing_token_stops_before_network(self):
        env = {k: v for k, v in os.environ.items() if not k.startswith('GITLAB_')}
        result = subprocess.run(['python3', str(SCRIPT)], env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('GITLAB_TOKEN', result.stderr)


if __name__ == '__main__':
    unittest.main()
