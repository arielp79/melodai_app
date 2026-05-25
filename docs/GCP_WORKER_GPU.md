# Worker GPU en Google Cloud (trial) — luego RunPod

Ruta recomendada si RunPod pide depósito alto: usa **créditos trial de GCP** (~$300) para una **VM con GPU**, luego migra a RunPod cuando quieras pagar por hora sin atar $150.

```text
Flutter → Render → Upstash → VM GPU en GCP (Docker) → GCS → callbacks Render
```

Misma imagen que RunPod: `ghcr.io/arielp79/melodai-worker:latest`

---

## 1. Requisitos

- Cuenta Google (proyecto **melodaiapp**, el de Firebase/GCS).
- Trial activado: [cloud.google.com/free](https://cloud.google.com/free) / facturación con créditos.
- Imagen en GHCR (pública): GitHub → **Actions** → **Worker Docker (GHCR)** → Run workflow.
- Mismos secretos que Render: `REDIS_URL`, `WORKER_API_KEY`, `ORCHESTRATOR_URL`.

---

## 2. Activar APIs y cuota GPU

1. [Console GCP](https://console.cloud.google.com/) → proyecto **melodaiapp**.
2. **APIs y servicios** → habilita **Compute Engine API**.
3. **IAM y administración** → **Cuotas** → filtra **GPUs (all regions)**.
4. Si la cuota es **0**, solicita aumento (p. ej. **1× NVIDIA T4** en `us-central1`) — suele aprobarse en horas para cuentas trial.

---

## 3. Cuenta de servicio para la VM (GCS sin JSON)

1. **IAM** → **Cuentas de servicio** → crea `melodai-worker-vm@melodaiapp.iam.gserviceaccount.com`.
2. Rol: **Storage Object Admin** (o Storage Object User + permisos de firma si hiciera falta).
3. En la VM usarás **GCS_USE_ADC=true** (la VM usa esta cuenta automáticamente, sin subir `service-account.json`).

---

## 4. Crear la VM con GPU

1. **Compute Engine** → **Instancias de VM** → **Crear instancia**.
2. Sugerencias:

| Campo | Valor |
|-------|--------|
| Nombre | `melodai-worker-gpu` |
| Región | `us-central1` (cerca de Render) |
| Tipo de máquina | Con GPU: p. ej. **n1-standard-4** + **1× NVIDIA T4** |
| SO | **Deep Learning on Linux** (Ubuntu + drivers CUDA) o Ubuntu 22.04 + GPU |
| Disco arranque | **50 GB** SSD |
| Firewall | Solo **SSH (22)** desde tu IP (opcional) |
| Acceso | Cuenta de servicio `melodai-worker-vm` (paso 3) |
| Alcance | Marca **Permitir acceso completo a todas las APIs de Cloud** o al menos Storage |

3. **Crear**.

Coste: consume créditos trial por hora de GPU + disco. **Detén la VM** cuando no la uses.

---

## 5. Conectar por SSH

**SSH** en la fila de la instancia (navegador o `gcloud compute ssh melodai-worker-gpu --zone=us-central1-a`).

---

## 6. Instalar Docker + NVIDIA Container Toolkit

En la VM (como root o con sudo):

```bash
# Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Cierra sesión SSH y vuelve a entrar

# NVIDIA Container Toolkit (GPU dentro de Docker)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Comprobar GPU
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

---

## 7. Arrancar el worker (contenedor)

Crea `/opt/melodai/worker.env` (chmod 600) con tus valores — **no lo subas a git**:

```bash
sudo mkdir -p /opt/melodai
sudo nano /opt/melodai/worker.env
```

Contenido (ejemplo):

```env
REDIS_URL=rediss://...
REDIS_SEPARATION_QUEUE=melodai:separation:jobs
ORCHESTRATOR_URL=https://melodai-orchestrator.onrender.com
WORKER_API_KEY=tu-clave-igual-que-render
DEMUCS_ENABLED=true
DEMUCS_MODEL=htdemucs_6s
DEMUCS_DEVICE=cuda
DEMUCS_FALLBACK_STUB=false
GCS_USE_ADC=true
```

Lanza el contenedor:

```bash
docker pull ghcr.io/arielp79/melodai-worker:latest

docker run -d --name melodai-worker --restart unless-stopped --gpus all \
  --env-file /opt/melodai/worker.env \
  ghcr.io/arielp79/melodai-worker:latest

docker logs -f melodai-worker
```

Logs esperados: `Conectado a Redis`, `device=cuda`, `Modelo Demucs ... listo`.

---

## 8. Parar worker local y probar

1. **Ctrl+C** en `python main.py` en tu PC.
2. Flutter con `API_BASE_URL` de Render.
3. Separar un audio corto → mira logs en `docker logs -f melodai-worker`.

---

## 9. Ahorrar créditos trial

| Acción | Efecto |
|--------|--------|
| **Detener** la VM | No cobra GPU/CPU (sí disco pequeño) |
| **Eliminar** la VM | Quita todo el coste |
| No dejar la VM 24/7 sin uso | Agota créditos rápido |

---

## 10. Migrar a RunPod más adelante

Cuando quieras:

1. Misma imagen `ghcr.io/arielp79/melodai-worker:latest`.
2. Mismas variables de entorno (en RunPod puedes usar `GOOGLE_SERVICE_ACCOUNT_JSON` en lugar de `GCS_USE_ADC`).
3. Apaga/elimina la VM en GCP.

Ver [RUNPOD_WORKER.md](RUNPOD_WORKER.md).

---

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| Cuota GPU 0 | Solicitar cuota T4 en IAM → Cuotas |
| `CUDA not available` en Docker | Pasos NVIDIA Container Toolkit |
| `403` GCS | Rol Storage Object Admin en la cuenta de servicio de la VM |
| `403` callbacks | `WORKER_API_KEY` ≠ Render |
| Pull imagen falla | GHCR público o `docker login ghcr.io` |

---

## Referencias

- [worker/Dockerfile](../worker/Dockerfile)
- [RUNPOD_WORKER.md](RUNPOD_WORKER.md)
- [RENDER_DEPLOY.md](RENDER_DEPLOY.md)
