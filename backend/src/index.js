import './bootstrapEnv.js';

import cors from 'cors';
import express from 'express';
import admin from 'firebase-admin';

import { config } from './config.js';
import {
  closeAudioUploadsRepository,
  connectAudioUploadsRepository,
  isAudioUploadsReady,
} from './db/audioUploadsRepository.js';
import {
  closeSeparationJobsRepository,
  connectSeparationJobsRepository,
  isSeparationJobsReady,
} from './db/separationJobsRepository.js';
import {
  credentialsFileExists,
  isGoogleManagedRuntime,
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

if (process.env.NODE_ENV === 'production') {
  app.set('trust proxy', 1);
}

app.use(
  cors({
    origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(','),
  }),
);
app.use(express.json({ limit: '1mb' }));

let dependenciesReady = false;
/** @type {string | null} */
let lastMongoConnectError = null;

app.use((req, res, next) => {
  if (dependenciesReady || req.path === '/health') {
    return next();
  }
  return res.status(503).json({
    error: 'Servidor iniciando. Reintenta en unos segundos.',
  });
});

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
      credentials: credentialsFileExists() || isGoogleManagedRuntime(),
      credentialsMode: credentialsFileExists()
        ? 'file'
        : isGoogleManagedRuntime()
          ? 'applicationDefault'
          : 'missing',
    },
    persistence: {
      mongodbConfigured: Boolean(config.mongodbUri),
      mongodbDb: config.mongodbDb,
      mongodbReady: isAudioUploadsReady() && isSeparationJobsReady(),
      dependenciesReady,
      mongodbError: lastMongoConnectError,
    },
    environment: process.env.NODE_ENV ?? 'development',
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

function logProductionWarnings() {
  if (config.nodeEnv !== 'production') return;
  if (config.authDisabled) {
    console.error('[melodai] AUTH_DISABLED=true en producción — desactiva antes de exponer el servicio.');
  }
  if (!config.mongodbUri) {
    console.error('[melodai] MONGODB_URI obligatoria en producción.');
  }
  if (!config.workerApiKey) {
    console.error('[melodai] WORKER_API_KEY obligatoria en producción.');
  }
  if (config.separationRedisFallbackStub) {
    console.warn(
      '[melodai] SEPARATION_REDIS_FALLBACK_STUB=true — los jobs pueden completarse en stub si Redis falla.',
    );
  }
}

/** Render/Cloud Run: escuchar antes que Mongo/Redis (health check en /health). */
app.listen(config.port, '0.0.0.0', () => {
  const publicUrl = config.orchestratorPublicUrl;
  console.info(`[melodai] Orquestador escuchando en 0.0.0.0:${config.port} (${publicUrl})`);
});

async function connectDependencies() {
  try {
    await connectAudioUploadsRepository();
    await connectSeparationJobsRepository();
    dependenciesReady = true;
    await initSeparationRuntime();
    logStartupDiagnostics();
    logProductionWarnings();
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
      console.warn('[melodai] Las subidas fallarán hasta configurar credenciales GCS.');
    }
  } catch (error) {
    lastMongoConnectError =
      error instanceof Error ? error.message : String(error);
    console.error('[melodai] Error conectando dependencias (Mongo/Redis):', error);
    logProductionWarnings();
    console.error(
      '[melodai] API bloqueada hasta MongoDB OK. Revisa MONGODB_URI en Render y Atlas 0.0.0.0/0.',
    );
  }
}

connectDependencies();

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
