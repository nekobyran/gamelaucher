import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, dirname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(process.argv[2] || dirname(dirname(fileURLToPath(import.meta.url))));
const port = Number(process.env.PORT || process.argv[3] || 4173);
const mime = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8'
};

createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://127.0.0.1');
    const pathname = decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname);
    let file = resolve(root, `.${pathname}`);
    if (!(file === root || file.startsWith(`${root}${sep}`))) throw new Error('path traversal');

    try {
      const info = await stat(file);
      if (info.isDirectory()) file = resolve(file, 'index.html');
    } catch {
      file = resolve(root, '404.html');
      response.statusCode = 404;
    }

    const body = await readFile(file);
    response.setHeader('Content-Type', mime[extname(file)] || 'application/octet-stream');
    response.setHeader('Cache-Control', 'no-store');
    response.end(body);
  } catch (error) {
    response.statusCode = 500;
    response.end('Internal Server Error');
    console.error(error);
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`GameLauncher release site: http://127.0.0.1:${port}`);
});
