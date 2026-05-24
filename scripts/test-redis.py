"""Comprueba REDIS_URL en backend/.env."""
import os
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
env_path = root / "backend" / ".env"


def load_redis_url() -> str:
    if not env_path.is_file():
        return ""
    for line in env_path.read_text(encoding="utf-8-sig").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("REDIS_URL="):
            return stripped.split("=", 1)[1].strip().strip('"').strip("'")
    return os.getenv("REDIS_URL", "").strip()


url = load_redis_url()
if not url:
    print("REDIS_URL no definida en backend/.env")
    print(f"  Archivo esperado: {env_path}")
    sys.exit(1)

if url.startswith("redis-cli"):
    print(
        "REDIS_URL incorrecta: pegaste el comando redis-cli de Upstash.\n"
        "Usa solo la URL rediss://... (Connect → Redis URL)."
    )
    sys.exit(1)

if not url.startswith(("redis://", "rediss://")):
    print(f"REDIS_URL invalida (debe empezar por redis:// o rediss://): {url[:50]}...")
    sys.exit(1)

if url.startswith("rediss://"):
    worker_root = root / "worker"
    if worker_root.is_dir() and str(worker_root) not in sys.path:
        sys.path.insert(0, str(worker_root))
    try:
        from ssl_bootstrap import apply_windows_ssl

        apply_windows_ssl()
    except ImportError:
        pass

try:
    import redis
except ImportError:
    print("Falta el paquete redis en este Python.")
    print("Ejecuta: .\\scripts\\test-redis.ps1")
    print("  (usa worker\\.venv\\Scripts\\python.exe)")
    sys.exit(1)

try:
    client = redis.from_url(url)
    client.ping()
except Exception as exc:
    print(f"Error conectando a Redis: {exc}")
    sys.exit(1)

host = url.split("@")[-1] if "@" in url else url
print(f"OK - Redis responde en {host}")
