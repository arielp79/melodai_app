# Pipeline real de separación (dev local)

Guía para que los jobs pasen por **Redis + worker Python + HTDemucs** y las pistas tengan `simulated: false` con archivos `.wav` en GCS.

## Redis en Windows (sin Docker)

En tu máquina Docker no está disponible; usa una de estas opciones:

1. **Upstash (recomendado, gratis)** — [upstash.com](https://upstash.com) → crea base Redis → copia `REDIS_URL` (`rediss://...`) en `backend/.env` y `worker/.env` → reinicia backend y worker.
2. **Memurai** — Redis compatible en Windows. **Requiere PowerShell como administrador:**

   ```powershell
   cd C:\Proyectos\melodai_app
   .\scripts\install-memurai.ps1
   ```

   O manual: `winget install Memurai.MemuraiDeveloper --source winget`. Por defecto: `redis://127.0.0.1:6379`.
3. **Docker Desktop** — luego `docker compose up -d` en la raíz del repo.

Sin Redis alcanzable, el orquestador usa **modo stub** aunque `SEPARATION_WORKER_MODE=redis`.

## Requisitos

| Componente | Comprobación |
|------------|--------------|
| Redis | Upstash, Memurai, o `docker compose up -d` |
| Orquestador | `backend/.env`: `SEPARATION_WORKER_MODE=redis`, `REDIS_URL` |
| Worker | `worker/.env`: mismas `REDIS_URL` y `WORKER_API_KEY` |
| GCS | `backend/service-account.json` con lectura/escritura en el bucket |
| ffmpeg | `ffmpeg -version` en PATH (worker) |
| Demucs | `worker/.venv` + `pip install -r requirements.txt` |

## Arranque rápido (3 terminales)

```powershell
# Una vez — Redis + comprobaciones
.\scripts\start-pipeline.ps1

# Terminal 1 — Orquestador
cd backend
npm run dev
# Debe mostrar: [melodai] Redis OK — cola activa para el worker Python.
# Y al arrancar listen: Separación: modo redis

# Terminal 2 — Worker
cd worker
.venv\Scripts\activate
python main.py
# Debe mostrar: Conectado a Redis. HTDemucs: model=htdemucs_6s ...

# Terminal 3 — Flutter
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

## Verificar que no estás en stub

```powershell
Invoke-RestMethod http://127.0.0.1:3000/health | ConvertTo-Json
```

Esperado:

```json
"separation": {
  "configMode": "redis",
  "effectiveMode": "redis",
  "redisOk": true
}
```

Si `effectiveMode` es `stub`: Redis no responde o el backend se inició antes que Redis → reinicia `npm run dev`.

## Flujo en la app

1. Login → subir un audio (mejor **corto** en CPU; Demucs puede tardar varios minutos).
2. **Separar pistas** → polling hasta `completed`.
3. En la respuesta del job, cada stem debe tener `simulated: false` y `downloadUrl` no nulo.
4. Play en pantalla de separación o abrir el **Mixer**.

## Caché y reintentos

- Solo se reutiliza caché si la separación previa fue **real** (`simulated: false` en `separation_cache`).
- Si antes corriste en stub con el mismo SHA-256, el orquestador **vuelve a encolar** el worker (no devuelve metadatos vacíos).
- Sin MongoDB, jobs y caché se guardan en `backend/.data/` (sobreviven reinicios de `npm run dev`).

## Variables clave

**backend/.env**

```env
REDIS_URL=redis://127.0.0.1:6379
SEPARATION_WORKER_MODE=redis
WORKER_API_KEY=dev-worker-key-change-me
SEPARATION_REDIS_FALLBACK_STUB=true   # si Redis cae, stub (dev); en prod considera false
```

**worker/.env**

```env
REDIS_URL=redis://127.0.0.1:6379
WORKER_API_KEY=dev-worker-key-change-me   # igual que backend
DEMUCS_ENABLED=true
DEMUCS_MODEL=htdemucs_6s
DEMUCS_DEVICE=cpu                        # o cuda con GPU NVIDIA
DEMUCS_FALLBACK_STUB=false               # fallar en lugar de simular
GOOGLE_APPLICATION_CREDENTIALS=../backend/service-account.json
```

## Problemas frecuentes

| Síntoma | Causa | Acción |
|---------|-------|--------|
| `effectiveMode: stub` | Redis apagado | `docker compose up -d`, reiniciar backend |
| Job completa sin audio | Stub Node o caché stub antigua | Health en redis; sube archivo nuevo o otro hash |
| Worker no consume | Cola distinta / Redis distinto | Misma `REDIS_SEPARATION_QUEUE` en ambos `.env` |
| `Demucs falló` | Sin ffmpeg | `winget install ffmpeg`, nueva terminal |
| Muy lento | CPU + modelo 6 stems | Normal; prueba clips &lt; 30 s o `DEMUCS_DEVICE=cuda` |
| `403` en internal API | `WORKER_API_KEY` distinto | Unificar en backend y worker |

## Producción (resumen)

- Redis gestionado (Upstash, Memorystore, ElastiCache).
- `SEPARATION_REDIS_FALLBACK_STUB=false` para no completar jobs falsos si la cola falla.
- Worker en VM/GPU o RunPod con el mismo contrato `X-Worker-Key`.
- MongoDB Atlas para jobs y `separation_cache` persistentes.

Ver también: [ESTADO_FASE1.md](ESTADO_FASE1.md), [worker/README.md](../worker/README.md).
