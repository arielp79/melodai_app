# MelodAI App

Cliente Flutter (Feature-First) + orquestador Node.js para subida de audio con presigned URLs y deduplicación SHA-256.

**Estado y roadmap Fase 1:** [docs/ESTADO_FASE1.md](docs/ESTADO_FASE1.md)

**Pipeline real (Redis + worker HTDemucs):** [docs/PIPELINE_REAL.md](docs/PIPELINE_REAL.md) — `.\scripts\start-pipeline.ps1`

## Flutter

```bash
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

## Backend (orquestador)

Ver [backend/README.md](backend/README.md).

```bash
cd backend
cp .env.example .env
# Añade service-account.json de Firebase
npm install
npm run dev
```

## Flujo de subida

1. App calcula SHA-256 del archivo.
2. `POST /uploads/presign` → URL firmada o `cached: true`.
3. App hace `PUT` directo al bucket (si no está en caché).
4. `POST /uploads/complete` → registra el hash para deduplicación futura.
5. `POST /separation/jobs` → job de separación Fase 1; `GET /separation/jobs/:id` para seguir el progreso.

## Worker de separación (Python + Redis)

```bash
docker compose up -d          # Redis en :6379
cd backend && npm run dev
cd worker && python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Detalle: [worker/README.md](worker/README.md) (HTDemucs, ffmpeg, GPU/CPU).

**Audio en Windows:** depende de `just_audio_windows`. Tras `flutter pub get`, haz **rebuild completo** (no solo hot reload):

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000
```
