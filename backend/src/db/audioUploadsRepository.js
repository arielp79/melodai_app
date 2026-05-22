import { MongoClient } from 'mongodb';

import { config } from '../config.js';

const COLLECTION = 'audio_uploads';

/** @type {Map<string, object>} */
const memoryStore = new Map();

let client;
let collection;
let usingMemory = false;

export async function connectAudioUploadsRepository() {
  if (!config.mongodbUri) {
    usingMemory = true;
    console.warn(
      '[melodai] MONGODB_URI no definida — deduplicación en memoria (se pierde al reiniciar).',
    );
    return;
  }

  client = new MongoClient(config.mongodbUri);
  await client.connect();
  collection = client.db(config.mongodbDb).collection(COLLECTION);
  await collection.createIndex({ sha256: 1 }, { unique: true });
  console.info('[melodai] MongoDB conectado.');
}

export async function findBySha256(sha256) {
  if (usingMemory) {
    return memoryStore.get(sha256) ?? null;
  }
  return collection.findOne({ sha256 });
}

export async function saveUpload(record) {
  if (usingMemory) {
    memoryStore.set(record.sha256, record);
    return;
  }

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
