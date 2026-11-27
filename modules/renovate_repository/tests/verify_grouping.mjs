// Offline branch planning with the same Renovate runtime as the pinned chart.
// Usage: node verify_grouping.mjs /path/to/renovate terraform-tests.jsonl
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [packageDirectory, testLog] = process.argv.slice(2);
assert(packageDirectory && testLog, 'Pass Renovate package directory and successful Terraform test log.');
const load = (path) => import(pathToFileURL(resolve(packageDirectory, 'dist', path)).href);
const { init } = await load('logger/index.js');
await init();
const { getConfig } = await load('config/defaults.js');
const { mergeChildConfig } = await load('config/utils.js');
const { resolveConfigPresets } = await load('config/presets/index.js');
const { branchifyUpgrades } = await load('workers/repository/updates/branchify.js');
const { validateConfig } = await load('config/validation.js');
const { applyPackageRules } = await load('util/package-rules/index.js');
const configs = new Map();
let passed = false;
for (const line of readFileSync(testLog, 'utf8').trim().split('\n')) {
  const event = JSON.parse(line);
  if (event.type === 'test_plan' && event.test_plan.output_changes?.configurations) {
    configs.set(event['@testrun'], event.test_plan.output_changes.configurations.after);
  }
  if (event.type === 'test_summary') passed = event.test_summary.failed === 0 && event.test_summary.passed > 0;
}
assert(passed, 'Terraform suite must pass before runtime grouping checks.');
const policy = Object.values(configs.get('groups_updates_by_manager'))[0];
const validation = await validateConfig('repo', policy);
assert.equal(validation.errors.length, 0, JSON.stringify(validation.errors));
assert.equal(validation.warnings.length, 0, JSON.stringify(validation.warnings));

const beforeLookup = await applyPackageRules({ ...policy, manager: 'future-manager', packageName: 'example' });
assert.equal(beforeLookup.groupName, '{{manager}} dependencies');
assert.equal(beforeLookup.separateMajorMinor, true, 'Type separation must apply before lookup.');
assert.equal(beforeLookup.separateMinorPatch, true);
for (const updateType of ['replacement', 'lockFileMaintenance']) {
  const special = await applyPackageRules({ ...policy, manager: 'npm', updateType });
  assert(!special.groupName, `${updateType} must keep native special handling.`);
  assert.equal(special.automerge, false);
}

async function branchPlan(config, packageFiles) {
  const { config: resolved } = await resolveConfigPresets(config);
  return branchifyUpgrades({
    ...mergeChildConfig(getConfig(), resolved),
    semanticCommits: 'disabled', repoIsOnboarded: true, errors: [], warnings: [],
  }, structuredClone(packageFiles));
}

function dependency(index) {
  const updateType = ['major', 'minor', 'patch'][index % 3];
  const major = updateType === 'major' ? 2 + index % 5 : 1;
  const minor = updateType === 'minor' ? 1 + index % 5 : 0;
  const patch = updateType === 'patch' ? 1 + index % 7 : 0;
  const version = `${major}.${minor}.${patch}`;
  return {
    depName: `example-${index}`, packageName: `example-${index}`,
    datasource: 'npm', currentValue: '1.0.0', currentVersion: '1.0.0',
    updates: [{ updateType, newValue: version, newVersion: version,
      newMajor: major, newMinor: minor, newPatch: patch }],
  };
}

