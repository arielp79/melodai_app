import Redis from 'ioredis';

import { config } from '../config.js';

let client;

function redisOptions() {
  return {
    maxRetriesPerRequest: null,
    connectTimeout: 5000,
    enableReadyCheck: true,
    retryStrategy(times) {
      if (times > 2) return null;
      return Math.min(times * 300, 1500);
    },
  };
}

export function getRedisClient() {
  if (!config.redisUrl) {
    throw new Error('REDIS_URL no configurada.');
  }
  if (!client) {
    client = new Redis(config.redisUrl, redisOptions());
    client.on('error', (err) => {
      console.error('[redis]', err.message);
    });
  }
  return client;
}

/** Comprueba conexión sin reutilizar un cliente roto. */
export async function checkRedisConnection() {
  if (!config.redisUrl) return false;

  const probe = new Redis(config.redisUrl, {
    ...redisOptions(),
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    retryStrategy: () => null,
  });

  try {
    await probe.connect();
    const pong = await probe.ping();
    await probe.quit();
    return pong === 'PONG';
  } catch {
    probe.disconnect();
    return false;
  }
}

export async function closeRedisClient() {
  if (client) {
    await client.quit();
    client = undefined;
  }
}

export async function pingRedis() {
  const redis = getRedisClient();
  if (redis.status === 'wait') {
    await redis.connect();
  }
  const pong = await redis.ping();
  return pong === 'PONG';
}
