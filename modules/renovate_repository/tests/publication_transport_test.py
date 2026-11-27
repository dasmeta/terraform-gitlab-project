"""The real Terraform local-exec must receive large JSON through an apply-time file."""
import hashlib
import json
from pathlib import Path
import tempfile
import state_migration_test as state_tests


MODULE = Path(__file__).resolve().parents[1]


class PublicationTransportTest(state_tests.StateMigrationTest):
    # The inherited migration tests already run in their own test case.
    test_legacy_file_is_forgotten_without_delete = None
    test_branch_recreation_replaces_publisher_with_unchanged_name_and_content = None

    def test_large_file_cache_and_publication_have_separate_lifecycles(self):
        source = (MODULE / 'main.tf').read_text()
        self.assertIn('resource "local_file" "proposal"', source,
                      'Publication needs an apply-time file instead of an environment payload.')
        resource = state_tests.hcl_block(source, 'resource "local_file" "proposal"')
        publication = state_tests.hcl_block(source, 'resource "null_resource" "publish"')
        binaries = [
            ('hashicorp', name, self.installed_provider('hashicorp', name, version))
            for name, version in [('local', '2.*'), ('null', '3.*')]
        ]
        # Exceeds both Linux single-string and common macOS total exec limits.
        content = json.dumps({'name': 'example', 'renovate': {}, 'description': '\u03bb' * 700000}, ensure_ascii=False) + '\n'
        with tempfile.TemporaryDirectory(prefix='renovate-payload-') as temporary:
            work = Path(temporary)
            mirror = work / 'plugins'
            requirements = {}
            for namespace, name, binary in binaries:
                version = binary.parent.parent.name
                package = mirror / f'registry.terraform.io/{namespace}/{name}' / version / self.platform
                package.parent.mkdir(parents=True)
                package.symlink_to(binary.parent.resolve(), target_is_directory=True)
                requirements[name] = {'source': f'{namespace}/{name}', 'version': f'={version}'}
            (work / 'providers.tf.json').write_text(json.dumps({'terraform': {'required_providers': requirements}}))
            (work / 'input.auto.tfvars.json').write_text(json.dumps({'payload': content}))
            (work / 'main.tf').write_text('''
variable "payload" {
  type = string
  sensitive = true
}
variable "project_ids" { default = { platform = "42" } }
variable "endpoint" { default = "https://example.invalid/api/v4" }
locals {
  projects = { platform = true }
  file_contents = { platform = var.payload }
  source_branches = { platform = "terraform/renovate-test" }
}
resource "null_resource" "merge_request" {
  for_each = local.projects
  triggers = {
    endpoint = var.endpoint
    project = "42"
    project_url = "https://example.invalid/example/project"
    source_branch = local.source_branches[each.key]
    target_branch = "main"
    title = "Configure Renovate"
    file_path = "package.json"
    content_sha256 = sha256(var.payload)
    source_content_sha256 = ""
  }
}
''' + resource + '\n' + publication)
            scripts = work / 'scripts'
            scripts.mkdir()
            (scripts / 'ensure_merge_request.py').write_text('''
import hashlib, os
from pathlib import Path
if Path('fail-publication').exists():
    raise SystemExit(1)
assert 'GITLAB_CONFIG_CONTENT' not in os.environ
raw = Path(os.environ['GITLAB_CONFIG_CONTENT_FILE']).read_bytes()
assert len(raw) > 1024 * 1024
assert hashlib.sha256(raw).hexdigest() == os.environ['GITLAB_CONFIG_CONTENT_SHA256']
marker = Path('publications.txt')
with marker.open('a') as stream:
    stream.write(hashlib.sha256(raw).hexdigest() + '\\n')
''')
            cli_config = work / 'terraform.rc'
            cli_config.write_text('disable_checkpoint = true\n')
            environment = dict(self.environment, TF_CLI_CONFIG_FILE=str(cli_config))

            def terraform(*args, succeeds=True):
                import subprocess
                result = subprocess.run([self.terraform, *args], cwd=work, env=environment,
                                        text=True, capture_output=True, timeout=60)
                if succeeds:
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                else:
                    self.assertNotEqual(result.returncode, 0, 'The synthetic publication must fail.')
                return result.stdout

            terraform('init', '-backend=false', '-input=false', '-no-color', f'-plugin-dir={mirror}')
            terraform('apply', '-auto-approve', '-input=false', '-no-color')
            expected = hashlib.sha256(content.encode()).hexdigest()
            self.assertEqual((work / 'publications.txt').read_text().splitlines(), [expected])
            files = list((work / '.terraform' / 'renovate').rglob('*.json'))
            self.assertEqual(len(files), 1)
            self.assertEqual(files[0].read_bytes(), content.encode())
            self.assertEqual(files[0].stat().st_mode & 0o777, 0o600)
            self.assertEqual(files[0].parent.stat().st_mode & 0o777, 0o700)
            # Normal CI refresh with state retained and only runner cache lost.
            files[0].unlink()
            terraform('plan', '-input=false', '-no-color', '-out=clean-runner.tfplan')
            cache_plan = json.loads(terraform('show', '-json', 'clean-runner.tfplan'))
            actions = {entry['address']: entry['change']['actions'] for entry in cache_plan['resource_changes']}
            self.assertEqual(actions['local_file.proposal["platform"]'], ['create'])
            self.assertEqual(actions['null_resource.publish["platform"]'], ['no-op'])
            self.assertEqual(actions['null_resource.merge_request["platform"]'], ['no-op'])
            terraform('apply', '-input=false', '-no-color', 'clean-runner.tfplan')
            self.assertEqual(files[0].read_bytes(), content.encode())
            self.assertEqual((work / 'publications.txt').read_text().splitlines(), [expected],
                             'Restoring runner cache must not invoke the publication helper.')
            terraform('plan', '-refresh=false', '-input=false', '-no-color',
                      '-replace=null_resource.merge_request["platform"]', '-out=retry.tfplan')
            # A saved plan must materialize the file on its apply runner, even if
            # the file seen at plan time is absent there.
            files[0].unlink()
            terraform('apply', '-input=false', '-no-color', 'retry.tfplan')
            self.assertEqual((work / 'publications.txt').read_text().splitlines(), [expected, expected])
            # An ordinary proposal-content change still publishes exactly once.
            changed = content + ' '
            (work / 'input.auto.tfvars.json').write_text(json.dumps({'payload': changed}))
            terraform('apply', '-auto-approve', '-input=false', '-no-color')
            changed_digest = hashlib.sha256(changed.encode()).hexdigest()
            self.assertEqual((work / 'publications.txt').read_text().splitlines(),
                             [expected, expected, changed_digest])
            # A failed publication remains retryable with a clean runner cache.
            (work / 'fail-publication').touch()
            terraform('apply', '-auto-approve', '-input=false', '-no-color',
                      '-replace=null_resource.publish["platform"]', succeeds=False)
            (work / 'fail-publication').unlink()
            files[0].unlink()
            terraform('plan', '-input=false', '-no-color', '-out=failed-retry.tfplan')
            terraform('apply', '-input=false', '-no-color', 'failed-retry.tfplan')
            self.assertEqual((work / 'publications.txt').read_text().splitlines(),
                             [expected, expected, changed_digest, changed_digest])
            plan = terraform('plan', '-input=false', '-no-color', '-out=stable.tfplan')
            self.assertIn('No changes.', plan)
