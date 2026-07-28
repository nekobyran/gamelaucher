import { cp, mkdir, rm, access } from 'node:fs/promises';
import { constants } from 'node:fs';
import { resolve, dirname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = resolve(root, process.argv[2] || 'dist');
const staging = `${output}.staging-${process.pid}`;
const files = [
  'index.html', 'styles.css', 'app.js', 'release.json', 'site.config.json',
  '404.html', '_headers', '_redirects', '.nojekyll'
];

if (output === root || root.startsWith(`${output}${sep}`)) {
  throw new Error('Build output must not contain the source root.');
}

await rm(staging, { recursive: true, force: true });
await mkdir(staging, { recursive: true });

try {
  for (const file of files) {
    await access(resolve(root, file), constants.R_OK);
    await cp(resolve(root, file), resolve(staging, file), { force: true });
  }
  await cp(resolve(root, 'assets'), resolve(staging, 'assets'), { recursive: true, force: true });
  await mkdir(dirname(output), { recursive: true });
  await rm(output, { recursive: true, force: true });
  await cp(staging, output, { recursive: true, force: true });
  console.log(JSON.stringify({ ok: true, output, files: files.length + 3 }, null, 2));
} finally {
  await rm(staging, { recursive: true, force: true });
}
