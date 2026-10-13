// Runs the real install/install.sh against a temporary HOME.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, existsSync, writeFileSync, mkdirSync, statSync, readdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const BEGIN = '<!-- agent-communication-guidelines:begin -->';
// Git Bash on Windows wants /c/... paths in HOME; elsewhere the path is used as is.
const posix = (p) => (process.platform === 'win32' ? p.replace(/^([A-Za-z]):\\/, (_, d) => `/${d.toLowerCase()}/`).replace(/\\/g, '/') : p);
const SH = posix(join(ROOT, 'install', 'install.sh'));
// install.sh targets macOS and Linux. On Windows it runs under Git Bash, where each short command can
// cost seconds (endpoint security on some machines), so one run can take minutes. Opt in there with
// ACG_TEST_SH=1 (tests\run-all.ps1 -WithShell).
const wanted = process.platform !== 'win32' || process.env.ACG_TEST_SH === '1';
const hasBash = wanted && spawnSync('bash', ['-c', 'exit 0']).status === 0;
const SKIP = !wanted ? 'set ACG_TEST_SH=1 to run install.sh tests on Windows' : !hasBash && 'bash not found';

function run(home, ...args) {
  const r = spawnSync('bash', [SH, ...args], { env: { ...process.env, HOME: posix(home) }, encoding: 'utf8' });
  return { code: r.status, out: (r.stdout || '') + (r.stderr || '') };
}
const freshHome = () => mkdtempSync(join(tmpdir(), 'acg-sh-'));
const markers = (p) => readFileSync(p, 'utf8').split(BEGIN).length - 1;

test('skills 배치로 세 도구를 모두 설치하면 스킬 폴더와 지시 블록이 생긴다', { skip: SKIP }, () => {
  const h = freshHome();
  const r = run(h, '--layout', 'skills');
  assert.equal(r.code, 0, r.out);
  assert.ok(existsSync(join(h, '.claude', 'skills', 'agent-tone', 'references', 'report-format.md')));
  assert.ok(existsSync(join(h, '.claude', 'skills', 'style-router', 'SKILL.md')));
  assert.ok(!existsSync(join(h, '.claude', 'skills', 'agent-communication-guidelines')));
  for (const f of ['mail-format.md', 'document-rules.md', 'guidelines.md', 'style-router.md']) {
    assert.ok(existsSync(join(h, '.gemini', 'skills', 'agent-communication-guidelines', 'references', f)), f);
  }
  for (const f of [['.claude', 'CLAUDE.md'], ['.gemini', 'GEMINI.md'], ['.codex', 'AGENTS.md']]) assert.equal(markers(join(h, ...f)), 1, f.join('/'));
});

test('다시 실행해도 블록이 두 번 들어가지 않고 아무것도 다시 쓰지 않는다', { skip: SKIP }, () => {
  const h = freshHome();
  assert.equal(run(h, '--layout', 'skills').code, 0);
  const p = join(h, '.codex', 'AGENTS.md');
  const before = statSync(p).mtimeMs;
  const r = run(h, '--layout', 'skills');
  assert.equal(r.code, 0, r.out);
  assert.match(r.out, /Done\. 0 written/);
  assert.equal(statSync(p).mtimeMs, before);
  assert.equal(markers(join(h, '.claude', 'CLAUDE.md')), 1);
  assert.ok(!existsSync(join(h, '.claude', 'backups')));
});

test('내용이 다른 기존 스킬 폴더는 skills 밖 backups 로 옮긴다', { skip: SKIP }, () => {
  const h = freshHome();
  const old = join(h, '.claude', 'skills', 'agent-tone');
  mkdirSync(old, { recursive: true });
  writeFileSync(join(old, 'SKILL.md'), 'old copy');
  const r = run(h, '--layout', 'skills', '--tools', 'claude');
  assert.equal(r.code, 0, r.out);
  const backups = readdirSync(join(h, '.claude', 'backups'));
  assert.equal(backups.length, 1);
  assert.equal(readFileSync(join(h, '.claude', 'backups', backups[0], 'agent-tone', 'SKILL.md'), 'utf8'), 'old copy');
  assert.notEqual(readFileSync(join(old, 'SKILL.md'), 'utf8'), 'old copy');
});

test('고른 도구만 건드린다', { skip: SKIP }, () => {
  const h = freshHome();
  assert.equal(run(h, '--tools', 'codex').code, 0);
  assert.ok(existsSync(join(h, '.codex', 'AGENTS.md')));
  assert.ok(!existsSync(join(h, '.claude')));
  assert.ok(!existsSync(join(h, '.gemini')));
});

test('dry run 은 아무것도 쓰지 않는다', { skip: SKIP }, () => {
  const h = freshHome();
  const r = run(h, '--layout', 'skills', '--dry-run');
  assert.equal(r.code, 0, r.out);
  assert.deepEqual(readdirSync(h), []);
});

test('모르는 배치나 도구 이름은 exit 2 로 거부한다', { skip: SKIP }, () => {
  const h = freshHome();
  assert.equal(run(h, '--layout', 'flat').code, 2);
  assert.equal(run(h, '--tools', 'cursor').code, 2);
  assert.deepEqual(readdirSync(h), []);
});
