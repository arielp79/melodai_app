import { MongoClient } from 'mongodb';

import { config } from '../config.js';

const COLLECTION = 'audio_uploads';

/** @type {Map<string, object>} */
const memoryStore = new Map();

let client;
let collection;
let usingMemory = false;
let mongoReady = false;

export function isAudioUploadsReady() {
  return usingMemory || mongoReady;
}

export async function connectAudioUploadsRepository() {
  if (!config.mongodbUri) {
    usingMemory = true;
    mongoReady = true;
    console.warn(
      '[melodai] MONGODB_URI no definida — deduplicación en memoria (se pierde al reiniciar).',
    );
    return;
  }

  const uri = config.mongodbUri;
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      client = new MongoClient(uri);
      await client.connect();
      collection = client.db(config.mongodbDb).collection(COLLECTION);
      await collection.createIndex({ sha256: 1 }, { unique: true });
      mongoReady = true;
      console.info('[melodai] MongoDB conectado (audio_uploads).');
      return;
    } catch (error) {
      lastError = error;
      console.error(
        `[melodai] MongoDB audio_uploads intento ${attempt}/3:`,
        error instanceof Error ? error.message : error,
      );
      if (client) {
        await client.close().catch(() => {});
        client = undefined;
      }
      collection = undefined;
      await new Promise((r) => setTimeout(r, attempt * 1000));
    }
  }

  throw lastError ?? new Error('No se pudo conectar a MongoDB (audio_uploads).');
}

function assertReady() {
  if (usingMemory) return;
  if (!mongoReady || !collection) {
    throw new Error(
      'MongoDB no conectado (audio_uploads). Revisa MONGODB_URI en Render y Network Access 0.0.0.0/0 en Atlas.',
    );
  }
}

export async function findBySha256(sha256) {
  if (usingMemory) {
    return memoryStore.get(sha256) ?? null;
  }
  assertReady();
  return collection.findOne({ sha256 });
}

export async function saveUpload(record) {
  if (usingMemory) {
    memoryStore.set(record.sha256, record);
    return;
  }

  assertReady();
  await collection.updateOne(
    { sha256: record.sha256 },
    { $set: record },
    { upsert: true },
  );
}

export async function closeAudioUploadsRepository() {
  if (client) {
    await client.close();
  }
}
