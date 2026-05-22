import logging
import subprocess
import sys
import tempfile
from pathlib import Path

from config import Settings
from stems import PHASE1_STEMS

logger = logging.getLogger(__name__)

# Salida de htdemucs_6s (6 fuentes). El PRD usa 5; omitimos "other".
DEMUCS_OUTPUT_FILES = {
    "vocals": "vocals.wav",
    "bass": "bass.wav",
    "drums": "drums.wav",
    "guitar": "guitar.wav",
    "piano": "piano.wav",
}


def run_htdemucs(mix_path: Path, settings: Settings) -> dict[str, Path]:
    """
    Ejecuta Demucs (modelo HTDemucs) y devuelve rutas locales por stem id.
    Requiere: pip install demucs torch torchaudio y ffmpeg en PATH.
    """
    with tempfile.TemporaryDirectory(prefix="melodai_demucs_") as tmp:
        out_root = Path(tmp)
        cmd = [
            sys.executable,
            "-m",
            "demucs",
            "-n",
            settings.demucs_model,
            "-d",
            settings.demucs_device,
            "-o",
            str(out_root),
            str(mix_path),
        ]
        logger.info("Demucs: %s", " ".join(cmd))

        try:
            completed = subprocess.run(
                cmd,
                check=True,
                capture_output=True,
                text=True,
            )
            if completed.stdout:
                logger.debug(completed.stdout[-2000:])
        except subprocess.CalledProcessError as exc:
            stderr = (exc.stderr or "").strip()
            raise RuntimeError(
                f"Demucs falló (exit {exc.returncode}). "
                f"¿ffmpeg instalado? ¿GPU/CUDA? Detalle: {stderr[-1500:]}",
            ) from exc

        model_dir = out_root / settings.demucs_model
        if not model_dir.is_dir():
            raise RuntimeError(
                f"No se encontró salida en {model_dir}. "
                f"Contenido: {list(out_root.iterdir())}",
            )

        track_dirs = [p for p in model_dir.iterdir() if p.is_dir()]
        if not track_dirs:
            raise RuntimeError(f"Sin carpeta de pista en {model_dir}")

        stem_dir = track_dirs[0]
        logger.info("Pistas generadas en %s", stem_dir)

        # Copiar a temporales persistentes (el TMP de demucs se borra al salir del with)
        result: dict[str, Path] = {}
        copy_root = Path(tempfile.mkdtemp(prefix="melodai_stems_"))
        for stem_id, _label in PHASE1_STEMS:
            filename = DEMUCS_OUTPUT_FILES.get(stem_id)
            if not filename:
                continue
            src = stem_dir / filename
            if not src.is_file():
                if settings.demucs_model == "htdemucs_6s":
                    logger.warning("Pista no generada: %s", filename)
                continue
            dest = copy_root / filename
            dest.write_bytes(src.read_bytes())
            result[stem_id] = dest

        if len(result) < 3:
            available = list(stem_dir.glob("*.wav"))
            raise RuntimeError(
                f"Pistas insuficientes ({len(result)}/5). "
                f"En disco: {[p.name for p in available]}. "
                "Prueba DEMUCS_MODEL=htdemucs_6s o revisa el audio de entrada.",
            )

        return result
