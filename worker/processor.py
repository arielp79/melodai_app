import logging
import time
from pathlib import Path

from config import Settings
from demucs_runner import run_htdemucs
from gcs_client import download_mix, safe_rmtree, safe_unlink, upload_stem
from orchestrator_client import OrchestratorClient
from stems import build_stems

logger = logging.getLogger(__name__)


def _run_stub_pipeline(
    job_id: str,
    sha256: str,
    mix_path: Path,
    settings: Settings,
    api: OrchestratorClient,
) -> None:
    step_ms = max(500, settings.stub_delay_ms // 4)
    time.sleep(step_ms / 1000)
    api.report_progress(job_id, 40)
    time.sleep(step_ms / 1000)
    api.report_progress(job_id, 75)
    time.sleep(step_ms / 1000)
    stems = build_stems(sha256, simulated=True)
    api.report_complete(job_id, stems, simulated=True)
    logger.info("Job %s completado (stub, %s pistas)", job_id, len(stems))


def _run_demucs_pipeline(
    job_id: str,
    sha256: str,
    mix_path: Path,
    job: dict,
    settings: Settings,
    api: OrchestratorClient,
) -> None:
    bucket_name = job["gcsBucket"]

    api.report_progress(job_id, 20, "processing")
    local_stems = run_htdemucs(mix_path, settings)
    api.report_progress(job_id, 55, "processing")

    stem_ids = list(local_stems.keys())
    stems_meta = build_stems(sha256, simulated=False, stem_ids=stem_ids)

    for i, meta in enumerate(stems_meta):
        stem_id = meta["id"]
        local_path = local_stems[stem_id]
        upload_stem(
            bucket_name=bucket_name,
            object_key=meta["objectKey"],
            local_path=local_path,
            settings=settings,
        )
        progress = 55 + int((i + 1) / len(stems_meta) * 40)
        api.report_progress(job_id, min(progress, 95))

    api.report_progress(job_id, 98)
    api.report_complete(job_id, stems_meta, simulated=False)
    logger.info(
        "Job %s completado (HTDemucs %s, %s pistas → GCS)",
        job_id,
        settings.demucs_model,
        len(stems_meta),
    )

    # Limpiar copias locales de stems
    if local_stems:
        first = next(iter(local_stems.values()))
        safe_rmtree(first.parent)


def process_job(job: dict, settings: Settings, api: OrchestratorClient) -> None:
    job_id = job["jobId"]
    sha256 = job["sha256"]
    mix_path: Path | None = None

    try:
        api.report_progress(job_id, 2, "processing")
        mix_path = download_mix(job, settings)
        api.report_progress(job_id, 10, "processing")

        if settings.demucs_enabled:
            try:
                _run_demucs_pipeline(
                    job_id, sha256, mix_path, job, settings, api,
                )
                return
            except Exception as exc:
                logger.exception("HTDemucs falló para job %s", job_id)
                if not settings.demucs_fallback_stub:
                    raise
                logger.warning("DEMUCS_FALLBACK_STUB=true → stub")
                api.report_progress(job_id, 15, "processing")

        _run_stub_pipeline(job_id, sha256, mix_path, settings, api)
    finally:
        safe_unlink(mix_path)
