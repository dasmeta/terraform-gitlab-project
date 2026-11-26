"""Small GitLab client that validates provider authority before reading credentials."""
import io
import json
import os
import urllib.error
import urllib.parse
import urllib.request


def _url(value, label):
    """Return a parsed URL and canonical origin without echoing untrusted input."""
    if not isinstance(value, str) or not value or any(ord(char) <= 32 or ord(char) == 127 for char in value):
        raise ValueError(f'{label} must be a valid HTTP(S) URL.')
    try:
        parsed = urllib.parse.urlsplit(value)
        if (parsed.scheme not in {'http', 'https'} or not parsed.hostname
                or parsed.username is not None or parsed.password is not None
                or '?' in value or '#' in value or '\\' in value):
            raise ValueError()
        hostname = parsed.hostname.rstrip('.').encode('idna').decode('ascii').lower()
        port = parsed.port if parsed.port is not None else (443 if parsed.scheme == 'https' else 80)
        if not hostname or parsed.netloc.endswith(':') or port < 1:
            raise ValueError()
    except (ValueError, UnicodeError):
        raise ValueError(f'{label} must be a valid HTTP(S) URL without credentials, query or fragment.') from None
    return parsed, (parsed.scheme, hostname, port)


def _endpoint(value, label):
    parsed, origin = _url(value, label)
    path = parsed.path.rstrip('/')
    if not path.endswith('/api/v4') or any(part in {'.', '..'} for part in urllib.parse.unquote(path).split('/')):
        raise ValueError(f'{label} must end in /api/v4.')
    return value.rstrip('/'), origin, path


class _RejectRedirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        fp.close()
        raise ValueError('GitLab API redirects are not allowed; check the configured endpoint.')


class GitLabAPI:
    """Validate API/project authority, then make requests without following redirects.

    ``project_url`` must come from authoritative GitLab provider project metadata.
    ``request`` accepts an API-relative suffix beginning with ``/``; body values
    are JSON encoded, and responses are JSON decoded unless decode_json=False.
    HTTP failures retain their status code as urllib.error.HTTPError, with URLs,
    server reasons, response bodies and headers removed from the exception.
    """

    def __init__(self, endpoint, project_url, token=None):
        self.endpoint, self._origin, self._path = _endpoint(endpoint, 'GitLab API endpoint')
        _, project_origin = _url(project_url, 'GitLab project URL')
        if self._origin != project_origin:
            raise ValueError('GitLab API endpoint origin does not match the provider project URL origin.')
        configured_base = os.environ.get('GITLAB_BASE_URL')
        if configured_base:
            _, configured_origin, configured_path = _endpoint(configured_base, 'GITLAB_BASE_URL')
            if (self._origin, self._path) != (configured_origin, configured_path):
                raise ValueError('GitLab API endpoint does not match GITLAB_BASE_URL.')
        # Authority checks intentionally precede all credential lookup/transport.
        self._token = token if token is not None else (os.environ.get('GITLAB_API_TOKEN') or os.environ.get('GITLAB_TOKEN'))
        if not self._token:
            raise ValueError('Set GITLAB_API_TOKEN or GITLAB_TOKEN for GitLab API access.')
        if not isinstance(self._token, str) or any(ord(char) < 32 or ord(char) == 127 for char in self._token):
            raise ValueError('GitLab API token contains invalid header characters.')
        self._opener = urllib.request.build_opener(_RejectRedirects())

    def request(self, method, suffix, body=None, decode_json=True):
        if (not isinstance(suffix, str) or not suffix.startswith('/') or suffix.startswith('//')
                or '\\' in suffix or any(ord(char) <= 32 or ord(char) == 127 for char in suffix)):
            raise ValueError('GitLab API request suffix must be an API-relative path.')
        parsed = urllib.parse.urlsplit(suffix)
        decoded_path = urllib.parse.unquote(parsed.path)
        if (parsed.scheme or parsed.netloc or parsed.fragment
                or any(part in {'.', '..'} for part in decoded_path.split('/'))):
            raise ValueError('GitLab API request suffix must stay within the configured API endpoint.')
        if method not in {'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'}:
            raise ValueError('Unsupported GitLab API request method.')
        try:
            data = None if body is None else json.dumps(body, allow_nan=False).encode('utf-8')
        except (TypeError, ValueError):
            raise ValueError('GitLab API request body must be JSON serializable.') from None
        request = urllib.request.Request(
            self.endpoint + suffix, data=data, method=method,
            headers={'PRIVATE-TOKEN': self._token, 'Content-Type': 'application/json'},
        )
        try:
            with self._opener.open(request, timeout=30) as response:
                content = response.read().decode('utf-8')
        except urllib.error.HTTPError as exc:
            status = exc.code
            exc.close()
            raise urllib.error.HTTPError('GitLab API', status, 'GitLab API request failed', None, io.BytesIO()) from None
        except (urllib.error.URLError, OSError):
            raise urllib.error.URLError('GitLab API connection failed.') from None
        except UnicodeError:
            raise ValueError('GitLab API response is not valid UTF-8.') from None
        if not decode_json:
            return content
        try:
            return json.loads(content)
        except ValueError:
            raise ValueError('GitLab API response is not valid JSON.') from None
