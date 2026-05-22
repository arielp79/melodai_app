import { MongoClient } from 'mongodb';
import { randomUUID } from 'crypto';

import { config } from '../config.js';
import { loadJsonMap, saveJsonMap } from './devJsonPersistence.js';

const JOBS_COLLECTION = 'separation_jobs';
const CACHE_COLLECTION = 'separation_cache';
const JOBS_FILE = 'separation-jobs.json';
const CACHE_FILE = 'separation-cache.json';

/** @type {Map<string, object>} */
let jobsMemory = new Map();
/** @type {Map<string, object>} */
let cacheMemory = new Map();

let client;
let jobsCollection;
let cacheCollection;
let usingMemory = false;

export async function connectSeparationJobsRepository() {
  if (!config.mongodbUri) {
    usingMemory = true;
    jobsMemory = await loadJsonMap(JOBS_FILE);
    cacheMemory = await loadJsonMap(CACHE_FILE);
    console.warn(
      '[melodai] Jobs de separación en disco local (.data/) — sin MONGODB_URI.',
    );
    console.info(
      `[melodai] Cargados ${jobsMemory.size} jobs, ${cacheMemory.size} entradas de caché.`,
    );
    return;
  }

  client = new MongoClient(config.mongodbUri);
  await client.connect();
  const db = client.db(config.mongodbDb);
  jobsCollection = db.collection(JOBS_COLLECTION);
  cacheCollection = db.collection(CACHE_COLLECTION);
  await jobsCollection.createIndex({ jobId: 1 }, { unique: true });
  await jobsCollection.createIndex({ userId: 1, sha256: 1 });
  await cacheCollection.createIndex({ sha256: 1 }, { unique: true });
}

export function createJobId() {
  return randomUUID();
}

export async function findJobById(jobId) {
  if (usingMemory) {
    return jobsMemory.get(jobId) ?? null;
  }
  return jobsCollection.findOne({ jobId });
}

export async function findActiveJobForUserHash(userId, sha256) {
  const query = {
    userId,
    sha256,
    status: { $in: ['queued', 'processing'] },
  };

  if (usingMemory) {
    for (const job of jobsMemory.values()) {
      if (
        job.userId === userId &&
        job.sha256 === sha256 &&
        (job.status === 'queued' || job.status === 'processing')
      ) {
        return job;
      }
    }
    return null;
  }

  return jobsCollection.findOne(query, { sort: { createdAt: -1 } });
}

export async function saveJob(job) {
  if (usingMemory) {
    jobsMemory.set(job.jobId, job);
    saveJsonMap(JOBS_FILE, jobsMemory);
    return;
  }
  await jobsCollection.updateOne({ jobId: job.jobId }, { $set: job }, { upsert: true });
}

export async function findCachedSeparation(sha256) {
  if (usingMemory) {
    return cacheMemory.get(sha256) ?? null;
  }
  return cacheCollection.findOne({ sha256 });
}

export async function saveSeparationCache(record) {
  if (usingMemory) {
    cacheMemory.set(record.sha256, record);
    saveJsonMap(CACHE_FILE, cacheMemory);
    return;
  }
  await cacheCollection.updateOne(
    { sha256: record.sha256 },
    { $set: record },
    { upsert: true },
  );
}

export async function closeSeparationJobsRepository() {
  if (client) {
    await client.close();
  }
}
