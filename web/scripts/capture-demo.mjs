import { spawn } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const chromePath = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const baseUrl = process.env.CRAMLY_CAPTURE_URL || 'http://127.0.0.1:4173';
const outputDirectory = process.env.CRAMLY_CAPTURE_OUT || path.resolve('../.codex-captures');
const port = Number(process.env.CRAMLY_CDP_PORT || 9333);
const viewport = { width: 1440, height: 900 };
const routes = [
  ['login', '/login?signedOut=1'],
  ['home', '/'],
  ['library', '/library'],
  ['course', '/library/demo-course'],
  ['upload', '/upload?courseId=demo-course'],
  ['document', '/library/demo-course/document/demo-document'],
  ['deck', '/library/demo-course/deck/demo-deck'],
  ['review', '/library/demo-course/deck/demo-deck/review'],
  ['summary', '/library/demo-course/document/demo-document/summary/demo-summary'],
  ['study', '/study'],
  ['progress', '/progress'],
  ['profile', '/profile'],
  ['not-found', '/not-a-real-route'],
];

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

async function waitForJson(url, attempts = 320) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      const response = await fetch(url);
      if (response.ok) return response.json();
    } catch {
      // Chrome may still be starting; retry until the bounded attempt limit.
    }
    await sleep(250);
  }
  throw new Error(`Chrome DevTools did not become ready at ${url}`);
}

function cdp(webSocketUrl) {
  const socket = new WebSocket(webSocketUrl);
  const pending = new Map();
  let sequence = 0;
  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (!message.id || !pending.has(message.id)) return;
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(message.error.message));
    else resolve(message.result);
  });
  const ready = new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  return {
    ready,
    send(method, params = {}) {
      const id = ++sequence;
      socket.send(JSON.stringify({ id, method, params }));
      return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
    },
    close() { socket.close(); },
  };
}

async function waitForRenderedRoute(client, attempts = 120) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    const state = await client.send('Runtime.evaluate', {
      expression: `({
        ready: document.readyState === 'complete',
        pending: Boolean(document.querySelector('.splash, .state-loading')),
        content: document.body.innerText.trim().length
      })`,
      returnByValue: true,
    });
    const value = state.result.value;
    if (value?.ready && !value.pending && value.content > 0) {
      await sleep(650);
      return;
    }
    await sleep(100);
  }
  throw new Error('The route did not finish rendering before capture.');
}

await mkdir(outputDirectory, { recursive: true });
const chrome = spawn(chromePath, [
  '--headless=new',
  '--disable-gpu',
  '--disable-background-networking',
  '--disable-component-update',
  '--disable-default-apps',
  '--disable-extensions',
  '--disable-sync',
  '--hide-scrollbars',
  '--no-first-run',
  '--remote-allow-origins=*',
  `--remote-debugging-port=${port}`,
  `--user-data-dir=/tmp/cramly-capture-${process.pid}`,
  'about:blank',
], { stdio: 'ignore' });

try {
  await waitForJson(`http://127.0.0.1:${port}/json/version`);
  for (const theme of ['light', 'dark']) {
    for (const [name, route] of routes) {
      const separator = route.includes('?') ? '&' : '?';
      const url = `${baseUrl}${route}${separator}theme=${theme}`;
      const target = await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`, { method: 'PUT' }).then((response) => response.json());
      const client = cdp(target.webSocketDebuggerUrl);
      await client.ready;
      await client.send('Page.enable');
      await client.send('Emulation.setDeviceMetricsOverride', {
        width: viewport.width,
        height: viewport.height,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await waitForRenderedRoute(client);
      await client.send('Runtime.evaluate', {
        expression: 'document.fonts.ready',
        awaitPromise: true,
        returnByValue: true,
      });
      const overflow = await client.send('Runtime.evaluate', {
        expression: '({scrollWidth: document.documentElement.scrollWidth, viewport: innerWidth})',
        returnByValue: true,
      });
      const capture = await client.send('Page.captureScreenshot', {
        format: 'png',
        fromSurface: true,
        captureBeyondViewport: false,
      });
      const file = path.join(
        outputDirectory,
        `${name}-${theme}-${viewport.width}x${viewport.height}.png`,
      );
      await writeFile(file, Buffer.from(capture.data, 'base64'));
      const metrics = overflow.result.value;
      if (metrics.scrollWidth > metrics.viewport) {
        process.stderr.write(`Horizontal overflow on ${name}-${theme}: ${metrics.scrollWidth}px > ${metrics.viewport}px\n`);
      }
      process.stdout.write(`${file}\n`);
      client.close();
      await fetch(`http://127.0.0.1:${port}/json/close/${target.id}`);
    }
  }
} finally {
  chrome.kill('SIGTERM');
  setTimeout(() => chrome.kill('SIGKILL'), 1500).unref();
}
