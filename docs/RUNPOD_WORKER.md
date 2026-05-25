# Worker GPU en RunPod (Docker)

> **Sin depósito RunPod:** usa primero [GCP_WORKER_GPU.md](GCP_WORKER_GPU.md) (trial). Esta guía aplica cuando migres a RunPod.

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

## 2. Imagen Docker (elige una vía)

### A — Sin Docker en tu PC (recomendado)

GitHub Actions construye la imagen al push en `main`:

1. Repo → **Actions** → **Worker Docker (GHCR)** → **Run workflow**.
2. Cuando termine en verde, la imagen queda en:
   ```text
   ghcr.io/arielp79/melodai-worker:latest
   ```
3. En GitHub → **Packages** → `melodai-worker` → **Package settings** → **Change visibility** → **Public** (RunPod debe poder hacer pull sin login).

### B — Build local

Desde la raíz del repo (necesitas [Docker Desktop](https://www.docker.com/products/docker-desktop/)).

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

## 3. Subir la imagen (solo si usaste build local)

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

## 4. RunPod — dashboard paso a paso

### 4.1 Cuenta y créditos

1. [runpod.io](https://www.runpod.io) → registro.
2. **Billing** → añade método de pago o créditos (GPU de pago por hora).
3. Verifica email si lo pide.

### 4.2 Crear el Pod

1. Menú **Pods** → **+ Deploy** (o **Deploy a Pod**).
2. Elige **GPU** (Community Cloud suele ser más barato):
   - Para pruebas: **RTX 3090 / 4090 / A4000** (≥ 16 GB VRAM recomendado).
3. **Template / Container image** → **Custom image** (no plantilla PyTorch genérica).
4. **Container image:**
   ```text
   ghcr.io/arielp79/melodai-worker:latest
   ```
5. **Container disk:** `30` GB (modelo Demucs + caché).
6. **Volume disk:** no obligatorio si usas `GOOGLE_SERVICE_ACCOUNT_JSON` en env.
7. **Expose HTTP ports:** déjalo vacío (el worker no expone web).
8. **Start Jupyter / SSH:** desactivado (no hace falta).

### 4.3 Variables de entorno

En **Environment variables** (Edit / Add) — copia desde tu setup actual:

| Key | Value |
|-----|--------|
| `REDIS_URL` | Upstash `rediss://...` (igual que Render) |
| `REDIS_SEPARATION_QUEUE` | `melodai:separation:jobs` |
| `ORCHESTRATOR_URL` | `https://melodai-orchestrator.onrender.com` |
| `WORKER_API_KEY` | **Igual que en Render** |
| `DEMUCS_ENABLED` | `true` |
| `DEMUCS_MODEL` | `htdemucs_6s` |
| `DEMUCS_DEVICE` | `cuda` |
| `DEMUCS_FALLBACK_STUB` | `false` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Salida de `.\scripts\render-gcp-json.ps1` (una línea) |

En Windows, prepara valores:

```powershell
cd C:\Proyectos\melodai_app
# WORKER_API_KEY ya está en Render — no generes otra distinta
.\scripts\render-gcp-json.ps1
```

`REDIS_URL` y `WORKER_API_KEY`: cópialos de Render → Environment (no los pegues en chat).

### 4.4 Registry privado (si GHCR no es público)

**Pod settings** → **Container registry credentials**:

- Registry: `ghcr.io`
- Username: tu usuario GitHub
- Password: [Personal Access Token](https://github.com/settings/tokens) con `read:packages`

Si el paquete es **Public**, no hace falta.

### 4.5 Deploy y logs

1. **Deploy** / **Create Pod**.
2. Espera estado **Running** (puede tardar 1–3 min en pull de imagen).
3. Clic en el pod → **Logs** (o **Connect** → log stream).

Logs OK:

```text
Conectado a Redis. Cola: melodai:separation:jobs
Callbacks → https://melodai-orchestrator.onrender.com/internal/...
HTDemucs: model=htdemucs_6s device=cuda
Modelo Demucs htdemucs_6s listo.
```

### 4.6 Parar worker local

En tu PC: **Ctrl+C** en `python main.py`. Si no, tu PC y RunPod compiten por la misma cola.

### 4.7 Probar

1. Flutter con `API_BASE_URL=https://melodai-orchestrator.onrender.com`.
2. Sube audio corto → **Separar pistas**.
3. Logs del pod: actividad Demucs.
4. Job `simulated: false` en la app.

### 4.8 Apagar pod (ahorrar)

Cuando no uses GPU: **Stop** / **Terminate** el pod en el dashboard.

---

## 6. Costes y operación

| Tema | Nota |
|------|------|
| **Facturación** | RunPod cobra por tiempo de GPU del pod encendido |
| **Apagar pod** | Cuando no haya jobs, para el pod para no gastar |
| **Serverless** | Fase posterior: escalar pods con cola Redis (Fase 2 warmup) |
| **ffmpeg** | Ya incluido en la imagen |
| **CPU fallback** | En la imagen por defecto `cuda`; sin GPU el pod no tiene sentido |

---

## 7. Problemas frecuentes

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
