// Native zero-dependency Node.js HTTP Server for The Forest Dashboard & API
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Helper: Lightweight zero-dependency .env loader
function loadEnv() {
  const envFiles = ['env/.env', '.env', 'default.env'];
  for (const envFile of envFiles) {
    const envPath = path.join(__dirname, envFile);
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf8');
      for (const line of content.split('\n')) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const eqIdx = trimmed.indexOf('=');
        if (eqIdx !== -1) {
          const key = trimmed.slice(0, eqIdx).trim();
          let val = trimmed.slice(eqIdx + 1).trim();
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.slice(1, -1);
          }
          if (!process.env[key]) {
            process.env[key] = val;
          }
        }
      }
    }
  }
}
loadEnv();

import statusHandler from './api/status.js';
import controlHandler from './api/control.js';
import insightsHandler from './api/insights.js';

const PORT = parseInt(process.env.DASHBOARD_PORT || process.env.PORT || '5050', 10);

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname.replace(/\/+$/, '') || '/';

  // Global CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    return res.end();
  }

  // Parse body for POST
  if (req.method === 'POST') {
    try {
      const chunks = [];
      for await (const chunk of req) {
        chunks.push(chunk);
      }
      const rawBody = Buffer.concat(chunks).toString('utf8');
      try {
        req.body = JSON.parse(rawBody);
      } catch (e) {
        req.body = rawBody;
      }
    } catch (e) {
      req.body = {};
    }
  }

  // API Routes
  if (pathname === '/api/status') {
    return statusHandler(req, res);
  }
  if (pathname === '/api/control') {
    return controlHandler(req, res);
  }
  if (pathname === '/api/insights') {
    return insightsHandler(req, res);
  }

  // Static files from public or fallback to public/index.html
  let filePath = path.join(__dirname, 'public', pathname === '/' ? 'index.html' : pathname);
  if (!fs.existsSync(filePath)) {
    filePath = path.join(__dirname, 'public', 'index.html');
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    res.setHeader('Content-Type', MIME_TYPES[ext] || 'application/octet-stream');
    return fs.createReadStream(filePath).pipe(res);
  }

  res.statusCode = 404;
  res.end('Not Found');
});

server.listen(PORT, () => {
  console.log(`Forest Insights & Management Server listening on http://localhost:${PORT}`);
  console.log(`- API Status:    http://localhost:${PORT}/api/status`);
  console.log(`- API Insights:  http://localhost:${PORT}/api/insights`);
  console.log(`- Dashboard:     http://localhost:${PORT}`);
});
