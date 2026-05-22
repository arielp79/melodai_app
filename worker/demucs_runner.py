import logging
import sys
import tempfile
from pathlib import Path

from config import Settings
from demucs_audio_patch import apply_demucs_audio_patch
from ssl_bootstrap import apply_windows_ssl
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

_model_prewarmed: set[str] = set()


def prewarm_demucs_model(model_name: str) -> None:
    """Descarga pesos HTDemucs al arrancar el worker (mismo proceso = SSL OK)."""
    if model_name in _model_prewarmed:
        return
    apply_windows_ssl()
    apply_demucs_audio_patch()
    from demucs.pretrained import get_model

    logger.info("Precargando modelo Demucs %s (puede tardar en la primera vez)…", model_name)
    get_model(model_name)
    _model_prewarmed.add(model_name)
    logger.info("Modelo Demucs %s listo.", model_name)


def run_htdemucs(mix_path: Path, settings: Settings) -> dict[str, Path]:
    """
    Ejecuta Demucs (modelo HTDemucs) en el mismo proceso que el worker.
    Requiere: pip install demucs torch torchaudio y ffmpeg en PATH.
    """
    apply_windows_ssl()
    apply_demucs_audio_patch()
    prewarm_demucs_model(settings.demucs_model)

    with tempfile.TemporaryDirectory(prefix="melodai_demucs_") as tmp:
        out_root = Path(tmp)
        demucs_argv = [
            "demucs",
            "-n",
            settings.demucs_model,
            "-d",
            settings.demucs_device,
            "-o",
            str(out_root),
            str(mix_path),
        ]
        logger.info("Demucs (in-process): %s", " ".join(demucs_argv[1:]))

        try:
            from demucs.separate import main as demucs_main

            demucs_main(demucs_argv[1:])
        except SystemExit as exc:
            code = exc.code if exc.code is not None else 1
            if code != 0:
                raise RuntimeError(
                    f"Demucs terminó con código {code}. "
                    "¿ffmpeg instalado? ¿GPU/CUDA? Revisa logs del worker.",
                ) from exc
        except Exception as exc:
            raise RuntimeError(
                f"Demucs falló: {exc}. ¿ffmpeg instalado? ¿GPU/CUDA?",
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
