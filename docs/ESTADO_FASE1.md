# Resumen técnico — MelodAI (estado al cerrar Fase 1)

Cliente Flutter Feature-First + orquestador Node.js: auth, subida directa al bucket (presigned URLs + SHA-256), jobs de separación Fase 1, reproducción y mixer multicanal básico. **Sin export ni Fase 2 (AudioSep).**

## Objetivo cubierto (PRD)

- Auth email/contraseña
- Upload con deduplicación por hash
- Separación por jobs (5 stems del PRD)
- Reproducción del mix y stems
- Mixer multicanal básico en cliente

## Stack y arquitectura

| Capa | Tecnología |
|------|------------|
| **App** | Flutter, go_router, http, just_audio + just_audio_windows |
| **Orquestador** | Express 5, firebase-admin, GCS signed URLs v4, ioredis |
| **Worker** | Python 3, Redis BRPOP, google-cloud-storage, Demucs `htdemucs_6s` |
| **Persistencia** | MongoDB opcional; sin URI → memoria (uploads + jobs) |

**Feature-First:** `core/`, `features/auth`, `upload`, `separation`, `mixer` (placeholder futuro: `export`).

## Implementado por bloques

### 1. Auth

- Email/contraseña.
- En Windows: auth REST (Identity Toolkit) + `AuthSessionStore` / refresh token.
- Backend: validación de token vía `accounts:lookup` + OAuth2; `node --use-system-ca` en Windows.

### 2. Upload

1. Cliente calcula SHA-256.
2. `POST /uploads/presign` → URL firmada o `cached: true`.
3. `PUT` directo al bucket (si no está en caché).
4. `POST /uploads/complete` → registra hash para deduplicación.

- Dedup por hash (memoria o MongoDB).
- Bucket autodetectado; `GCS_BUCKET_NAME` sin prefijo `gs://`.

### 3. Separación

- `POST /separation/jobs`, `GET /separation/jobs/:id` (polling en Flutter).
- Estados: `queued` → `processing` → `completed` / `failed`.
- Caché por SHA-256 en `separation_cache`.
- 5 stems PRD: `vocals`, `bass`, `drums`, `guitar`, `piano`.

### 4. Cola y worker

| Modo | Comportamiento |
|------|----------------|
| **redis** | LPUSH en cola; worker Python consume y llama API interna (`X-Worker-Key`). |
| **stub** | Node o Python simulan ~8 s sin archivos reales. |

- `SEPARATION_REDIS_FALLBACK_STUB`: si Redis no responde, Node no falla el job → stub.
- Worker: descarga mix GCS → HTDemucs → subida `stems/{sha256}/*.wav` → complete con `simulated: false`.

### 5. Audio / mixer

- `sourceAudioUrl` y `downloadUrl` (presigned GET) en respuestas de job.
- Pantalla separación: play mix + pistas.
- Mixer multicanal: un `AudioPlayer` por canal, play/pause/stop global, faders, mute, solo, master.

## Decisiones técnicas relevantes

| Tema | Decisión |
|------|----------|
| **Presigned URLs** | El binario no pasa por Node; solo presign + confirmación. |
| **SHA-256 en cliente** | Dedup en orquestador; ahorro de GPU en reprocesos. |
| **Auth Windows por REST** | Evita fallos SSL del SDK C++ de Firebase. |
| **Token backend** | REST `accounts:lookup`, no `verifyIdToken` directo del Admin en Windows. |
| **Cola Redis + worker desacoplado** | Contrato estable para sustituir stub por GPU/RunPod. |
| **htdemucs_6s** | Alineado con las 5 pistas del PRD (no el modelo de 4 stems). |
| **just_audio_windows** | Obligatorio; sin él, `MissingPluginException` en desktop. |
| **Mixer con N reproductores** | Simplicidad en MVP; sin mezcla en servidor ni DSP nativo aún. |

## Problemas resueltos en el camino

| Síntoma | Causa | Fix |
|---------|-------|-----|
| HTTP 500 presign | Bucket inexistente | Activar Storage en Firebase |
| Connection closed | Async sin handler / reinicio `--watch` | `asyncHandler`, fallback Redis, rebuild estable |
| `gs://` en bucket name | Formato incorrecto en `.env` | Normalización en `config.js` |
| Redis max retries | Redis no corriendo | Fallback stub + doc Upstash/Docker |
| No audio / stub | Sin worker HTDemucs o sin `.wav` en GCS | Pipeline worker + URLs firmadas |
| No reproduce en Windows | Falta plugin nativo | `just_audio_windows` + rebuild completo |

## Estado operativo típico

**Funciona:** login, subida, jobs de separación (UI + progreso), mixer UI, play del mix original (tras rebuild).

**Stems reales:** requieren Redis + worker + ffmpeg + HTDemucs y archivos en GCS. Si solo stub → metadatos sin audio reproducible.

## Próximos pasos (orden PRD)

1. **Cerrar pipeline real en dev/prod** — Redis (p. ej. Upstash), worker estable, HTDemucs en CPU/GPU, verificar stems en Storage y play en app (`simulated: false`).
2. **`features/export/`** — Descarga stems o ZIP.
3. **Infra producción** — MongoDB Atlas, despliegue orquestador, pre-calentamiento GPU (Redis) para Fase 2.
4. **Fase 2** — AudioSep / instrumentos raros.
5. **Mixer avanzado** — Sincronización al play, niveles, export de mezcla (opcional).

## En una frase

MVP de auth + upload + separación por jobs + worker HTDemucs (código listo) + mixer multicanal en Flutter; el cuello de botella operativo es infra de cola/GPU y archivos reales en el bucket, no el contrato de la API. El siguiente hito de producto es **export** y **separación real end-to-end en producción**.

## Referencias en el repo

- Arranque rápido: [README.md](../README.md)
- **Pipeline real (Redis + HTDemucs):** [PIPELINE_REAL.md](PIPELINE_REAL.md)
- Orquestador: [backend/README.md](../backend/README.md)
- Worker: [worker/README.md](../worker/README.md)
