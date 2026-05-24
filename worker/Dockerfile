# MelodAI worker — HTDemucs + GPU (RunPod / VM NVIDIA)
# Imagen base con PyTorch + CUDA 12.4 (no reinstalar torch en pip).
FROM pytorch/pytorch:2.4.1-cuda12.4-cudnn9-runtime

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    DEMUCS_DEVICE=cuda \
    DEMUCS_MODEL=htdemucs_6s \
    DEMUCS_FALLBACK_STUB=false \
    GOOGLE_APPLICATION_CREDENTIALS=/secrets/service-account.json

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-docker.txt .
RUN pip install --no-cache-dir -r requirements-docker.txt

COPY bootstrap_gcp.py config.py demucs_audio_patch.py demucs_main.py demucs_runner.py \
    gcs_client.py main.py orchestrator_client.py processor.py ssl_bootstrap.py stems.py ./

CMD ["python", "-u", "main.py"]
