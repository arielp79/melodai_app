# Desplegar orquestador en Render

Guía para `melodai-orchestrator` con Docker, MongoDB Atlas, Upstash y GCS.

## Requisitos previos

- [ ] Repo en GitHub: `arielp79/melodai_app`
- [ ] MongoDB Atlas con `0.0.0.0/0` en **Network Access** (Render no tiene IP fija)
- [ ] Upstash Redis → `REDIS_URL` (`rediss://...`)
- [ ] `backend/service-account.json` (cuenta de servicio GCP con **Storage Object Admin**)
- [ ] Firebase Web API Key (la misma que en Flutter local)

---

## 1. Cuenta Render

1. [render.com](https://render.com) → registro (GitHub recomendado).
2. **New** → **Blueprint**.
3. Conecta el repo `melodai_app` → Render detecta `render.yaml` en la raíz.
4. Revisa el servicio `melodai-orchestrator` → **Apply**.

Si no usas Blueprint: **New Web Service** → repo → **Node** → Root Directory `backend` → Build `npm ci --omit=dev` → Start `node src/index.js` (sin `--use-system-ca`; Node 20 en Render no lo soporta).

> El Blueprint usa **runtime Node** (no Docker) para caber en el plan free (~512 MB RAM). Docker suele provocar `Exited with status 9` (proceso matado por memoria).

---

## 2. Variables de entorno (Environment)

En el servicio → **Environment** → añade estas variables (valores desde tu `backend/.env` local, **sin subir el .env a git**):

| Variable | Valor |
|----------|--------|
| `MONGODB_URI` | `mongodb+srv://...` (Atlas) |
| `REDIS_URL` | `rediss://...` (Upstash) |
| `FIREBASE_WEB_API_KEY` | API key de Firebase Console |
| `WORKER_API_KEY` | Genera con `.\scripts\prod-generate-secrets.ps1` (mín. 32 caracteres) |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Contenido **completo** de `service-account.json` en **una línea** (minificado) |

Las demás ya vienen de `render.yaml`: `NODE_ENV`, `FIREBASE_PROJECT_ID`, `GCS_BUCKET_NAME`, `SEPARATION_WORKER_MODE=redis`, `SEPARATION_REDIS_FALLBACK_STUB=false`, etc.

### Pegar el JSON de GCP

En PowerShell (desde `backend/`):

```powershell
(Get-Content .\service-account.json -Raw) | ConvertFrom-Json | ConvertTo-Json -Compress
```

Copia la salida y pégala en `GOOGLE_SERVICE_ACCOUNT_JSON` en Render.

**Alternativa:** Render → **Secret Files** → monta `service-account.json` y define:

```env
GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/service-account.json
```

(en ese caso no hace falta `GOOGLE_SERVICE_ACCOUNT_JSON`).

---

## 3. Primer deploy

1. **Manual Deploy** → **Deploy latest commit** (o push a `main` si activaste auto-deploy).
2. Espera build Docker (~3–5 min en plan Starter).
3. Copia la URL pública, p. ej. `https://melodai-orchestrator.onrender.com`.

---

## 4. URL del orquestador

Añade o actualiza en Render:

| Variable | Valor |
|----------|--------|
| `ORCHESTRATOR_PUBLIC_URL` | `https://melodai-orchestrator.onrender.com` (tu URL real) |

Guarda → Render redeploya solo.

---

## 5. Comprobar `/health`

```powershell
Invoke-RestMethod https://TU-SERVICIO.onrender.com/health | ConvertTo-Json -Depth 5
```

Esperado:

```json
"persistence": { "mongodbConfigured": true },
"separation": { "redisOk": true, "effectiveMode": "redis" },
"storage": { "credentials": true, "credentialsMode": "file" }
```

Si `credentials: false` → revisa `GOOGLE_SERVICE_ACCOUNT_JSON` (JSON válido, una línea).

Si `redisOk: false` → revisa `REDIS_URL` (`rediss://`).

---

## 6. App Flutter apuntando a Render

```powershell
flutter run -d windows --dart-define=API_BASE_URL=https://TU-SERVICIO.onrender.com
```

Build release:

```powershell
flutter build windows --release --dart-define=API_BASE_URL=https://TU-SERVICIO.onrender.com
```

---

## 7. Worker (RunPod / VM / PC)

En `worker/.env` o secrets del pod:

```env
ORCHESTRATOR_URL=https://TU-SERVICIO.onrender.com
WORKER_API_KEY=<mismo que en Render>
REDIS_URL=rediss://...   # misma Upstash
```

---

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| **`Exited with status 9`** | Casi siempre **falta de RAM** en plan free (Docker + `npm ci`). Solución: Blueprint con **runtime Node** (`render.yaml` actual) o plan de pago. |
| **Deploy failed** (build OK) | **Logs → Deploy** (no Build). Suele ser: Mongo sin `0.0.0.0/0` en Atlas, `REDIS_URL` mal, JSON GCP inválido, o health check sin puerto. Tras actualizar código, **Manual Deploy**. |
| Build falla | **Logs → Build**: `npm ci` o Dockerfile. |
| 502 al arrancar | Logs runtime: error Mongo/Redis; comprueba URIs |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Una sola línea con `render-gcp-json.ps1`; sin comillas extra alrededor del JSON |
| Subida 503 GCS | JSON de cuenta de servicio incorrecto o sin permiso en el bucket |
| Jobs en stub | `redisOk: false` o worker sin misma `REDIS_URL` / `WORKER_API_KEY` |
| Plan free duerme | Primera petición tarda ~30 s (cold start) |

### Cómo leer el fallo en Render

1. Dashboard → servicio **melodai-orchestrator** → pestaña **Logs**.
2. Abre el deploy fallido (**Events** → clic en **Deploy** rojo).
3. Mira el final del log:
   - **`npm ERR!`** → fallo de **build**.
   - **`Error conectando dependencias`** → Mongo o Redis (Atlas IP / `REDIS_URL`).
   - **`GOOGLE_SERVICE_ACCOUNT_JSON debe ser JSON`** → vuelve a pegar el JSON con `render-gcp-json.ps1`.
   - **`no open ports`** / health check → actualiza repo (arranque en `0.0.0.0` + `/health`).

---

## Referencias

- [render.yaml](../render.yaml)
- [DESPLIEGUE_PROD_PASOS.md](DESPLIEGUE_PROD_PASOS.md)
- [INFRA_PRODUCCION.md](INFRA_PRODUCCION.md)
