import json
import logging
import os
import sys

import certifi

# Windows: certificados del sistema para GCS / google-auth.
os.environ.setdefault("SSL_CERT_FILE", certifi.where())
os.environ.setdefault("REQUESTS_CA_BUNDLE", certifi.where())
try:
    import truststore

    truststore.inject_into_ssl()
except ImportError:
    pass

import redis

from config import Settings
from orchestrator_client import OrchestratorClient
from processor import process_job

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("melodai-worker")


def run() -> None:
    settings = Settings.from_env()
    api = OrchestratorClient(settings)

    client = redis.from_url(settings.redis_url, decode_responses=True)
    client.ping()
    logger.info("Conectado a Redis. Cola: %s", settings.redis_queue)
    logger.info("Callbacks → %s/internal/separation/jobs/…", settings.orchestrator_url)
    if settings.demucs_enabled:
        logger.info(
            "HTDemucs: model=%s device=%s fallback_stub=%s",
            settings.demucs_model,
            settings.demucs_device,
            settings.demucs_fallback_stub,
        )
    else:
        logger.info("HTDemucs desactivado (DEMUCS_ENABLED=false) — modo stub")

    while True:
        item = client.brpop(settings.redis_queue, timeout=5)
        if item is None:
            continue

        _queue, raw = item
        try:
            job = json.loads(raw)
        except json.JSONDecodeError:
            logger.error("Mensaje inválido en cola: %s", raw[:200])
            continue

        job_id = job.get("jobId", "?")
        logger.info("Procesando job %s (%s)", job_id, job.get("fileName", ""))

        try:
            process_job(job, settings, api)
        except Exception as exc:
            logger.exception("Job %s falló", job_id)
            try:
                api.report_fail(job_id, str(exc))
            except Exception as report_exc:
                logger.error("No se pudo reportar fallo: %s", report_exc)


if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        logger.info("Worker detenido.")
        sys.exit(0)
