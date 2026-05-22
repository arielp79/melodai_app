import { existsSync } from 'fs';
import { resolve } from 'path';

import admin from 'firebase-admin';

import { config } from '../config.js';

export function resolveCredentialsPath() {
  if (!config.googleApplicationCredentials) {
    return null;
  }
  return resolve(process.cwd(), config.googleApplicationCredentials);
}

export function credentialsFileExists() {
  const path = resolveCredentialsPath();
  return path != null && existsSync(path);
}

/** Cloud Run y GCE exponen K_SERVICE; ahí usamos Application Default Credentials. */
export function isGoogleManagedRuntime() {
  return Boolean(process.env.K_SERVICE || process.env.GOOGLE_CLOUD_PROJECT);
}

export function loadFirebaseCredential() {
  const path = resolveCredentialsPath();
  if (path && existsSync(path)) {
    return admin.credential.cert(path);
  }
  if (isGoogleManagedRuntime()) {
    return admin.credential.applicationDefault();
  }
  return undefined;
}

export function logStartupDiagnostics() {
  const credsPath = resolveCredentialsPath();
  if (credentialsFileExists()) {
    console.info('[melodai] Credenciales GCS (archivo):', credsPath);
    return;
  }
  if (isGoogleManagedRuntime()) {
    console.info('[melodai] Credenciales GCS: Application Default (cuenta de servicio del runtime)');
    return;
  }
  console.error(
    '[melodai] FALTA service-account.json en:',
    credsPath ?? '(ruta no configurada)',
  );
  console.error(
    '[melodai] En Cloud Run asigna una cuenta de servicio con Storage Object Admin.',
  );
}
