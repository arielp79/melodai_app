"""Escribe service-account.json desde GOOGLE_SERVICE_ACCOUNT_JSON (RunPod / Docker)."""

import os
from pathlib import Path


def prepare_gcp_credentials() -> None:
    raw = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "").strip()
    if not raw:
        return
    json_str = raw
    if (json_str.startswith('"') and json_str.endswith('"')) or (
        json_str.startswith("'") and json_str.endswith("'")
    ):
        json_str = json_str[1:-1].strip()
    if not json_str.startswith("{"):
        print(
            "[melodai-worker] GOOGLE_SERVICE_ACCOUNT_JSON debe ser JSON (empieza con {).",
        )
        return

    path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "/secrets/service-account.json").strip()
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json_str, encoding="utf-8")
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(target)
