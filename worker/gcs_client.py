import logging
import os
import tempfile
from pathlib import Path

# Certificados Windows antes de importar google.cloud.
import certifi

os.environ.setdefault("SSL_CERT_FILE", certifi.where())
os.environ.setdefault("REQUESTS_CA_BUNDLE", certifi.where())
try:
    import truststore

    truststore.inject_into_ssl()
except ImportError:
    pass

from google.cloud import storage

from config import Settings

logger = logging.getLogger(__name__)


def download_mix(job: dict, settings: Settings) -> Path:
    """Descarga el mix subido por Flutter desde GCS a un archivo temporal."""
    bucket_name = job.get("gcsBucket")
    object_key = job.get("objectKey")

    if not bucket_name:
        raise ValueError("gcsBucket ausente en el payload del job.")
    if not object_key:
        raise ValueError("objectKey ausente en el payload del job.")

    client = storage.Client.from_service_account_json(settings.gcs_credentials)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_key)

    if not blob.exists():
        raise FileNotFoundError(
            f"Archivo no encontrado: gs://{bucket_name}/{object_key}",
        )

    suffix = Path(object_key).suffix or ".audio"
    fd, temp_path = tempfile.mkstemp(prefix="melodai_mix_", suffix=suffix)
    os.close(fd)
    path = Path(temp_path)

    blob.download_to_filename(str(path))
    size = path.stat().st_size
    logger.info(
        "Mix descargado (%s bytes): gs://%s/%s → %s",
        size,
        bucket_name,
        object_key,
        path,
    )
    return path


def upload_stem(
    *,
    bucket_name: str,
    object_key: str,
    local_path: Path,
    settings: Settings,
) -> None:
    client = storage.Client.from_service_account_json(settings.gcs_credentials)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_key)
    blob.upload_from_filename(
        str(local_path),
        content_type="audio/wav",
    )
    logger.info(
        "Stem subido: gs://%s/%s (%s bytes)",
        bucket_name,
        object_key,
        local_path.stat().st_size,
    )


def safe_unlink(path: Path | None) -> None:
    if path is None:
        return
    try:
        path.unlink(missing_ok=True)
    except OSError as exc:
        logger.warning("No se pudo borrar temporal %s: %s", path, exc)


def safe_rmtree(path: Path | None) -> None:
    if path is None or not path.is_dir():
        return
    import shutil

    try:
        shutil.rmtree(path, ignore_errors=True)
    except OSError as exc:
        logger.warning("No se pudo borrar carpeta %s: %s", path, exc)
