// Checks the rule files that ship, not copies of them.
// Budgets are documented in GUIDELINES.md "규칙 관리"; change both together.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const TONE = join(ROOT, 'skills', 'agent-tone');
const REFS = join(TONE, 'references');
const BUDGET = { core: 200, reference: 220, mandate: 30 };

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const lineCount = (t) => t.replace(/\n$/, '').split('\n').length;
const refFiles = () => readdirSync(REFS).filter((f) => f.endsWith('.md')).map((f) => join(REFS, f));

function mdFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (name === '.git' || name === 'node_modules') continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...mdFiles(p));
    else if (name.endsWith('.md')) out.push(p);
  }
  return out;
}

// Files that cite agent-tone section numbers. Bundled third-party skills keep their own numbering.
const CITING = () => [
  join(TONE, 'SKILL.md'),
  ...refFiles(),
  join(ROOT, 'skills', 'style-router', 'SKILL.md'),
  join(ROOT, 'skills', 'humanize-ko', 'SKILL.md'),
  ...readdirSync(join(ROOT, 'install', 'snippets')).map((f) => join(ROOT, 'install', 'snippets', f)),
  join(ROOT, 'install', 'gemini-skill', 'SKILL.md'),
  join(ROOT, 'install', 'README.md'),
  join(ROOT, 'README.md'),
  join(ROOT, 'GUIDELINES.md'),
  ...readdirSync(join(ROOT, 'examples')).filter((f) => f.endsWith('.md')).map((f) => join(ROOT, 'examples', f)),
];

test('핵심 SKILL.md 가 분량 상한을 넘으면 실패한다', () => {
  const n = lineCount(read(join(TONE, 'SKILL.md')));
  assert.ok(n <= BUDGET.core, `SKILL.md ${n} lines > ${BUDGET.core}`);
});

test('references 파일 하나라도 분량 상한을 넘으면 실패한다', () => {
  const files = refFiles();
  assert.ok(files.length >= 4, `expected the split references, found ${files.length}`);
  for (const p of files) {
    const n = lineCount(read(p));
    assert.ok(n <= BUDGET.reference, `${relative(ROOT, p)} ${n} lines > ${BUDGET.reference}`);
  }
});

test('매 세션 로드되는 mandate-core.md 가 상한을 넘으면 실패한다', () => {
  const n = lineCount(read(join(ROOT, 'install', 'snippets', 'mandate-core.md')));
  assert.ok(n <= BUDGET.mandate, `mandate-core.md ${n} lines > ${BUDGET.mandate}`);
});

test('SKILL.md 와 설치 조각이 가리키는 references 파일이 없으면 실패한다', () => {
  const extra = new Set(['guidelines.md', 'style-router.md']); // written by the installer into the Gemini skill
  const sources = [join(TONE, 'SKILL.md'), join(ROOT, 'install', 'snippets', 'mandate-core.md'), join(ROOT, 'install', 'gemini-skill', 'SKILL.md')];
  let seen = 0;
  for (const src of sources) {
    for (const m of read(src).matchAll(/references\/([\w.-]+\.md)/g)) {
      seen++;
      const ok = existsSync(join(REFS, m[1])) || extra.has(m[1]);
      assert.ok(ok, `${relative(ROOT, src)} points to missing references/${m[1]}`);
    }
  }
  assert.ok(seen >= 5, `expected references pointers, found ${seen}`);
});

test('옛 절 번호(§2.1, §6.9, §8 같은 형식)가 남아 있으면 실패한다', () => {
  const bad = [];
  for (const p of CITING()) {
    if (!existsSync(p)) continue;
    for (const m of read(p).matchAll(/§\s?(\d+)(\.\d+)?/g)) {
      if (m[2] || Number(m[1]) > 7) bad.push(`${relative(ROOT, p)}: ${m[0]}`);
    }
  }
  assert.deepEqual(bad, []);
});

test('D·R·M 번호 참조가 없는 항목을 가리키면 실패한다', () => {
  const ids = new Set();
  for (const p of refFiles()) for (const m of read(p).matchAll(/^## ([DRM]\d+)\./gm)) ids.add(m[1]);
  assert.ok(ids.has('D12') && ids.has('R10') && ids.has('M3'), `headings found: ${[...ids].join(',')}`);
  const bad = [];
  for (const p of CITING()) {
    if (!existsSync(p)) continue;
    for (const m of read(p).matchAll(/(?<![\w-])([DRM]\d{1,2})(?![\w-])/g)) {
      if (!ids.has(m[1])) bad.push(`${relative(ROOT, p)}: ${m[1]}`);
    }
  }
  assert.deepEqual(bad, []);
});

test('저장소 안 마크다운 상대 링크가 깨져 있으면 실패한다', () => {
  const bad = [];
  for (const p of mdFiles(ROOT)) {
    for (const m of read(p).matchAll(/\]\((?!https?:|mailto:|#)([^)\s]+)\)/g)) {
      const target = decodeURIComponent(m[1].split('#')[0]);
      if (target && !existsSync(resolve(dirname(p), target))) bad.push(`${relative(ROOT, p)} -> ${m[1]}`);
    }
  }
  assert.deepEqual(bad, []);
});

test('SKILL.md 프런트매터에 name 과 1024자 이하 description 이 없으면 실패한다', () => {
  const t = read(join(TONE, 'SKILL.md'));
  const fm = t.match(/^---\n([\s\S]*?)\n---\n/);
  assert.ok(fm, 'frontmatter missing');
  assert.match(fm[1], /^name: agent-tone$/m);
  const d = fm[1].match(/^description: (.+)$/m);
  assert.ok(d && d[1].length <= 1024, `description length ${d && d[1].length}`);
});

test('SKILL.md 프런트매터의 따옴표 없는 값에 ": " 가 있으면 YAML 이 깨지므로 실패한다', () => {
  const files = [
    ...readdirSync(join(ROOT, 'skills')).map((d) => join(ROOT, 'skills', d, 'SKILL.md')),
    join(ROOT, 'install', 'gemini-skill', 'SKILL.md'),
  ].filter(existsSync);
  const bad = [];
  for (const p of files) {
    const fm = read(p).match(/^---\n([\s\S]*?)\n---\n/);
    if (!fm) { bad.push(`${relative(ROOT, p)}: no frontmatter`); continue; }
    for (const line of fm[1].split('\n')) {
      const m = line.match(/^[\w-]+: (.*)$/);
      if (m && !/^["'|>]/.test(m[1]) && /: |\s#/.test(m[1])) bad.push(`${relative(ROOT, p)}: ${line.slice(0, 60)}`);
    }
  }
  assert.deepEqual(bad, []);
});

test('agent-tone 제목 줄에 줄표 촌평이나 이모지가 있으면 실패한다', () => {
  const bad = [];
  for (const p of [join(TONE, 'SKILL.md'), ...refFiles()]) {
    for (const line of read(p).split('\n')) {
      if (/^#{1,4} /.test(line) && /[—–]|\p{Extended_Pictographic}/u.test(line)) bad.push(`${relative(ROOT, p)}: ${line}`);
    }
  }
  assert.deepEqual(bad, []);
});
