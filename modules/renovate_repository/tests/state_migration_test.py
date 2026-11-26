"""Offline plans verify legacy-state safety and publisher replacement.

Set RENOVATE_TEST_TERRAFORM to select Terraform >= 1.7. Tests skip when a
compatible Terraform or initialized provider is unavailable. Only local state
and installed provider schemas are used; refresh and provider auth are disabled.
"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1]
ROOT = MODULE.parents[1]
FILE_ADDRESS = 'gitlab_repository_file.this["platform"]'
BRANCH_ADDRESS = 'gitlab_branch.this["platform"]'
PUBLISHER_ADDRESS = 'null_resource.merge_request["platform"]'


def hcl_block(source, marker):
    """Copy the real module declaration, including nested lifecycle settings."""
    start = source.index(marker)
    depth = 0
    for index in range(start, len(source)):
        depth += (source[index] == '{') - (source[index] == '}')
        if depth == 0 and source[index] == '}':
            return source[start:index + 1]
    raise AssertionError(f'The module must contain a complete {marker} block.')


def state_resource(kind, name, provider, attributes):
    return {
        'mode': 'managed', 'type': kind, 'name': name,
        'provider': f'provider["registry.terraform.io/{provider}"]',
        'instances': [{'index_key': 'platform', 'schema_version': 0, 'attributes': attributes}],
    }


class StateMigrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.terraform = os.environ.get('RENOVATE_TEST_TERRAFORM') or shutil.which('terraform')
        if not cls.terraform or not Path(cls.terraform).is_file():
            raise unittest.SkipTest('Terraform is unavailable; set RENOVATE_TEST_TERRAFORM.')
        # Do not inherit real provider credentials, logging, or CLI arguments.
        cls.environment = {
            key: value for key, value in os.environ.items()
            if not key.startswith(('GITLAB_', 'TF_'))
        }
        cls.environment.update(CHECKPOINT_DISABLE='1', TF_IN_AUTOMATION='1', TF_INPUT='0')
        version = subprocess.run(
            [cls.terraform, 'version', '-json'], env=cls.environment,
            text=True, capture_output=True, check=True, timeout=30)
        details = json.loads(version.stdout)
        numbers = tuple(int(value) for value in re.match(r'^(\d+)\.(\d+)', details['terraform_version']).groups())
        if numbers < (1, 7):
            raise unittest.SkipTest('The removed-block regression requires Terraform >= 1.7.')
        cls.platform = details['platform']
        cls.module_source = (MODULE / 'main.tf').read_text()

    def installed_provider(self, namespace, name, versions):
        candidates = [
            path for base in (MODULE, ROOT)
            for path in (base / f'.terraform/providers/registry.terraform.io/{namespace}/{name}').glob(
                f'{versions}/{self.platform}/terraform-provider-{name}_v*')
            if path.is_file()
        ]
        if not candidates:
            self.skipTest(f'An initialized {namespace}/{name} {versions} provider is unavailable.')
        return sorted(candidates)[0]

    def plan(self, blocks, resources, with_null=False, replace=None):
        providers = [('gitlabhq', 'gitlab', self.installed_provider('gitlabhq', 'gitlab', '19.*'))]
        if with_null:
            providers.append(('hashicorp', 'null', self.installed_provider('hashicorp', 'null', '3.*')))
        with tempfile.TemporaryDirectory(prefix='renovate-state-migration-') as temporary:
            work = Path(temporary)
            mirror = work / 'plugins'
            requirements = {}
            for namespace, name, binary in providers:
                version = binary.parent.parent.name
                package = mirror / f'registry.terraform.io/{namespace}/{name}' / version / self.platform
                package.parent.mkdir(parents=True)
                package.symlink_to(binary.parent.resolve(), target_is_directory=True)
                requirements[name] = {'source': f'{namespace}/{name}', 'version': f'={version}'}
            (work / 'providers.tf.json').write_text(json.dumps({
                'terraform': {'required_version': '>= 1.7', 'required_providers': requirements},
                'provider': {'gitlab': {
                    'early_auth_check': False,
                    'token': 'synthetic-offline-migration-test',
                    'base_url': 'http://127.0.0.1:1/api/v4/',
                }},
            }))
            (work / 'main.tf').write_text(blocks + '\n')
            (work / 'terraform.tfstate').write_text(json.dumps({
                'version': 4, 'terraform_version': '1.7.0', 'serial': 1,
                'lineage': 'eb12f0d5-a04c-4aa9-8349-21addb30c398',
                'outputs': {}, 'resources': resources,
            }))
            environment = dict(self.environment)
            cli_config = work / 'terraform.rc'
            cli_config.write_text('disable_checkpoint = true\n')
            environment['TF_CLI_CONFIG_FILE'] = str(cli_config)

            def terraform(*arguments):
                completed = subprocess.run(
                    [self.terraform, *arguments], cwd=work, env=environment,
                    text=True, capture_output=True, timeout=60)
                self.assertEqual(
                    completed.returncode, 0,
                    f'{arguments[0]} failed:\n{completed.stdout}\n{completed.stderr}')
                return completed.stdout

            # An explicit local plugin directory prevents registry downloads.
            terraform('init', '-backend=false', '-input=false', '-no-color', f'-plugin-dir={mirror}')
            arguments = ['plan', '-refresh=false', '-input=false', '-no-color', '-out=regression.tfplan']
            if replace:
                arguments.append(f'-replace={replace}')
            terraform(*arguments)
            return json.loads(terraform('show', '-json', 'regression.tfplan'))

    def test_legacy_file_is_forgotten_without_delete(self):
        legacy = state_resource('gitlab_repository_file', 'this', 'gitlabhq/gitlab', {
            'id': '42:terraform/renovate-old:renovate.json',
            'project': '42', 'branch': 'terraform/renovate-old', 'file_path': 'renovate.json',
            'encoding': 'text', 'content': '{"automerge":false}\n', 'overwrite_on_create': True,
        })
        plan = self.plan(hcl_block(self.module_source, 'removed {'), [legacy])
        changes = plan.get('resource_changes', [])
        self.assertEqual(len(changes), 1, changes)
        self.assertEqual(changes[0]['address'], FILE_ADDRESS)
        self.assertEqual(changes[0]['change']['actions'], ['forget'])
        self.assertFalse(any('delete' in change['change']['actions'] for change in changes))

    def test_branch_recreation_replaces_publisher_with_unchanged_name_and_content(self):
        branch = hcl_block(self.module_source, 'resource "gitlab_branch" "this"')
        publisher = hcl_block(self.module_source, 'resource "null_resource" "merge_request"')
        # Include the real branch identity trigger when declared by the module.
        identity = re.search(r'^\s*branch_id\s*=.*$', publisher, re.MULTILINE)
        identity_trigger = identity.group(0) if identity else ''
        trigger_state = {'source_branch': 'terraform/renovate-stable', 'content_sha256': 'unchanged-content-digest'}
        if identity:
            trigger_state['branch_id'] = '42:terraform/renovate-stable'
        # Use both real lifecycles while replacing only their surrounding inputs.
        blocks = '''variable "project_ids" { default = { platform = "42" } }
resource "gitlab_branch" "this" {
  for_each = { platform = true }
  project = "42"
  name = "terraform/renovate-stable"
  ref = "cccccccccccccccccccccccccccccccccccccccc"
%s
}
resource "null_resource" "merge_request" {
  for_each = { platform = true }
  triggers = {
    source_branch = "terraform/renovate-stable"
    content_sha256 = "unchanged-content-digest"
%s
  }
%s
}
''' % (hcl_block(branch, 'lifecycle {'), identity_trigger, hcl_block(publisher, 'lifecycle {'))
        resources = [
            state_resource('gitlab_branch', 'this', 'gitlabhq/gitlab', {
                'id': '42:terraform/renovate-stable', 'project': '42',
                'name': 'terraform/renovate-stable', 'ref': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                'keep_on_destroy': False,
            }),
            state_resource('null_resource', 'merge_request', 'hashicorp/null', {
                'id': 'synthetic-local-publisher',
                'triggers': trigger_state,
            }),
        ]
        baseline = self.plan(blocks, resources, with_null=True)
        self.assertTrue(all(change['change']['actions'] == ['no-op'] for change in baseline['resource_changes']))
        plan = self.plan(blocks, resources, with_null=True, replace=BRANCH_ADDRESS)
        changes = {change['address']: change for change in plan['resource_changes']}
        self.assertEqual(set(changes[BRANCH_ADDRESS]['change']['actions']), {'create', 'delete'})
        publication = changes[PUBLISHER_ADDRESS]
        self.assertEqual(set(publication['change']['actions']), {'create', 'delete'})
        self.assertEqual(publication['change']['before']['triggers']['content_sha256'], publication['change']['after']['triggers']['content_sha256'])

        # Refresh removes a deleted remote branch from state before planning.
        # Retain its publisher state to reproduce that exact scheduling input.
        recreated = self.plan(blocks, resources[1:], with_null=True)
        changes = {change['address']: change for change in recreated['resource_changes']}
        self.assertEqual(changes[BRANCH_ADDRESS]['change']['actions'], ['create'])
        publication = changes[PUBLISHER_ADDRESS]
        self.assertEqual(set(publication['change']['actions']), {'create', 'delete'})
        self.assertEqual(publication['change']['before']['triggers']['content_sha256'], publication['change']['after']['triggers']['content_sha256'])
        self.assertTrue(publication['change']['after_unknown']['triggers']['branch_id'])


if __name__ == '__main__':
    unittest.main()
