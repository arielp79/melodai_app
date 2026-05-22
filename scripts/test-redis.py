"""Comprueba REDIS_URL (backend/.env o variable de entorno)."""
import os
import sys
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None

root = Path(__file__).resolve().parents[1]
env_path = root / "backend" / ".env"
if load_dotenv and env_path.is_file():
    load_dotenv(env_path)

url = os.getenv("REDIS_URL", "").strip()
if not url:
    print("REDIS_URL no definida en backend/.env")
    sys.exit(1)

try:
    import redis
except ImportError:
    print("pip install redis  (o usa el venv del worker)")
    sys.exit(1)

client = redis.from_url(url)
client.ping()
print(f"OK — Redis responde en {url.split('@')[-1] if '@' in url else url}")
