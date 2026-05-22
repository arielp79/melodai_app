import 'dotenv/config';

/** Firebase Console muestra gs://…; el SDK espera solo el nombre del bucket. */
export function normalizeGcsBucketName(raw) {
  const trimmed = raw?.trim();
  if (!trimmed) return null;
  return trimmed.replace(/^gs:\/\//i, '').replace(/\/+$/, '');
}

const port = Number(process.env.PORT ?? 3000);
const redisUrl = process.env.REDIS_URL?.trim() || null;
const workerModeEnv = process.env.SEPARATION_WORKER_MODE?.trim()?.toLowerCase();

/** stub = Node in-process; redis = cola + worker Python */
function resolveSeparationWorkerMode() {
  if (workerModeEnv === 'stub' || workerModeEnv === 'redis') {
    return workerModeEnv;
  }
  return redisUrl ? 'redis' : 'stub';
}

export const config = {
  port: Number.isFinite(port) ? port : 3000,
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? 'melodaiapp',
  /** Misma Web API Key que Flutter (`DefaultFirebaseOptions.windows.apiKey`). */
  firebaseWebApiKey: process.env.FIREBASE_WEB_API_KEY?.trim() || null,
  /** Vacío = autodetectar entre .appspot.com y .firebasestorage.app (sin prefijo gs://) */
  gcsBucketName: normalizeGcsBucketName(process.env.GCS_BUCKET_NAME),
  googleApplicationCredentials: process.env.GOOGLE_APPLICATION_CREDENTIALS,
  mongodbUri: process.env.MONGODB_URI?.trim() || null,
  mongodbDb: process.env.MONGODB_DB ?? 'melodai',
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  authDisabled: process.env.AUTH_DISABLED === 'true',
  presignExpiresMinutes: Number(process.env.PRESIGN_EXPIRES_MINUTES ?? 15),
  maxUploadBytes: Number(process.env.MAX_UPLOAD_BYTES ?? 500 * 1024 * 1024),
  redisUrl,
  redisSeparationQueue: process.env.REDIS_SEPARATION_QUEUE ?? 'melodai:separation:jobs',
  separationWorkerMode: resolveSeparationWorkerMode(),
  /** Si Redis no responde, usar stub en Node en lugar de fallar el job. */
  separationRedisFallbackStub: process.env.SEPARATION_REDIS_FALLBACK_STUB !== 'false',
  /** Simula inferencia Fase 1 en modo stub Node o worker Python (ms). */
  separationStubDelayMs: Number(process.env.SEPARATION_STUB_DELAY_MS ?? 8000),
  /** Clave compartida orquestador ↔ worker (`X-Worker-Key`). */
  workerApiKey: process.env.WORKER_API_KEY?.trim() || null,
  /** URL base que usa el worker para callbacks (p. ej. http://127.0.0.1:3000). */
  orchestratorPublicUrl:
    process.env.ORCHESTRATOR_PUBLIC_URL?.trim() || `http://127.0.0.1:${Number.isFinite(port) ? port : 3000}`,
  /** Cola Redis para señal de pre-calentamiento GPU (Fase 2 / AudioSep). */
  redisGpuWarmupChannel:
    process.env.REDIS_GPU_WARMUP_CHANNEL?.trim() || 'melodai:gpu:warmup',
  nodeEnv: process.env.NODE_ENV ?? 'development',
};
