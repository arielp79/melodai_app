import { Router } from 'express';

import { asyncHandler } from '../lib/asyncHandler.js';
import { requireWorkerAuth } from '../middleware/workerAuth.js';
import { findJobById, saveJob } from '../db/separationJobsRepository.js';
import { pushSeparationJob } from '../queue/separationQueue.js';
import {
  completeSeparationJob,
  failSeparationJob,
  updateSeparationJobProgress,
} from '../services/separationJobUpdates.js';

export const internalRouter = Router();

internalRouter.use(requireWorkerAuth);

internalRouter.post(
  '/separation/jobs/:jobId/requeue',
  asyncHandler(async (req, res) => {
    const job = await findJobById(req.params.jobId);
    if (!job) {
      return res.status(404).json({ error: 'Job no encontrado.' });
    }

    const now = new Date().toISOString();
    await saveJob({
      ...job,
      status: 'queued',
      progress: 0,
      error: null,
      stems: [],
      updatedAt: now,
    });
    await pushSeparationJob(req.params.jobId);

    return res.json({ ok: true, jobId: req.params.jobId, status: 'queued' });
  }),
);

internalRouter.post(
  '/separation/jobs/:jobId/progress',
  asyncHandler(async (req, res) => {
    const { progress, status } = req.body ?? {};
    if (!Number.isFinite(progress)) {
      return res.status(400).json({ error: 'progress es obligatorio (número).' });
    }

    const job = await updateSeparationJobProgress(req.params.jobId, {
      progress,
      status: typeof status === 'string' ? status : undefined,
    });

    if (!job) {
      return res.status(404).json({ error: 'Job no encontrado o ya terminado.' });
    }

    return res.json({ ok: true, jobId: job.jobId, status: job.status, progress: job.progress });
  }),
);

internalRouter.post(
  '/separation/jobs/:jobId/complete',
  asyncHandler(async (req, res) => {
    const { stems, phase, simulated } = req.body ?? {};
    const result = await completeSeparationJob(req.params.jobId, {
      stems,
      phase: Number.isFinite(phase) ? phase : 1,
      simulated: simulated === true,
    });

    if (!result.ok) {
      return res.status(404).json({ error: result.error });
    }

    return res.json({
      ok: true,
      jobId: req.params.jobId,
      stems: result.stems,
    });
  }),
);

internalRouter.post(
  '/separation/jobs/:jobId/fail',
  asyncHandler(async (req, res) => {
    const message =
      typeof req.body?.error === 'string' && req.body.error.trim()
        ? req.body.error.trim()
        : 'Error en el worker de separación.';

    const result = await failSeparationJob(req.params.jobId, message);
    if (!result.ok) {
      return res.status(404).json({ error: result.error });
    }

    return res.json({ ok: true, jobId: req.params.jobId });
  }),
);
