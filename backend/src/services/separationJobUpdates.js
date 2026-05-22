import {
  findJobById,
  saveJob,
  saveSeparationCache,
} from '../db/separationJobsRepository.js';
import { buildStemObjectKeys } from './separationStems.js';

export async function updateSeparationJobProgress(jobId, { progress, status }) {
  const job = await findJobById(jobId);
  if (!job || job.status === 'completed') {
    return null;
  }

  const nextStatus =
    status ??
    (job.status === 'queued' || job.status === 'failed' ? 'processing' : job.status);

  const updated = {
    ...job,
    status: nextStatus,
    progress: Math.min(100, Math.max(0, Math.floor(progress))),
    error: nextStatus === 'processing' ? null : job.error,
    updatedAt: new Date().toISOString(),
  };
  await saveJob(updated);
  return updated;
}

export async function completeSeparationJob(jobId, { stems, phase = 1, simulated = false }) {
  const job = await findJobById(jobId);
  if (!job) {
    return { ok: false, error: 'Job no encontrado.' };
  }

  const resolvedStems =
    stems?.length > 0
      ? stems.map((s) => ({ ...s, simulated: s.simulated ?? simulated }))
      : buildStemObjectKeys(job.sha256);

  const completedAt = new Date().toISOString();

  await saveSeparationCache({
    sha256: job.sha256,
    phase,
    stems: resolvedStems,
    simulated,
    completedAt,
  });

  await saveJob({
    ...job,
    status: 'completed',
    progress: 100,
    phase,
    stems: resolvedStems,
    cached: false,
    error: null,
    completedAt,
    updatedAt: completedAt,
  });

  return { ok: true, stems: resolvedStems };
}

export async function failSeparationJob(jobId, errorMessage) {
  const job = await findJobById(jobId);
  if (!job) {
    return { ok: false, error: 'Job no encontrado.' };
  }

  await saveJob({
    ...job,
    status: 'failed',
    error: errorMessage,
    updatedAt: new Date().toISOString(),
  });

  return { ok: true };
}
