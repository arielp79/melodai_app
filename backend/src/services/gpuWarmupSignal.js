import { config } from '../config.js';
import { getRedisClient } from '../queue/redisClient.js';

/**
 * Publica señal en Redis para que un autoscaler (RunPod, etc.) pre-caliente GPU.
 * Fase 2 / AudioSep — el consumidor lo implementa fuera de este repo.
 */
export async function publishGpuWarmupSignal({ reason = 'manual', metadata = {} } = {}) {
  if (!config.redisUrl) {
    return { ok: false, error: 'REDIS_URL no configurada.' };
  }

  const redis = getRedisClient();
  const payload = JSON.stringify({
    type: 'gpu_warmup',
    reason,
    projectId: config.firebaseProjectId,
    at: new Date().toISOString(),
    ...metadata,
  });

  await redis.lpush(config.redisGpuWarmupChannel, payload);
  return { ok: true, channel: config.redisGpuWarmupChannel };
}
