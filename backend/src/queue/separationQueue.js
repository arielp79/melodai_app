import { config } from '../config.js';
import { findJobById } from '../db/separationJobsRepository.js';
import { getRedisClient } from './redisClient.js';

export async function pushSeparationJob(jobId) {
  const job = await findJobById(jobId);
  if (!job) {
    throw new Error(`Job ${jobId} no existe.`);
  }

  const redis = getRedisClient();
  const payload = JSON.stringify({
    jobId: job.jobId,
    userId: job.userId,
    sha256: job.sha256,
    objectKey: job.objectKey,
    fileName: job.fileName,
    phase: job.phase ?? 1,
    gcsBucket: config.gcsBucketName,
    enqueuedAt: new Date().toISOString(),
  });

  await redis.lpush(config.redisSeparationQueue, payload);
  console.info(`[separation] Job ${jobId} encolado en ${config.redisSeparationQueue}`);
}
