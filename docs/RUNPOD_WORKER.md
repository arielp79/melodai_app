# Worker GPU en RunPod (Docker)

El worker consume la cola **Upstash** (`rediss://`), separa con **HTDemucs** en GPU y reporta a **Render**.

```text
Flutter → Render → Redis (Upstash) → RunPod (este worker) → GCS + callbacks Render
```

---

## 1. Requisitos

- Cuenta en [runpod.io](https://www.runpod.io)
- Orquestador en Render funcionando (`/health` con `redisOk`, `mongodbReady`)
- Mismos secretos que ya usas:
  - `REDIS_URL` (Upstash `rediss://`)
  - `WORKER_API_KEY` (igual que en Render)
  - `ORCHESTRATOR_URL` = `https://melodai-orchestrator.onrender.com`
  - JSON de `backend/service-account.json`

---

## 2. Construir la imagen Docker

Desde la raíz del repo (necesitas [Docker Desktop](https://www.docker.com/products/docker-desktop/) o build en GitHub Actions / RunPod).

```powershell
cd C:\Proyectos\melodai_app\worker
docker build -t melodai-worker:latest .
```

La primera vez descarga la imagen PyTorch (~varios GB).

Comprobar CUDA dentro del contenedor (opcional):

```powershell
docker run --rm --gpus all melodai-worker:latest python -c "import torch; print(torch.cuda.is_available())"
```

En Windows sin GPU local, `docker build` basta; el test `--gpus` solo funciona con NVIDIA local.

---

## 3. Subir la imagen a un registry

### Docker Hub (ejemplo)

```powershell
docker login
docker tag melodai-worker:latest TU_USUARIO/melodai-worker:latest
docker push TU_USUARIO/melodai-worker:latest
```

### GitHub Container Registry

```powershell
docker tag melodai-worker:latest ghcr.io/TU_USUARIO/melodai-worker:latest
docker push ghcr.io/TU_USUARIO/melodai-worker:latest
```

---

## 4. Crear el Pod en RunPod

1. **Pods** → **Deploy** → **GPU** (p. ej. RTX 4090 / A4000 según presupuesto).
2. **Container image:** `TU_USUARIO/melodai-worker:latest` (o GHCR).
3. **Container disk:** ≥ 20 GB (modelo Demucs + caché).
4. **Expose HTTP Ports:** no necesario (el worker no sirve HTTP).
5. **Environment variables:**

| Variable | Valor |
|----------|--------|
| `REDIS_URL` | `rediss://...` (Upstash) |
| `REDIS_SEPARATION_QUEUE` | `melodai:separation:jobs` |
| `ORCHESTRATOR_URL` | `https://melodai-orchestrator.onrender.com` |
| `WORKER_API_KEY` | Misma que Render |
| `DEMUCS_ENABLED` | `true` |
| `DEMUCS_MODEL` | `htdemucs_6s` |
| `DEMUCS_DEVICE` | `cuda` |
| `DEMUCS_FALLBACK_STUB` | `false` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | JSON minificado (`.\scripts\render-gcp-json.ps1`) |

**Alternativa a `GOOGLE_SERVICE_ACCOUNT_JSON`:** montar archivo en `/secrets/service-account.json` y definir solo `GOOGLE_APPLICATION_CREDENTIALS=/secrets/service-account.json`.

6. **Deploy** → abre **Logs** del pod.

Log esperado:

```text
Conectado a Redis. Cola: melodai:separation:jobs
Callbacks → https://melodai-orchestrator.onrender.com/internal/...
HTDemucs: model=htdemucs_6s device=cuda
Modelo Demucs htdemucs_6s listo.
```

---

## 5. Apagar el worker local

Si sigues con `python main.py` en tu PC **y** RunPod activos, ambos compiten por la misma cola Redis.

Detén el worker en Windows antes de probar solo RunPod.

---

## 6. Probar E2E

1. App Flutter con `API_BASE_URL` de Render.
2. Sube un audio **corto** (primera vez descarga el modelo en el pod).
3. Logs del pod: descarga GCS → Demucs → subida stems.
4. Job `completed` con `simulated: false`.

---

## 7. Costes y operación

| Tema | Nota |
|------|------|
| **Facturación** | RunPod cobra por tiempo de GPU del pod encendido |
| **Apagar pod** | Cuando no haya jobs, para el pod para no gastar |
| **Serverless** | Fase posterior: escalar pods con cola Redis (Fase 2 warmup) |
| **ffmpeg** | Ya incluido en la imagen |
| **CPU fallback** | En la imagen por defecto `cuda`; sin GPU el pod no tiene sentido |

---

## 8. Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| `CUDA not available` | Elige plantilla/pod con GPU NVIDIA; `DEMUCS_DEVICE=cuda` |
| `GOOGLE_APPLICATION_CREDENTIALS no encontrado` | Define `GOOGLE_SERVICE_ACCOUNT_JSON` o monta el JSON en `/secrets/` |
| `403` en callbacks | `WORKER_API_KEY` distinta entre Render y RunPod |
| Jobs no se consumen | ¿Worker local aún corriendo? ¿Misma `REDIS_URL`? |
| OOM GPU | Pod con más VRAM o canciones más cortas |

---

## Referencias

- [worker/Dockerfile](../worker/Dockerfile)
- [worker/.env.production.example](../worker/.env.production.example)
- [INFRA_PRODUCCION.md](INFRA_PRODUCCION.md)
- [RENDER_DEPLOY.md](RENDER_DEPLOY.md)
