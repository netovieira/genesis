"""Shared helpers for the Genesis python scripts."""
import subprocess
import sys
import tempfile
from pathlib import Path

import requests


def log(msg: str) -> None:
    print(f"    [py] {msg}", flush=True)


def download(url: str, dest: Path, timeout: int = 60) -> Path:
    log(f"baixando {url}")
    resp = requests.get(url, timeout=timeout, allow_redirects=True, stream=True,
                         headers={"User-Agent": "Mozilla/5.0"})
    resp.raise_for_status()
    dest.parent.mkdir(parents=True, exist_ok=True)
    with open(dest, "wb") as f:
        for chunk in resp.iter_content(chunk_size=1 << 16):
            f.write(chunk)
    return dest


def run_silent_installer(installer_path: Path, silent_args: list[str]) -> int:
    log(f"instalando {installer_path.name} {' '.join(silent_args)}")
    result = subprocess.run([str(installer_path), *silent_args])
    return result.returncode


def temp_download_dir() -> Path:
    d = Path(tempfile.gettempdir()) / "genesis-downloads"
    d.mkdir(parents=True, exist_ok=True)
    return d


def fail(msg: str) -> None:
    log(f"ERRO: {msg}")
    sys.exit(1)