for (const count of [1, 2, 100]) {
  const packageFiles = Object.fromEntries(['dockerfile', 'npm', 'pip_requirements'].map((manager) => [manager, [{
    packageFile: `example/${manager}`, deps: Array.from({ length: count }, (_, index) => dependency(index)),
  }]]));
  const result = await branchPlan(policy, packageFiles);
  const typeCount = Math.min(count, 3);
  assert.equal(result.branches.length, 3 * typeCount, `${count} dependencies must group per manager and update type.`);
  assert.equal(new Set(result.branches.map((branch) => branch.branchName)).size, 3 * typeCount);
  for (const branch of result.branches) {
    const type = branch.upgrades[0].updateType;
    assert.equal(branch.upgrades.length, Array.from({ length: count }, (_, i) => dependency(i)).filter((dep) => dep.updates[0].updateType === type).length);
    assert.equal(new Set(branch.upgrades.map((upgrade) => upgrade.updateType)).size, 1);
    assert.equal(new Set(branch.upgrades.map((upgrade) => upgrade.manager)).size, 1);
    assert.equal(branch.automerge, false);
    assert(branch.prTitle.includes(`(${type})`), 'Grouped MR titles must identify major/minor/patch.');
    assert(!branch.branchName.includes('{{'), 'Manager template must be resolved.');
  }
}
const dockerOnly = await branchPlan(policy, { dockerfile: [{ packageFile: 'Dockerfile', deps: Array.from({ length: 100 }, (_, index) => dependency(index)) }] });
assert.equal(dockerOnly.branches.length, 3, 'A Docker-only repository must have three version-type groups.');

const alternativeTypes = await branchPlan(policy, { npm: [{ packageFile: 'package.json', deps: [{
  ...dependency(0), updates: [dependency(0).updates[0], dependency(1).updates[0], dependency(2).updates[0]],
}] }] });
assert.equal(alternativeTypes.branches.length, 3, 'Major, minor and patch alternatives for one package must stay separate.');
assert(alternativeTypes.branches.every((branch) => branch.upgrades.length === 1));

const multipleFiles = await branchPlan(policy, { dockerfile: [
  { packageFile: 'one/Dockerfile', deps: Array.from({ length: 50 }, (_, index) => dependency(index)) },
  { packageFile: 'two/Dockerfile', deps: Array.from({ length: 50 }, (_, index) => dependency(index + 50)) },
] });
assert.equal(multipleFiles.branches.length, 3, 'Files from one manager share groups by version type.');
assert.equal(multipleFiles.branches.reduce((sum, branch) => sum + branch.upgrades.length, 0), 100);

const inheritedGroups = await branchPlan(policy, { npm: [{ packageFile: 'package.json', deps: [
  { ...dependency(0), groupSlug: 'inherited-monorepo-one' },
  { ...dependency(1), groupSlug: 'inherited-monorepo-two' },
] }] });
assert.equal(inheritedGroups.branches.length, 2, 'Inherited preset group slugs must not add groups beyond manager/type.');

const inheritedAcrossManagers = await branchPlan(policy, Object.fromEntries(['dockerfile', 'npm', 'pip_requirements'].map((manager) => [manager, [{
  packageFile: `example/${manager}`, deps: [
    { ...dependency(0), groupSlug: 'inherited-monorepo-one' },
    { ...dependency(1), groupSlug: 'inherited-monorepo-two' },
  ],
}]])));
assert.equal(inheritedAcrossManagers.branches.length, 6, 'Templated manager/type groups must stay distinct despite inherited preset slugs.');

const manual = Object.values(configs.get('explicit_repository_grouping_overrides_default'))[0];
const manualResult = await branchPlan(manual, { npm: [{ packageFile: 'package.json', deps: [dependency(0), dependency(1)] }] });
assert.equal(manualResult.branches.length, 1, 'Explicit inline rules can combine types despite the generic default.');
assert(manualResult.branches.every((branch) => branch.groupName === 'manual JavaScript group'));

const protectedPolicy = Object.values(configs.get('shared_defaults_and_exact_owned_paths'))[0];
// Avoid the fixture's intentionally nonexistent shared preset; package rules are local.
const protection = await branchPlan({ ...protectedPolicy, extends: ['config:recommended'] }, { dockerfile: [
  { packageFile: 'generated/deploy.yml', deps: [dependency(0)] },
  { packageFile: 'manual/generated/deploy.yml', deps: [dependency(1)] },
] });
assert.equal(protection.branches.length, 1);
assert.equal(protection.branches[0].upgrades.length, 1);
assert.equal(protection.branches[0].upgrades[0].packageFile, 'manual/generated/deploy.yml');
console.log('Pinned Renovate: 1/2/100 updates group by manager and major/minor/patch; target-version streams stay together; MR titles, inline overrides and protected files verified.');
