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

export function loadFirebaseCredential() {
  const path = resolveCredentialsPath();
  if (!path || !existsSync(path)) {
    return undefined;
  }
  return admin.credential.cert(path);
}

export function logStartupDiagnostics() {
  const credsPath = resolveCredentialsPath();
  if (!credentialsFileExists()) {
    console.error(
      '[melodai] FALTA service-account.json en:',
      credsPath ?? '(ruta no configurada)',
    );
    console.error(
      '[melodai] Firebase Console → Configuración → Cuentas de servicio → Generar nueva clave privada',
    );
    console.error(
      '[melodai] Sin este archivo NO se pueden crear URLs firmadas para subir audio.',
    );
    return;
  }
  console.info('[melodai] Credenciales GCS encontradas:', credsPath);
}
