import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const dataDir = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../.data',
);

export async function loadJsonMap(filename) {
  try {
    const raw = await fs.readFile(path.join(dataDir, filename), 'utf8');
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return new Map();
    return new Map(Object.entries(parsed));
  } catch (err) {
    if (err?.code === 'ENOENT') return new Map();
    console.warn(`[melodai] No se pudo cargar ${filename}:`, err.message);
    return new Map();
  }
}

export function saveJsonMap(filename, map) {
  const filePath = path.join(dataDir, filename);
  const payload = JSON.stringify(Object.fromEntries(map), null, 2);
  return fs
    .mkdir(dataDir, { recursive: true })
    .then(() => fs.writeFile(filePath, payload, 'utf8'))
    .catch((err) => {
      console.warn(`[melodai] No se pudo guardar ${filename}:`, err.message);
    });
}
