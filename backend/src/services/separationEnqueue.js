import { pushSeparationJob } from '../queue/separationQueue.js';
import { effectiveWorkerMode, initSeparationRuntime } from './separationRuntime.js';
import { enqueueSeparationJobStub } from './separationWorkerStub.js';

/**
 * Encola el job según modo efectivo:
 * - stub: proceso en el mismo Node
 * - redis: cola para el worker Python (si Redis responde)
 */
export async function enqueueSeparationJob(jobId) {
  if (effectiveWorkerMode === 'redis') {
    try {
      await pushSeparationJob(jobId);
      return;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(
        `[separation] Redis falló al encolar ${jobId}, usando stub:`,
        message,
      );
      await initSeparationRuntime();
    }
  }

  enqueueSeparationJobStub(jobId);
}
