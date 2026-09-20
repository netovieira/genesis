"""
Installs the latest NVIDIA App silently.

NVIDIA does not publish a stable "always latest" direct link, so this
scrapes the official download page for the current installer URL. If
NVIDIA changes the page layout this will stop matching - that's a
maintenance point, not a silent failure: it exits with an error telling
you to update DOWNLOAD_PAGE/PATTERN below instead of installing nothing
and pretending it worked.
"""
import re

from common import download, fail, log, run_silent_installer, temp_download_dir

import requests

DOWNLOAD_PAGE = "https://www.nvidia.com/en-us/software/nvidia-app/"
# Matches installer URLs like https://us.download.nvidia.com/nvapp/client/.../NVIDIA_app_v*.exe
EXE_PATTERN = re.compile(r"https://[^\"' ]+NVIDIA_app[^\"' ]*\.exe", re.IGNORECASE)


def find_latest_url() -> str:
    resp = requests.get(DOWNLOAD_PAGE, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
    resp.raise_for_status()
    match = EXE_PATTERN.search(resp.text)
    if not match:
        fail(
            "Nao achei o link do instalador na pagina da Nvidia. "
            f"Baixe manualmente em {DOWNLOAD_PAGE} e ajuste EXE_PATTERN em install_nvidia_app.py."
        )
    return match.group(0)


def main() -> None:
    url = find_latest_url()
    dest = temp_download_dir() / "NVIDIA_app_setup.exe"
    download(url, dest)
    code = run_silent_installer(dest, ["-s"])
    if code != 0:
        fail(f"instalador da Nvidia retornou codigo {code}")
    log("NVIDIA App instalado")


if __name__ == "__main__":
    main()
