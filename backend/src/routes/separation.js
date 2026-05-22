import { Router } from 'express';

import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/auth.js';
import {
  createSeparationJob,
  getSeparationJob,
  validateCreateJobBody,
} from '../services/separationService.js';

export const separationRouter = Router();

separationRouter.post(
  '/jobs',
  requireAuth,
  asyncHandler(async (req, res) => {
    const validation = validateCreateJobBody(req.body);
    if (validation.error) {
      return res.status(400).json({ error: validation.error });
    }

    const result = await createSeparationJob({
      user: req.user,
      payload: validation.value,
    });

    return res.status(result.status).json(result.body);
  }),
);

separationRouter.get(
  '/jobs/:jobId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const result = await getSeparationJob({
      user: req.user,
      jobId: req.params.jobId,
    });
    return res.status(result.status).json(result.body);
  }),
);
