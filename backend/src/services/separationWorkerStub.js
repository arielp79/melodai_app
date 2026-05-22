import { config } from '../config.js';
import { findJobById } from '../db/separationJobsRepository.js';
import {
  completeSeparationJob,
  failSeparationJob,
  updateSeparationJobProgress,
} from './separationJobUpdates.js';

const inFlight = new Set();

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function runStubPipeline(jobId) {
  const job = await findJobById(jobId);
  if (!job) return;

  const stepMs = Math.max(500, Math.floor(config.separationStubDelayMs / 4));

  await updateSeparationJobProgress(jobId, { status: 'processing', progress: 5 });
  await sleep(stepMs);
  await updateSeparationJobProgress(jobId, { progress: 35 });
  await sleep(stepMs);
  await updateSeparationJobProgress(jobId, { progress: 70 });
  await sleep(stepMs);

  const result = await completeSeparationJob(jobId, { simulated: true });
  console.info(
    `[separation] Job ${jobId} completado (stub Node, ${result.stems?.length ?? 0} pistas)`,
  );
}

export function enqueueSeparationJobStub(jobId) {
  if (inFlight.has(jobId)) return;
  inFlight.add(jobId);

  runStubPipeline(jobId)
    .catch(async (error) => {
      console.error(`[separation] Job ${jobId} falló (stub):`, error);
      await failSeparationJob(
        jobId,
        error instanceof Error ? error.message : String(error),
      );
    })
    .finally(() => {
      inFlight.delete(jobId);
    });
}
