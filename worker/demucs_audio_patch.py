"""
Parche para Demucs: TorchAudio 2.9+ exige torchcodec (frágil en Windows).

Reemplaza save_audio por soundfile (PCM 16/24/32 y FLAC); MP3 sigue con lameenc.
"""

from __future__ import annotations

import logging
from pathlib import Path
import typing as tp

import numpy as np
import soundfile as sf
import torch

logger = logging.getLogger(__name__)

_patched = False


def apply_demucs_audio_patch() -> None:
    global _patched
    if _patched:
        return

    import demucs.audio as demucs_audio

    def save_audio(
        wav: torch.Tensor,
        path: tp.Union[str, Path],
        samplerate: int,
        bitrate: int = 320,
        clip: tp.Literal["rescale", "clamp", "tanh", "none"] = "rescale",
        bits_per_sample: tp.Literal[16, 24, 32] = 16,
        as_float: bool = False,
        preset: tp.Literal[2, 3, 4, 5, 6, 7] = 2,
    ) -> None:
        wav = demucs_audio.prevent_clip(wav, mode=clip)
        path = Path(path)
        suffix = path.suffix.lower()
        if suffix == ".mp3":
            demucs_audio.encode_mp3(
                wav, path, samplerate, bitrate, preset, verbose=True,
            )
            return
        if suffix not in (".wav", ".flac"):
            raise ValueError(f"Invalid suffix for path: {suffix}")

        data = wav.detach().cpu().numpy()
        if data.ndim == 2:
            data = data.T  # (frames, channels) para soundfile

        if suffix == ".flac":
            sf.write(str(path), data, samplerate, format="FLAC")
            return

        if as_float or bits_per_sample == 32:
            sf.write(str(path), data.astype(np.float32), samplerate, subtype="FLOAT")
        elif bits_per_sample == 24:
            sf.write(str(path), data, samplerate, subtype="PCM_24")
        else:
            sf.write(str(path), data, samplerate, subtype="PCM_16")

    demucs_audio.save_audio = save_audio
    try:
        import demucs.separate as demucs_separate

        demucs_separate.save_audio = save_audio
    except ImportError:
        pass

    _patched = True
    logger.debug("Parche Demucs save_audio (soundfile) aplicado.")
