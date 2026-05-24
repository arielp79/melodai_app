/**
 * Render / hosts sin archivo local: pega el JSON de la cuenta de servicio en
 * GOOGLE_SERVICE_ACCOUNT_JSON y se escribe a /tmp antes de cargar config.
 */
import { writeFileSync } from 'fs';

let json = process.env.GOOGLE_SERVICE_ACCOUNT_JSON?.trim();
if (!json) {
  // nada
} else {
  if (json.startsWith('"') && json.endsWith('"')) {
    json = json.slice(1, -1);
  }
  if (!json.startsWith('{')) {
    console.error(
      '[melodai] GOOGLE_SERVICE_ACCOUNT_JSON debe ser JSON (empieza con {). Revisa comillas en Render.',
    );
  } else {
    const target =
      process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim() || '/tmp/melodai-gcp-sa.json';
    writeFileSync(target, json, { encoding: 'utf8', mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = target;
  }
}
