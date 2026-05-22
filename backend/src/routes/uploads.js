import { Router } from 'express';

import { config } from '../config.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { credentialsFileExists } from '../lib/credentials.js';
import { requireAuth } from '../middleware/auth.js';
import {
  completeUpload,
  requestPresignedUpload,
  validatePresignBody,
} from '../services/presignService.js';

export const uploadsRouter = Router();

uploadsRouter.post('/presign', requireAuth, asyncHandler(async (req, res) => {
  const validation = validatePresignBody(req.body);
  if (validation.error) {
    return res.status(400).json({ error: validation.error });
  }

  if (!credentialsFileExists()) {
    return res.status(503).json({
      error: 'Almacenamiento no configurado en el servidor.',
      hint:
        'Coloca service-account.json en backend/ (clave de cuenta de servicio de Firebase).',
    });
  }

  try {
    const result = await requestPresignedUpload({
      user: req.user,
      payload: validation.value,
      maxUploadBytes: config.maxUploadBytes,
    });

    return res.status(result.status).json(result.body);
  } catch (error) {
    console.error('[presign]', error);
    const message = error instanceof Error ? error.message : String(error);
    const bucketMissing = message.includes('Ningún bucket de Storage existe');
    if (bucketMissing) {
      return res.status(503).json({
        error: 'Almacenamiento no disponible.',
        detail: message,
        hint:
          'Firebase Console → Storage → Empezar. Reinicia el backend y comprueba "[melodai] Bucket GCS activo: ..." en consola.',
      });
    }
    return res.status(500).json({
      error: 'No se pudo generar la URL firmada.',
      detail: message,
    });
  }
}));

uploadsRouter.post('/complete', requireAuth, asyncHandler(async (req, res) => {
  const { sha256, objectKey } = req.body ?? {};

  try {
    const result = await completeUpload({
      user: req.user,
      sha256,
      objectKey,
    });
    return res.status(result.status).json(result.body);
  } catch (error) {
    console.error('[complete]', error);
    return res.status(500).json({ error: 'No se pudo registrar la subida.' });
  }
}));
