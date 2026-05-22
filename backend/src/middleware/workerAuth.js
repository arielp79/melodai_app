import { config } from '../config.js';

/** Autenticación del worker Python vía cabecera compartida (no Firebase). */
export function requireWorkerAuth(req, res, next) {
  const expected = config.workerApiKey;
  if (!expected) {
    return res.status(503).json({
      error: 'Worker API no configurada.',
      hint: 'Define WORKER_API_KEY en .env del orquestador y del worker Python.',
    });
  }

  const provided = req.headers['x-worker-key'] ?? '';
  if (provided !== expected) {
    return res.status(401).json({ error: 'Clave de worker inválida.' });
  }

  return next();
}
