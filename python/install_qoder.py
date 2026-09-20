"""
Installs the latest Qoder (AI IDE) silently.

Same approach as install_nvidia_app.py: scrape the official download page
for the current Windows installer link instead of hardcoding a version.
If Qoder changes their page/CDN this needs EXE_PATTERN updated below -
it will fail loudly rather than silently doing nothing.
"""
import re

from common import download, fail, log, run_silent_installer, temp_download_dir

import requests

DOWNLOAD_PAGE = "https://qoder.com/download"
EXE_PATTERN = re.compile(r"https://[^\"' ]+Qoder[^\"' ]*\.exe", re.IGNORECASE)


def find_latest_url() -> str:
    resp = requests.get(DOWNLOAD_PAGE, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
    resp.raise_for_status()
    match = EXE_PATTERN.search(resp.text)
    if not match:
        fail(
            "Nao achei o link do instalador do Qoder na pagina oficial. "
            f"Baixe manualmente em {DOWNLOAD_PAGE} e ajuste EXE_PATTERN em install_qoder.py."
        )
    return match.group(0)


def main() -> None:
    url = find_latest_url()
    dest = temp_download_dir() / "Qoder_setup.exe"
    download(url, dest)
    code = run_silent_installer(dest, ["/S"])
    if code != 0:
        fail(f"instalador do Qoder retornou codigo {code}")
    log("Qoder instalado")


if __name__ == "__main__":
    main()
