// Check generated policies with the pinned Renovate implementation, offline.
// Usage: node tests/verify_renovate.mjs /path/to/node_modules/renovate terraform-tests.jsonl
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [packageDirectory, testLog] = process.argv.slice(2);
assert(packageDirectory && testLog, 'Pass the installed Renovate directory and terraform test -json -verbose log.');
const load = (path) => import(pathToFileURL(resolve(packageDirectory, 'dist', path)).href);
const { applyPackageRules } = await load('util/package-rules/index.js');
const { resolveConfigPresets } = await load('config/presets/index.js');
const { getConfigFileNames } = await load('config/app-strings.js');
const { init } = await load('logger/index.js');
await init();
const configurations = new Map();
let passed = 0;
for (const line of readFileSync(testLog, 'utf8').trim().split('\n')) {
  const event = JSON.parse(line);
  if (event.type === 'test_plan' && event.test_plan.output_changes?.configurations) {
    configurations.set(event['@testrun'], event.test_plan.output_changes.configurations.after);
  }
  if (event.type === 'test_summary') {
    assert.equal(event.test_summary.failed, 0, 'Terraform tests must pass before policy checks.');
    passed = event.test_summary.passed;
  }
}
assert(passed > 0, 'Expected a complete successful Terraform test log.');
const policy = (run) => Object.values(configurations.get(run))[0];

for (const [run, owned] of [
  ['shared_defaults_and_exact_owned_paths', 'generated/deploy.yml'],
  ['owned_paths_escape_regex_metacharacters', 'generated/(deploy)[dev]+.yml'],
]) {
  const config = policy(run);
  // Literal ownership must survive both substring lookalikes and regex syntax.
  for (const file of [owned, `manual/${owned}`, `${owned}.backup`, 'generated/deployd.yml']) {
    const result = await applyPackageRules({
      ...config, enabled: true, automerge: true, packageFile: file,
      depName: 'example', packageName: 'example', datasource: 'docker',
    });
    assert.equal(result.enabled, file !== owned, `Incorrect ownership protection for ${file}`);
    assert.equal(result.automerge, false, `Automerge must remain disabled for ${file}`);
  }
}
const { config: resolved } = await resolveConfigPresets(policy('project_presets_override_shared_defaults'));
assert(resolved.dependencyDashboard === false || resolved.dependencyDashboard?.enabled === false,
  'The explicit project preset must override the shared default.');
const { config: existing } = await resolveConfigPresets(policy('existing_preset_order_survives_shared_duplicates'));
assert(existing.dependencyDashboard === true || existing.dependencyDashboard?.enabled === true,
  'Shared duplicate presets must not reorder existing repository policy.');
const fleet = configurations.get('fleet_of_125_projects');
assert.equal(Object.keys(fleet).length, 125);
assert.equal(new Set(Object.values(fleet).map((config) => JSON.stringify(config.customManagers))).size, 1);
assert(Object.values(fleet).every((config) => !('enabledManagers' in config)));
assert(!getConfigFileNames('gitlab').some((path) => path.startsWith('.github/')));
console.log('Pinned Renovate checks passed: exact owned paths, manual lookalikes, escaped paths, preset precedence and shared fleet extraction policy.');
