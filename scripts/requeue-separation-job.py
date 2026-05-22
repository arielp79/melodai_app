"""Reencola un job atascado o fallido vía API del orquestador."""
import os
import sys
from pathlib import Path

import requests
from dotenv import load_dotenv

root = Path(__file__).resolve().parents[1]
load_dotenv(root / "backend" / ".env")
load_dotenv(root / "worker" / ".env")

job_id = sys.argv[1] if len(sys.argv) > 1 else None
if not job_id:
    print("Uso: python scripts/requeue-separation-job.py <jobId>")
    sys.exit(1)

base = os.getenv("ORCHESTRATOR_URL", "http://127.0.0.1:3000").rstrip("/")
key = os.getenv("WORKER_API_KEY", "")
url = f"{base}/internal/separation/jobs/{job_id}/requeue"
resp = requests.post(url, headers={"X-Worker-Key": key}, timeout=30)
resp.raise_for_status()
print(resp.json())
print("Asegúrate de que el worker Python está corriendo (python main.py).")
