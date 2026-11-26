"""Transport regressions use synthetic credentials and localhost servers only."""
import contextlib
import importlib.util
import json
import os
from pathlib import Path
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch
import urllib.error


SCRIPT = Path(__file__).parents[1] / 'scripts' / 'gitlab_api.py'
spec = importlib.util.spec_from_file_location('gitlab_api', SCRIPT)
gitlab_api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gitlab_api)
GitLabAPI = gitlab_api.GitLabAPI
TOKEN = 'synthetic-private-token-for-transport-tests'


@contextlib.contextmanager
def server(status=200, payload=None, location=None, reason=None):
    calls = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            length = int(self.headers.get('Content-Length', '0'))
            calls.append((self.command, self.path, dict(self.headers), self.rfile.read(length)))
            self.send_response(status, reason)
            if location:
                self.send_header('Location', location)
            self.end_headers()
            self.wfile.write(json.dumps(payload if payload is not None else {'ok': True}).encode())

        do_POST = do_GET

        def log_message(self, *_args):
            pass

    httpd = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    try:
        yield f'http://127.0.0.1:{httpd.server_port}', calls
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


class GitLabAPITest(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {}, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_mismatched_endpoint_sends_no_requests_to_either_server(self):
        with server() as (trusted, trusted_calls), server() as (other, other_calls):
            with self.assertRaisesRegex(ValueError, 'origin'):
                GitLabAPI(other + '/api/v4', trusted + '/group/project', TOKEN)
            self.assertEqual(trusted_calls, [])
            self.assertEqual(other_calls, [])

    def test_authority_is_validated_before_environment_token_is_obtained(self):
        with patch.object(gitlab_api.os.environ, 'get', side_effect=AssertionError('token read too soon')):
            with self.assertRaises(ValueError):
                GitLabAPI('https://other.example/api/v4', 'https://gitlab.example/group/repo')

    def test_matching_cloud_and_self_managed_normalized_origins(self):
        examples = (
            ('https://GITLAB.COM:443/api/v4/', 'https://gitlab.com/group/repo'),
            ('https://GitLab.Example:8443/custom/api/v4/', 'https://gitlab.example:8443/custom/group/repo'),
            ('http://gitlab.example:80/api/v4', 'http://GITLAB.EXAMPLE/group/repo'),
        )
        for endpoint, project_url in examples:
            with self.subTest(endpoint=endpoint):
                GitLabAPI(endpoint, project_url, TOKEN)

    def test_default_cloud_endpoint_conflicting_with_provider_environment_is_rejected(self):
        os.environ['GITLAB_BASE_URL'] = 'https://gitlab.example/api/v4/'
        with self.assertRaisesRegex(ValueError, 'GITLAB_BASE_URL'):
            GitLabAPI('https://gitlab.com/api/v4', 'https://gitlab.com/group/repo', TOKEN)

    def test_provider_environment_endpoint_normalizes_default_port_and_slash(self):
        os.environ['GITLAB_BASE_URL'] = 'https://GITLAB.EXAMPLE:443/api/v4/'
        GitLabAPI('https://gitlab.example/api/v4', 'https://gitlab.example/group/repo', TOKEN)

    def test_invalid_authorities_are_rejected_without_exposing_input(self):
        bad_endpoints = ('', 'https://gitlab.example', 'https://gitlab.example/api/v3',
                         f'https://{TOKEN}@gitlab.example/api/v4',
                         f'https://gitlab.example/api/v4?token={TOKEN}',
                         f'https://gitlab.example/api/v4#{TOKEN}',
                         'https://gitlab.example/api/v4?', 'https://gitlab.example/api/v4#',
                         'https://gitlab.example:0/api/v4',
                         'https://gitlab.example:bad/api/v4', '//gitlab.example/api/v4')
        for endpoint in bad_endpoints:
            with self.subTest(endpoint=endpoint):
                with self.assertRaises(ValueError) as caught:
                    GitLabAPI(endpoint, 'https://gitlab.example/group/repo', TOKEN)
                self.assertNotIn(TOKEN, str(caught.exception))
        for project_url in ('', '/group/repo', f'https://{TOKEN}@gitlab.example/repo',
                            'ftp://gitlab.example/repo'):
            with self.subTest(project_url=project_url):
                with self.assertRaises(ValueError):
                    GitLabAPI('https://gitlab.example/api/v4', project_url, TOKEN)

    def test_local_requests_support_environment_token_json_body_and_raw_text(self):
        os.environ['GITLAB_TOKEN'] = TOKEN
        with server(payload={'ok': True}) as (base, calls):
            api = GitLabAPI(base + '/api/v4/', base + '/group/repo')
            self.assertEqual(api.request('POST', '/projects/1', {'value': 7}), {'ok': True})
            self.assertEqual(api.request('GET', '/projects/1?ref=main', decode_json=False), '{"ok": true}')
            self.assertEqual(calls[0][0:2], ('POST', '/api/v4/projects/1'))
            self.assertEqual(calls[0][2]['Private-Token'], TOKEN)
            self.assertEqual(json.loads(calls[0][3]), {'value': 7})

    def test_primary_environment_token_takes_precedence(self):
        os.environ.update(GITLAB_API_TOKEN=TOKEN, GITLAB_TOKEN='unused-token')
        with server() as (base, calls):
            GitLabAPI(base + '/api/v4', base + '/repo').request('GET', '/projects/1')
            self.assertEqual(calls[0][2]['Private-Token'], TOKEN)

    def test_missing_token_is_a_safe_error(self):
        with self.assertRaisesRegex(ValueError, 'GITLAB_API_TOKEN or GITLAB_TOKEN'):
            GitLabAPI('https://gitlab.com/api/v4', 'https://gitlab.com/group/repo')

    def test_redirects_never_forward_token_to_receiver(self):
        with server() as (receiver, received):
            for status in (301, 302, 303, 307, 308):
                with self.subTest(status=status), server(status, location=receiver + '/' + TOKEN) as (source, calls):
                    api = GitLabAPI(source + '/api/v4', source + '/repo', TOKEN)
                    with self.assertRaisesRegex(ValueError, 'redirect') as caught:
                        api.request('GET', '/projects/1')
                    self.assertNotIn(TOKEN, str(caught.exception))
                    self.assertEqual(len(calls), 1)
                    self.assertEqual(received, [])

    def test_http_status_survives_but_response_body_and_reason_do_not(self):
        for status in (404, 409, 500):
            with self.subTest(status=status), server(status, payload={'error': TOKEN}, reason=TOKEN) as (base, _):
                api = GitLabAPI(base + '/api/v4', base + '/repo', TOKEN)
                with self.assertRaises(urllib.error.HTTPError) as caught:
                    api.request('GET', '/projects/1?token=' + TOKEN)
                self.assertEqual(caught.exception.code, status)
                self.assertNotIn(TOKEN, str(caught.exception))
                self.assertNotIn(TOKEN.encode(), caught.exception.read())
                caught.exception.close()

    def test_suffix_cannot_change_origin_or_escape_api_path(self):
        with server() as (base, calls):
            api = GitLabAPI(base + '/api/v4', base + '/repo', TOKEN)
            for suffix in ('https://other.example/projects/1', '//other.example/projects/1',
                           'projects/1', '/../projects/1', '/projects/1#fragment', '/\\other.example'):
                with self.subTest(suffix=suffix), self.assertRaises(ValueError):
                    api.request('GET', suffix)
            self.assertEqual(calls, [])


if __name__ == '__main__':
    unittest.main()
