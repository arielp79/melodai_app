import cors from 'cors';
import express from 'express';
import admin from 'firebase-admin';

import { config } from './config.js';
import {
  closeAudioUploadsRepository,
  connectAudioUploadsRepository,
} from './db/audioUploadsRepository.js';
import {
  closeSeparationJobsRepository,
  connectSeparationJobsRepository,
} from './db/separationJobsRepository.js';
import {
  credentialsFileExists,
  loadFirebaseCredential,
  logStartupDiagnostics,
} from './lib/credentials.js';
import { checkRedisConnection, closeRedisClient } from './queue/redisClient.js';
import { initSeparationRuntime, effectiveWorkerMode } from './services/separationRuntime.js';
import { internalRouter } from './routes/internal.js';
import { resolveStorageBucket } from './services/storageService.js';
import { separationRouter } from './routes/separation.js';
import { uploadsRouter } from './routes/uploads.js';

const firebaseOptions = {
  projectId: config.firebaseProjectId,
  storageBucket: config.gcsBucketName,
};
const credential = loadFirebaseCredential();
if (credential) {
  firebaseOptions.credential = credential;
}
admin.initializeApp(firebaseOptions);

const app = express();

app.use(
  cors({
    origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(','),
  }),
);
app.use(express.json({ limit: '1mb' }));

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const pathLogged = req.originalUrl ?? req.url;
    console.info(`[http] ${req.method} ${pathLogged} → ${res.statusCode} (${Date.now() - start}ms)`);
  });
  next();
});

app.get('/health', async (_req, res) => {
  const redisConfigured = Boolean(config.redisUrl);
  const redisOk = redisConfigured ? await checkRedisConnection() : false;

  res.json({
    status: 'ok',
    service: 'melodai-orchestrator',
    separation: {
      configMode: config.separationWorkerMode,
      effectiveMode: effectiveWorkerMode,
      redisConfigured,
      redisOk,
      redisFallbackStub: config.separationRedisFallbackStub,
    },
    storage: {
      bucket: config.gcsBucketName || null,
      credentials: credentialsFileExists(),
    },
  });
});

app.use('/uploads', uploadsRouter);
app.use('/separation', separationRouter);
app.use('/internal', internalRouter);

app.use((err, _req, res, _next) => {
  if (res.headersSent) {
    console.error('[unhandled] (respuesta ya enviada)', err);
    return;
  }
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Cuerpo JSON inválido.' });
  }
  console.error('[unhandled]', err);
  res.status(500).json({
    error: 'Error interno del servidor.',
    detail: err instanceof Error ? err.message : String(err),
  });
});

await connectAudioUploadsRepository();
await connectSeparationJobsRepository();
await initSeparationRuntime();
logStartupDiagnostics();

app.listen(config.port, () => {
  console.info(`[melodai] Orquestador en http://127.0.0.1:${config.port}`);
  console.info(
    `[melodai] Separación: modo ${effectiveWorkerMode}` +
      (effectiveWorkerMode !== config.separationWorkerMode
        ? ` (config=${config.separationWorkerMode})`
        : ''),
  );
  if (effectiveWorkerMode === 'redis' && config.workerApiKey) {
    console.info('[melodai] Worker API interna: POST /internal/separation/jobs/:id/*');
  }
  if (!credentialsFileExists()) {
    console.warn('[melodai] Las subidas fallarán hasta configurar service-account.json');
  }
});

try {
  await resolveStorageBucket();
} catch (error) {
  console.error('[melodai]', error.message);
}

process.on('unhandledRejection', (reason) => {
  console.error('[melodai] unhandledRejection:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('[melodai] uncaughtException:', error);
});

process.on('SIGINT', async () => {
  await closeAudioUploadsRepository();
  await closeSeparationJobsRepository();
  await closeRedisClient();
  process.exit(0);
});
