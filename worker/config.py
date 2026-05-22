import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    redis_url: str
    redis_queue: str
    orchestrator_url: str
    worker_api_key: str
    stub_delay_ms: int
    gcs_credentials: str
    demucs_enabled: bool
    demucs_model: str
    demucs_device: str
    demucs_fallback_stub: bool

    @classmethod
    def from_env(cls) -> "Settings":
        redis_url = os.getenv("REDIS_URL", "").strip()
        worker_api_key = os.getenv("WORKER_API_KEY", "").strip()
        orchestrator_url = os.getenv("ORCHESTRATOR_URL", "http://127.0.0.1:3000").strip().rstrip("/")
        gcs_credentials = os.getenv(
            "GOOGLE_APPLICATION_CREDENTIALS",
            "../backend/service-account.json",
        ).strip()

        if not redis_url:
            raise ValueError("REDIS_URL es obligatoria para el worker.")
        if not worker_api_key:
            raise ValueError("WORKER_API_KEY es obligatoria (misma que en backend/.env).")
        if not os.path.isfile(gcs_credentials):
            raise ValueError(
                f"GOOGLE_APPLICATION_CREDENTIALS no encontrado: {gcs_credentials}",
            )

        demucs_enabled = os.getenv("DEMUCS_ENABLED", "true").lower() in (
            "1",
            "true",
            "yes",
        )

        return cls(
            redis_url=redis_url,
            redis_queue=os.getenv("REDIS_SEPARATION_QUEUE", "melodai:separation:jobs").strip(),
            orchestrator_url=orchestrator_url,
            worker_api_key=worker_api_key,
            stub_delay_ms=int(os.getenv("WORKER_STUB_DELAY_MS", "8000")),
            gcs_credentials=os.path.abspath(gcs_credentials),
            demucs_enabled=demucs_enabled,
            demucs_model=os.getenv("DEMUCS_MODEL", "htdemucs_6s").strip(),
            demucs_device=os.getenv("DEMUCS_DEVICE", "cpu").strip(),
            demucs_fallback_stub=os.getenv("DEMUCS_FALLBACK_STUB", "false").lower()
            in ("1", "true", "yes"),
        )
