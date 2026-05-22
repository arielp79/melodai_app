import requests

from config import Settings


class OrchestratorClient:
    def __init__(self, settings: Settings):
        self._base = settings.orchestrator_url
        self._headers = {
            "Content-Type": "application/json",
            "X-Worker-Key": settings.worker_api_key,
        }

    def report_progress(self, job_id: str, progress: int, status: str = "processing") -> None:
        url = f"{self._base}/internal/separation/jobs/{job_id}/progress"
        resp = requests.post(
            url,
            json={"progress": progress, "status": status},
            headers=self._headers,
            timeout=30,
        )
        resp.raise_for_status()

    def report_complete(self, job_id: str, stems: list[dict], *, simulated: bool) -> None:
        url = f"{self._base}/internal/separation/jobs/{job_id}/complete"
        resp = requests.post(
            url,
            json={"stems": stems, "phase": 1, "simulated": simulated},
            headers=self._headers,
            timeout=60,
        )
        resp.raise_for_status()

    def report_fail(self, job_id: str, error: str) -> None:
        url = f"{self._base}/internal/separation/jobs/{job_id}/fail"
        resp = requests.post(
            url,
            json={"error": error},
            headers=self._headers,
            timeout=30,
        )
        resp.raise_for_status()
