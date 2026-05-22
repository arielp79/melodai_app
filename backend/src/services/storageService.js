import { getStorage } from 'firebase-admin/storage';
import { randomUUID } from 'crypto';

import { config } from '../config.js';

let resolvedBucketName = null;

function bucketCandidates() {
  const fromEnv = config.gcsBucketName;
  const projectId = config.firebaseProjectId;

  return [...new Set(
    [
      fromEnv,
      `${projectId}.appspot.com`,
      `${projectId}.firebasestorage.app`,
    ].filter(Boolean),
  )];
}

/** Resuelve el bucket real en GCS (evita NoSuchBucket por nombre incorrecto). */
export async function resolveStorageBucket() {
  if (resolvedBucketName) {
    return getStorage().bucket(resolvedBucketName);
  }

  const candidates = bucketCandidates();

  for (const name of candidates) {
    const bucket = getStorage().bucket(name);
    const [exists] = await bucket.exists();
    if (exists) {
      resolvedBucketName = name;
      console.info(`[melodai] Bucket GCS activo: ${name}`);
      return bucket;
    }
    console.warn(`[melodai] Bucket no existe: ${name}`);
  }

  throw new Error(
    `Ningún bucket de Storage existe. Candidatos: ${candidates.join(', ')}. ` +
      'Abre Firebase Console → Storage → Empezar y crea el bucket por defecto.',
  );
}

export function buildObjectKey(userId, fileName) {
  const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 180);
  return `uploads/${userId}/${randomUUID()}_${safeName}`;
}

export async function createPresignedPutUrl({ objectKey, contentType }) {
  try {
    const bucket = await resolveStorageBucket();
    const file = bucket.file(objectKey);
    const expires = Date.now() + config.presignExpiresMinutes * 60 * 1000;

    const [uploadUrl] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires,
      contentType,
    });

    return uploadUrl;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`No se pudo firmar la URL de subida: ${message}`);
  }
}

/** URL firmada de lectura para reproducir/descargar una pista (mixer, export). */
export async function createPresignedGetUrl({ objectKey }) {
  try {
    const bucket = await resolveStorageBucket();
    const file = bucket.file(objectKey);
    const expires = Date.now() + config.presignExpiresMinutes * 60 * 1000;

    const [downloadUrl] = await file.getSignedUrl({
      version: 'v4',
      action: 'read',
      expires,
    });

    return downloadUrl;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`No se pudo firmar la URL de lectura: ${message}`);
  }
}
