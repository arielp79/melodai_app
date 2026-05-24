# Prueba MONGODB_URI de backend/.env (copiar la misma a Render).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $root "backend")
try {
  node --input-type=module -e @"
import 'dotenv/config';
import { MongoClient } from 'mongodb';
const uri = process.env.MONGODB_URI?.trim();
if (!uri) { console.error('MONGODB_URI vacia'); process.exit(1); }
const client = new MongoClient(uri, { serverSelectionTimeoutMS: 15000 });
try {
  await client.connect();
  await client.db('melodai').command({ ping: 1 });
  console.log('OK - MongoDB responde (usa esta URI en Render)');
} catch (e) {
  console.error('ERROR:', e.message);
  process.exit(1);
} finally {
  await client.close();
}
"@
} finally {
  Pop-Location
}
