import {
  createJobId,
  findActiveJobForUserHash,
  findCachedSeparation,
  findJobById,
  saveJob,
} from '../db/separationJobsRepository.js';
import { buildStemObjectKeys } from './separationStems.js';
import { enqueueSeparationJob } from './separationEnqueue.js';
import { isRealSeparationCache } from '../lib/separationCache.js';
import { createPresignedGetUrl } from './storageService.js';

const SHA256_REGEX = /^[a-f0-9]{64}$/i;

export function validateCreateJobBody(body) {
  const { sha256, objectKey, fileName } = body ?? {};

  if (!sha256 || !SHA256_REGEX.test(sha256)) {
    return { error: 'sha256 debe ser un hash hexadecimal de 64 caracteres.' };
  }
  if (!objectKey || typeof objectKey !== 'string') {
    return { error: 'objectKey es obligatorio.' };
  }
  if (!objectKey.startsWith('uploads/')) {
    return { error: 'objectKey debe pertenecer a uploads/.' };
  }

  return {
    value: {
      sha256: sha256.toLowerCase(),
      objectKey: objectKey.trim(),
      fileName: typeof fileName === 'string' && fileName.trim()
        ? fileName.trim()
        : 'audio',
    },
  };
}

async function enrichStemsWithDownloadUrls(stems) {
  if (!stems?.length) return [];

  return Promise.all(
    stems.map(async (stem) => {
      if (stem.simulated) {
        return { ...stem, downloadUrl: null };
      }
      try {
        const downloadUrl = await createPresignedGetUrl({
          objectKey: stem.objectKey,
        });
        return { ...stem, downloadUrl };
      } catch {
        return { ...stem, downloadUrl: null };
      }
    }),
  );
}

async function jobToResponse(job) {
  const stems =
    job.status === 'completed'
      ? await enrichStemsWithDownloadUrls(job.stems ?? [])
      : (job.stems ?? []);

  let sourceAudioUrl = null;
  if (job.status === 'completed' && job.objectKey) {
    try {
      sourceAudioUrl = await createPresignedGetUrl({ objectKey: job.objectKey });
    } catch {
      sourceAudioUrl = null;
    }
  }

  return {
    jobId: job.jobId,
    status: job.status,
    progress: job.progress ?? 0,
    sha256: job.sha256,
    objectKey: job.objectKey,
    fileName: job.fileName,
    phase: job.phase ?? 1,
    cached: job.cached ?? false,
    stems,
    sourceAudioUrl,
    error: job.error ?? null,
    createdAt: job.createdAt,
    updatedAt: job.updatedAt,
    completedAt: job.completedAt ?? null,
  };
}

function completedJobFromCache({ user, payload, cache }) {
  const now = new Date().toISOString();
  return {
    jobId: createJobId(),
    userId: user.uid,
    sha256: payload.sha256,
    objectKey: payload.objectKey,
    fileName: payload.fileName,
    status: 'completed',
    progress: 100,
    phase: cache.phase ?? 1,
    cached: true,
    stems: cache.stems,
    error: null,
    createdAt: now,
    updatedAt: now,
    completedAt: cache.completedAt ?? now,
  };
}

export async function createSeparationJob({ user, payload }) {
  const cached = await findCachedSeparation(payload.sha256);
  if (isRealSeparationCache(cached)) {
    const job = completedJobFromCache({ user, payload, cache: cached });
    await saveJob(job);
    return { status: 201, body: await jobToResponse(job) };
  }

  const active = await findActiveJobForUserHash(user.uid, payload.sha256);
  if (active) {
    return { status: 200, body: await jobToResponse(active) };
  }

  const now = new Date().toISOString();
  const job = {
    jobId: createJobId(),
    userId: user.uid,
    sha256: payload.sha256,
    objectKey: payload.objectKey,
    fileName: payload.fileName,
    status: 'queued',
    progress: 0,
    phase: 1,
    cached: false,
    stems: [],
    error: null,
    createdAt: now,
    updatedAt: now,
    completedAt: null,
  };

  await saveJob(job);
  await enqueueSeparationJob(job.jobId);

  return { status: 201, body: await jobToResponse(job) };
}

export async function getSeparationJob({ user, jobId }) {
  const job = await findJobById(jobId);
  if (!job) {
    return { status: 404, body: { error: 'Job no encontrado.' } };
  }
  if (job.userId !== user.uid) {
    return { status: 403, body: { error: 'No tienes acceso a este job.' } };
  }

  if (job.status === 'completed' && (!job.stems || job.stems.length === 0)) {
    const cached = await findCachedSeparation(job.sha256);
    if (cached?.stems) {
      job.stems = cached.stems;
    } else {
      job.stems = buildStemObjectKeys(job.sha256);
    }
  }

  return { status: 200, body: await jobToResponse(job) };
}
