import https from 'node:https';

/** POST JSON usando https nativo (evita fallos SSL de `fetch` en algunos Windows). */
export function httpsPostJson(url, body) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);
    const parsed = new URL(url);

    const req = https.request(
      {
        hostname: parsed.hostname,
        port: parsed.port || 443,
        path: `${parsed.pathname}${parsed.search}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          try {
            resolve({ status: res.statusCode ?? 500, body: JSON.parse(text) });
          } catch {
            reject(new Error(`Respuesta no JSON (${res.statusCode}): ${text.slice(0, 200)}`));
          }
        });
      },
    );

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}
