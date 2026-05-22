"""Certificados SSL en Windows (GCS, torch.hub, Demucs)."""

import os
import platform

import certifi


def apply_windows_ssl() -> None:
    """
    En Windows usa el almacén del sistema (truststore).
    No fijar SSL_CERT_FILE a certifi: en Python 3.14 provoca
    CERTIFICATE_VERIFY_FAILED al descargar modelos con torch.hub.
    """
    if platform.system() == "Windows":
        try:
            import truststore

            truststore.inject_into_ssl()
            return
        except ImportError:
            pass

    os.environ.setdefault("SSL_CERT_FILE", certifi.where())
    os.environ.setdefault("REQUESTS_CA_BUNDLE", certifi.where())
    try:
        import truststore

        truststore.inject_into_ssl()
    except ImportError:
        pass
