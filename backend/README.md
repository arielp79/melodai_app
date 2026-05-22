# MelodAI — Orquestador Node.js

API mínima alineada con el cliente Flutter: presigned URLs a Firebase/Google Cloud Storage y deduplicación por SHA-256.

## Endpoints

### `POST /uploads/presign`

Requiere `Authorization: Bearer <Firebase ID token>`.

**Body:**

```json
{
  "fileName": "cancion.mp3",
  "contentType": "audio/mpeg",
  "sha256": "abc123...64 chars",
  "sizeBytes": 5242880
}
```

**Respuesta (subida nueva):**

```json
{
  "uploadUrl": "https://storage.googleapis.com/...",
  "objectKey": "uploads/{uid}/{uuid}_cancion.mp3",
  "contentType": "audio/mpeg",
  "headers": { "Content-Type": "audio/mpeg" },
  "cached": false
}
```

**Respuesta (caché por hash):**

```json
{
  "uploadUrl": "",
  "objectKey": "uploads/.../existing.mp3",
  "contentType": "audio/mpeg",
  "headers": {},
  "cached": true
}
```

### Separación de audio (jobs)

#### `POST /separation/jobs`

Crea un job de separación Fase 1 (HTDemucs / 5 pistas estándar). En local ejecuta un **worker stub** (~8 s); en producción lo sustituirá el worker Python + Redis.

**Body:**

```json
{
  "sha256": "abc123...64 chars",
  "objectKey": "uploads/{uid}/{uuid}_cancion.mp3",
  "fileName": "cancion.mp3"
}
```

**Respuesta:** `201` job nuevo (`queued` → `processing` → `completed`) o `200` si ya hay un job activo para el mismo usuario/hash. Si el SHA-256 ya fue separado, devuelve `completed` con `cached: true`.

#### `GET /separation/jobs/:jobId`

Estado del job (`progress`, `stems`, `error`). Requiere ser el mismo usuario que creó el job.

Variables en `.env`:

| Variable | Descripción |
|----------|-------------|
| `SEPARATION_STUB_DELAY_MS` | Duración del stub (ms), default `8000` |
| `REDIS_URL` | Si está definida → modo cola Redis (salvo `SEPARATION_WORKER_MODE=stub`) |
| `SEPARATION_WORKER_MODE` | `stub` \| `redis` (auto: `redis` si hay `REDIS_URL`) |
| `WORKER_API_KEY` | Clave `X-Worker-Key` para el worker Python |
| `REDIS_SEPARATION_QUEUE` | Nombre de cola, default `melodai:separation:jobs` |

### Worker Python + Redis

Ver [worker/README.md](../worker/README.md).

1. Redis local o Upstash → `REDIS_URL` en `backend/.env`
2. Misma `WORKER_API_KEY` en `backend/.env` y `worker/.env`
3. `npm run dev` + `python worker/main.py`
4. La app Flutter no cambia: sigue haciendo polling a `GET /separation/jobs/:id`

**API interna** (solo worker): `POST /internal/separation/jobs/:jobId/progress|complete|fail`

### `POST /uploads/complete`

Registra el hash tras un `PUT` exitoso al bucket (activa la dedup en siguientes subidas).

**Body:**

```json
{
  "sha256": "abc123...",
  "objectKey": "uploads/{uid}/{uuid}_cancion.mp3"
}
```

## Configuración

1. Copia `.env.example` → `.env`.
2. En Firebase Console → Project settings → Service accounts → **Generate new private key** → guarda como `service-account.json` en `backend/` (ya está en `.gitignore`).
3. El rol de la cuenta de servicio debe poder firmar URLs en el bucket (`Storage Object Admin` o equivalente).
4. (Opcional) Crea cluster en MongoDB Atlas y define `MONGODB_URI`. Sin URI, la dedup usa memoria (solo para pruebas locales).

```bash
cd backend
npm install
npm run dev
```

Los scripts usan `node --use-system-ca` para evitar errores SSL al validar tokens con Google en Windows.

**Windows (error SSL `UNABLE_TO_VERIFY_LEAF_SIGNATURE`):**

```powershell
$env:NODE_OPTIONS="--use-system-ca"
npm install
```

Comprueba: `GET http://127.0.0.1:3000/health`

## Producción

Docker + Cloud Run / Render: ver [docs/INFRA_PRODUCCION.md](../docs/INFRA_PRODUCCION.md) y [backend/.env.production.example](.env.production.example).

```bash
cd backend
docker build -t melodai-orchestrator .
```

## Flutter

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

## Desarrollo sin Firebase token

En `.env`: `AUTH_DISABLED=true` (solo local).

## Problemas frecuentes

### `NoSuchBucket` / 404 al subir al almacenamiento

El nombre del bucket en `.env` no coincide con el bucket real de tu proyecto.

1. Firebase Console → **Storage** → si no está activo, pulsa **Empezar** (crea el bucket).
2. Copia el nombre del bucket que aparece arriba (suele ser `melodaiapp.appspot.com` o `melodaiapp.firebasestorage.app`).
3. Déjalo vacío en `.env` (`GCS_BUCKET_NAME=`) para autodetectar, o pon el nombre exacto.
4. Reinicia `npm run dev` — debe mostrar `[melodai] Bucket GCS activo: ...`

### "No se pudo generar la URL firmada" / error al subir

**No es MongoDB.** Sin `MONGODB_URI` el servidor usa memoria y funciona para pruebas.

Causa habitual: falta `backend/service-account.json`:

1. [Firebase Console](https://console.firebase.google.com) → tu proyecto → ⚙️ Configuración del proyecto
2. Pestaña **Cuentas de servicio** → **Generar nueva clave privada**
3. Guarda el JSON como `backend/service-account.json`
4. En Google Cloud IAM, esa cuenta debe poder escribir en el bucket (p. ej. rol **Storage Object Admin**)
5. Reinicia `npm run dev` — en consola debe aparecer `Credenciales GCS encontradas`

### Token inválido (401)

Inicia sesión de nuevo en la app. En Windows la sesión es en memoria; si reiniciaste el backend o la app, vuelve a hacer login.
