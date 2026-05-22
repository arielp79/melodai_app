"""
CLI de Demucs con SSL de Windows aplicado antes de importar torch.

`python -m demucs` arranca un proceso hijo sin truststore → falla torch.hub en
Python 3.14+ con CERTIFICATE_VERIFY_FAILED. El worker invoca este script.
"""

from ssl_bootstrap import apply_windows_ssl

apply_windows_ssl()

from demucs.separate import main

if __name__ == "__main__":
    main()
