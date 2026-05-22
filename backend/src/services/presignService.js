import { findBySha256, saveUpload } from '../db/audioUploadsRepository.js';
import { buildObjectKey, createPresignedPutUrl } from './storageService.js';

const SHA256_REGEX = /^[a-f0-9]{64}$/i;

export function validatePresignBody(body) {
  const { fileName, contentType, sha256, sizeBytes } = body ?? {};

  if (!fileName || typeof fileName !== 'string') {
    return { error: 'fileName es obligatorio.' };
  }
  if (!contentType || typeof contentType !== 'string') {
    return { error: 'contentType es obligatorio.' };
  }
  if (!sha256 || !SHA256_REGEX.test(sha256)) {
    return { error: 'sha256 debe ser un hash hexadecimal de 64 caracteres.' };
  }
  if (!Number.isFinite(sizeBytes) || sizeBytes <= 0) {
    return { error: 'sizeBytes debe ser un número positivo.' };
  }

  return {
    value: {
      fileName: fileName.trim(),
      contentType: contentType.trim(),
      sha256: sha256.toLowerCase(),
      sizeBytes: Math.floor(sizeBytes),
    },
  };
}

export async function requestPresignedUpload({ user, payload, maxUploadBytes }) {
  if (payload.sizeBytes > maxUploadBytes) {
    return { status: 413, body: { error: 'Archivo demasiado grande.' } };
  }

  const existing = await findBySha256(payload.sha256);
  if (existing) {
    return {
      status: 200,
      body: {
        uploadUrl: '',
        objectKey: existing.objectKey,
        contentType: existing.contentType ?? payload.contentType,
        headers: {},
        cached: true,
      },
    };
  }

  const objectKey = buildObjectKey(user.uid, payload.fileName);
  const uploadUrl = await createPresignedPutUrl({
    objectKey,
    contentType: payload.contentType,
  });

  return {
    status: 200,
    body: {
      uploadUrl,
      objectKey,
      contentType: payload.contentType,
      headers: { 'Content-Type': payload.contentType },
      cached: false,
    },
  };
}

export async function completeUpload({ user, sha256, objectKey }) {
  if (!sha256 || !SHA256_REGEX.test(sha256)) {
    return { status: 400, body: { error: 'sha256 inválido.' } };
  }
  if (!objectKey || typeof objectKey !== 'string') {
    return { status: 400, body: { error: 'objectKey es obligatorio.' } };
  }

  const normalizedHash = sha256.toLowerCase();
  const existing = await findBySha256(normalizedHash);
  if (existing) {
    return {
      status: 200,
      body: {
        sha256: normalizedHash,
        objectKey: existing.objectKey,
        cached: true,
      },
    };
  }

  await saveUpload({
    sha256: normalizedHash,
    objectKey,
    userId: user.uid,
    status: 'ready',
    completedAt: new Date(),
  });

  return {
    status: 200,
    body: {
      sha256: normalizedHash,
      objectKey,
      cached: false,
    },
  };
}
