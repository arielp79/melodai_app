# Despliegue producción — paso a paso

Guía operativa ordenada. Detalle de arquitectura: [INFRA_PRODUCCION.md](INFRA_PRODUCCION.md).

## Estado (marca según avances)

| Paso | Componente | Estado |
|------|------------|--------|
| 1 | MongoDB Atlas | ✅ (local con `MONGODB_URI`) |
| 2 | Upstash Redis (`rediss://`) | ⬜ |
| 3 | Orquestador (Cloud Run o Render) | ⬜ |
| 4 | Secretos `WORKER_API_KEY` fuerte | ⬜ |
| 5 | Worker GPU (GCP trial o RunPod) | ⬜ |
| 6 | Flutter `API_BASE_URL` prod | ⬜ |
| 7 | E2E prod (subida → separación → export) | ⬜ |

---

## Paso 2 — Upstash Redis (siguiente)

1. Cuenta en [upstash.com](https://upstash.com) → **Create database** → región `us-east-1` (cerca de Cloud Run `us-central1`).
2. En la base → pestaña **Connect** → copia la URL **Redis** con TLS (`rediss://default:...@....upstash.io:6379`).
3. En **backend/.env** (prueba local contra cola prod) y luego en secretos de Cloud Run/Render:

```env
REDIS_URL=rediss://...
SEPARATION_WORKER_MODE=redis
SEPARATION_REDIS_FALLBACK_STUB=false
```

4. Comprueba conexión:

```powershell
cd C:\Proyectos\melodai_app
.\scripts\prod-checklist.ps1
python scripts\test-redis.py
```

5. Reinicia `npm run dev` en `backend/` — log esperado: `Redis OK`.

> El worker local puede usar la misma `REDIS_URL` de Upstash para consumir la cola de prod (cuidado: jobs reales en prod).

---

## Paso 3 — Orquestador en la nube

### Opción A — Google Cloud Run (recomendado con Firebase/GCS)

**Requisito:** [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`).

```powershell
gcloud config set project melodaiapp
gcloud auth login
```

1. **Secret Manager** (Console GCP o CLI) — crea secretos:
   - `firebase-web-api-key` → valor de Firebase Web API Key
   - `worker-api-key` → genera con `.\scripts\prod-generate-secrets.ps1`
   - `mongodb-uri` → misma URI que en local (sin commitear)
   - `redis-url` → URL Upstash `rediss://...`

2. **Cuenta de servicio** `melodai-orchestrator@melodaiapp.iam.gserviceaccount.com` con rol **Storage Object Admin**.

3. Despliegue (desde `backend/`):

```powershell
cd backend
gcloud run deploy melodai-orchestrator `
  --source . `
  --region us-central1 `
  --allow-unauthenticated `
  --set-env-vars "NODE_ENV=production,FIREBASE_PROJECT_ID=melodaiapp,GCS_BUCKET_NAME=melodaiapp.firebasestorage.app,SEPARATION_WORKER_MODE=redis,SEPARATION_REDIS_FALLBACK_STUB=false,MONGODB_DB=melodai,AUTH_DISABLED=false" `
  --set-secrets "FIREBASE_WEB_API_KEY=firebase-web-api-key:latest,WORKER_API_KEY=worker-api-key:latest,MONGODB_URI=mongodb-uri:latest,REDIS_URL=redis-url:latest" `
  --service-account melodai-orchestrator@melodaiapp.iam.gserviceaccount.com
```

4. Copia la URL del servicio → `ORCHESTRATOR_PUBLIC_URL` / `ORCHESTRATOR_URL` del worker.

5. Health:

```powershell
Invoke-RestMethod https://TU-SERVICIO.run.app/health | ConvertTo-Json -Depth 5
```

Esperado: `mongodbConfigured: true`, `redisOk: true`, `effectiveMode: "redis"`, `credentialsMode: "applicationDefault"`.

### Opción B — Render (sin `gcloud`)

Guía detallada: **[RENDER_DEPLOY.md](RENDER_DEPLOY.md)**.

Resumen: Blueprint con [render.yaml](../render.yaml) → variables `MONGODB_URI`, `REDIS_URL`, `FIREBASE_WEB_API_KEY`, `WORKER_API_KEY`, `GOOGLE_SERVICE_ACCOUNT_JSON` → deploy → `ORCHESTRATOR_PUBLIC_URL` → `/health`.

---

## Paso 4 — Worker GPU

| Opción | Cuándo |
|--------|--------|
| **[GCP_WORKER_GPU.md](GCP_WORKER_GPU.md)** | Trial ~$300, sin depósito RunPod — **recomendado ahora** |
| **[RUNPOD_WORKER.md](RUNPOD_WORKER.md)** | Cuando GCP trial termine o quieras GPU por hora |

No va en Cloud Run. RunPod / VM con [worker/.env.production.example](../worker/.env.production.example):

```env
ORCHESTRATOR_URL=https://TU-ORQUESTADOR.run.app
WORKER_API_KEY=<mismo que Cloud Run/Render>
REDIS_URL=rediss://...
DEMUCS_DEVICE=cuda
DEMUCS_FALLBACK_STUB=false
GOOGLE_APPLICATION_CREDENTIALS=/ruta/service-account.json
```

Instala en la imagen: `pip install -r requirements.txt` + `soundfile` + ffmpeg.

---

## Paso 5 — App Flutter

```powershell
flutter build windows --release `
  --dart-define=API_BASE_URL=https://TU-ORQUESTADOR.run.app
```

---

## Paso 6 — Checklist final

```powershell
.\scripts\prod-checklist.ps1
```

- [ ] `/health` público OK
- [ ] Worker GPU conectado a Upstash
- [ ] Job prod con `simulated: false`
- [ ] API keys Firebase restringidas ([SECRETS_Y_GITHUB.md](SECRETS_Y_GITHUB.md))

---

## Comandos útiles

| Acción | Comando |
|--------|---------|
| Generar `WORKER_API_KEY` | `.\scripts\prod-generate-secrets.ps1` |
| Probar Redis | `python scripts\test-redis.py` |
| Revisar variables locales | `.\scripts\prod-checklist.ps1` |
