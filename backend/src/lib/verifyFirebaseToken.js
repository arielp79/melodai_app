import { OAuth2Client } from 'google-auth-library';

import { config } from '../config.js';
import { httpsPostJson } from './httpsJson.js';

const oauthClient = new OAuth2Client();

function isJwtShape(token) {
  return typeof token === 'string' && token.split('.').length === 3 && token.length > 100;
}

async function verifyViaIdentityToolkit(idToken) {
  const apiKey = config.firebaseWebApiKey;
  if (!apiKey) {
    throw new Error('FIREBASE_WEB_API_KEY no configurada en .env');
  }

  const url = `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${apiKey}`;
  const { status, body } = await httpsPostJson(url, { idToken });

  if (status !== 200) {
    const message = body?.error?.message ?? JSON.stringify(body);
    throw new Error(message);
  }

  const user = body.users?.[0];
  if (!user?.localId) {
    throw new Error('Usuario no encontrado para este token');
  }

  return {
    uid: user.localId,
    email: user.email ?? null,
  };
}

async function verifyViaOAuth2(idToken) {
  const ticket = await oauthClient.verifyIdToken({
    idToken,
    audience: config.firebaseProjectId,
  });
  const payload = ticket.getPayload();
  if (!payload?.sub) {
    throw new Error('Payload de token vacío');
  }
  return {
    uid: payload.sub,
    email: payload.email ?? null,
  };
}

export async function verifyFirebaseIdToken(rawToken) {
  const idToken = rawToken.trim();

  if (!isJwtShape(idToken)) {
    throw Object.assign(new Error('Formato de token inválido'), {
      code: 'auth/invalid-token-format',
    });
  }

  try {
    return await verifyViaIdentityToolkit(idToken);
  } catch (restError) {
    console.warn('[auth] accounts:lookup:', restError.message);
  }

  try {
    return await verifyViaOAuth2(idToken);
  } catch (oauthError) {
    console.error('[auth] OAuth2 verifyIdToken:', oauthError.message);
    throw new Error('Token de Firebase inválido o expirado.');
  }
}
