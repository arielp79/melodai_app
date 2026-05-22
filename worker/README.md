# MelodAI — Worker Python (HTDemucs + Redis)

Consume jobs de Redis, separa audio con **HTDemucs** (`htdemucs_6s`: voz, bajo, batería, guitarra, piano), sube stems a GCS y reporta al orquestador Node.

## Requisitos

- Python 3.10+
- **ffmpeg** en PATH ([descarga](https://ffmpeg.org/) o `winget install ffmpeg`)
- Redis (Docker, Upstash o local)
- Orquestador Node (`backend/npm run dev`)
- `service-account.json` con permiso de lectura/escritura en el bucket

## Instalación

```powershell
cd worker
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

**GPU NVIDIA (opcional, mucho más rápido):**

```powershell
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu124
```

En `.env`: `DEMUCS_DEVICE=cuda`

**Solo CPU (Windows sin GPU):** deja `DEMUCS_DEVICE=cpu` (puede tardar varios minutos por canción).

## Variables (`worker/.env`)

| Variable | Descripción |
|----------|-------------|
| `REDIS_URL` | Cola de jobs |
| `WORKER_API_KEY` | Igual que en `backend/.env` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta a `service-account.json` |
| `DEMUCS_ENABLED` | `true` = HTDemucs; `false` = solo stub |
| `DEMUCS_MODEL` | `htdemucs_6s` (5 pistas PRD) o `htdemucs` (4 pistas) |
| `DEMUCS_DEVICE` | `cpu` o `cuda` |
| `DEMUCS_FALLBACK_STUB` | Si Demucs falla, ¿completar en stub? (`false` recomendado) |

## Ejecutar (3 terminales)

```powershell
# 1 — Orquestador (modo redis o fallback stub si no hay Redis)
cd backend
npm run dev

# 2 — Worker
cd worker
.venv\Scripts\activate
python main.py

# 3 — Flutter
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Flujo: subir audio → **Separar pistas** → el worker descarga el mix, ejecuta Demucs, sube `stems/{sha256}/*.wav` → en la app cada pista tiene botón **play**.

## Redis sin Docker

[Upstash](https://upstash.com) → copia `REDIS_URL` (`rediss://...`) en `backend/.env` y `worker/.env`.

## API interna

`POST /internal/separation/jobs/:id/progress|complete|fail` con cabecera `X-Worker-Key`.

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| `Demucs falló` / ffmpeg | Instala ffmpeg y reinicia la terminal |
| `CUDA not available` | Usa `DEMUCS_DEVICE=cpu` |
| Muy lento | Normal en CPU; usa GPU o canciones cortas para pruebas |
| `CERTIFICATE_VERIFY_FAILED` (Windows) | Python 3.14 + descarga modelo | Reinicia `python main.py`; el worker precarga el modelo con truststore al inicio |
| `TorchCodec is required` | TorchAudio 2.9+ al guardar WAV | `pip install soundfile` y reinicia el worker (parche automático en `demucs_audio_patch.py`) |
| Pistas sin play en app | Comprueba que el job terminó con `simulated: false` y archivos en Firebase Storage → `stems/...` |
