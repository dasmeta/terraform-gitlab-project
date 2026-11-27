"""Run credential-free local extraction with an actual generated fleet policy."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--node', required=True, help='Supported Node executable')
    parser.add_argument('--renovate-dir', type=Path, required=True)
    parser.add_argument('--test-log', type=Path, required=True,
                        help='Successful terraform test -json -verbose output')
    args = parser.parse_args()
    policy = None
    passed = False
    for line in args.test_log.read_text().splitlines():
        event = json.loads(line)
        if event.get('type') == 'test_plan' and event.get('@testrun') == 'fleet_of_125_projects':
            policies = event['test_plan']['output_changes']['configurations']['after']
            assert len(policies) == 125
            policy = next(iter(policies.values()))
            assert all(config == policy for config in policies.values())
        if event.get('type') == 'test_summary':
            passed = event['test_summary']['status'] == 'pass'
    assert passed and policy, 'Expected successful Terraform tests and a generated fleet policy.'
    fixtures = Path(__file__).parent / 'fixtures'
    cli = args.renovate_dir.resolve() / 'dist' / 'renovate.js'
    expected = {
        ('dockerfile', 'Dockerfile', 'alpine', '3.20.0'),
        ('helmv3', 'Chart.yaml', 'base', '0.3.15'),
        ('helm-values', 'values.yaml', 'nginx', '1.26.0'),
        ('terraform', 'main.tf', 'dasmeta/project/gitlab', '1.4.1'),
        ('jsonata', 'terramate/module.yaml', 'dasmeta/project/gitlab', '1.4.1'),
    }
    with tempfile.TemporaryDirectory(prefix='renovate-extraction-') as directory:
        root = Path(directory)
        # Do not inherit bot/cloud credentials or other Renovate configuration.
        environment = {key: os.environ[key] for key in ('PATH', 'HOME', 'TMPDIR') if key in os.environ}
        environment.update({
            'RENOVATE_PLATFORM': 'local', 'RENOVATE_DRY_RUN': 'extract',
            'LOG_FORMAT': 'json', 'LOG_LEVEL': 'debug',
            'RENOVATE_BASE_DIR': str(root / 'base'),
            'RENOVATE_CACHE_DIR': str(root / 'cache'),
        })
        for name in ('arbitrary-service', 'another-name'):
            repository = root / name
            shutil.copytree(fixtures, repository)
            (repository / 'renovate.json').write_text(json.dumps(policy))
            result = subprocess.run([args.node, str(cli)], cwd=repository,
                                    env=environment, capture_output=True, text=True, timeout=120)
            assert result.returncode == 0, result.stdout + result.stderr
            extracted = set()
            for line in result.stdout.splitlines():
                event = json.loads(line)
                assert event.get('level', 0) < 50, event
                for manager, files in event.get('packageFiles', {}).items():
                    for file in files:
                        for dependency in file.get('deps', []):
                            extracted.add((manager, file['packageFile'], dependency.get('depName'), dependency.get('currentValue')))
            assert expected <= extracted, f'{name}: missing {expected - extracted}'
            print(f'{name}: verified native Docker, Helm chart/values, Terraform and shared JSONata extraction.')


if __name__ == '__main__':
    main()
