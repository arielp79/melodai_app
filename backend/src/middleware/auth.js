import { config } from '../config.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { verifyFirebaseIdToken } from '../lib/verifyFirebaseToken.js';

export const requireAuth = asyncHandler(async (req, res, next) => {
  if (config.authDisabled) {
    req.user = { uid: 'dev-user', email: 'dev@melodai.local' };
    return next();
  }

  const header = req.headers.authorization ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ error: 'Falta Authorization Bearer token.' });
  }

  try {
    req.user = await verifyFirebaseIdToken(match[1]);
    return next();
  } catch (error) {
    console.error('[auth]', error?.code ?? error?.message ?? error);
    return res.status(401).json({
      error: 'Token de Firebase inválido o expirado.',
      hint: 'Cierra sesión en la app, vuelve a iniciar sesión e inténtalo de nuevo.',
    });
  }
});
