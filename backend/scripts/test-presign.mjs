import 'dotenv/config';
import admin from 'firebase-admin';

import { config } from '../src/config.js';
import { connectAudioUploadsRepository } from '../src/db/audioUploadsRepository.js';
import { loadFirebaseCredential } from '../src/lib/credentials.js';
import { requestPresignedUpload } from '../src/services/presignService.js';

const credential = loadFirebaseCredential();
admin.initializeApp({
  projectId: config.firebaseProjectId,
  storageBucket: config.gcsBucketName ?? undefined,
  ...(credential ? { credential } : {}),
});

await connectAudioUploadsRepository();

const result = await requestPresignedUpload({
  user: { uid: 'test-user' },
  payload: {
    fileName: 'song.mp3',
    contentType: 'audio/mpeg',
    sha256: 'b'.repeat(64),
    sizeBytes: 1024,
  },
  maxUploadBytes: config.maxUploadBytes,
});

console.log('OK', result.status, result.body.uploadUrl?.slice(0, 80));
