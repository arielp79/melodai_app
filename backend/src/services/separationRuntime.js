import { config } from '../config.js';
import { checkRedisConnection } from '../queue/redisClient.js';

/** Modo efectivo tras comprobar Redis (puede ser `stub` aunque .env diga `redis`). */
export let effectiveWorkerMode = config.separationWorkerMode;

export async function initSeparationRuntime() {
  if (config.separationWorkerMode !== 'redis') {
    effectiveWorkerMode = 'stub';
    return;
  }

  const redisOk = await checkRedisConnection();
  if (redisOk) {
    effectiveWorkerMode = 'redis';
    console.info('[melodai] Redis OK — cola activa para el worker Python.');
    return;
  }

  if (config.separationRedisFallbackStub) {
    effectiveWorkerMode = 'stub';
    console.warn(
      '[melodai] Redis no alcanzable en REDIS_URL → separación en modo stub (Node).',
    );
    console.warn(
      '[melodai] Para usar el worker Python: Upstash (rediss://), Docker, o Memurai en Windows.',
    );
    return;
  }

  effectiveWorkerMode = 'redis';
  console.error(
    '[melodai] Redis requerido pero no disponible. Define SEPARATION_REDIS_FALLBACK_STUB=true o arranca Redis.',
  );
}
