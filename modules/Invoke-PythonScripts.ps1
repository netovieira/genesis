# Creates a venv under python/.venv and installs requirements.txt into it,
# so the helper scripts don't pollute (or depend on) the system Python
# that winget just installed.

function Initialize-PythonEnv {
    param([Parameter(Mandatory)][string]$PythonDir)

    if (-not (Test-CommandExists 'python')) {
        throw "python nao encontrado no PATH (deveria ter vindo do winget). Abra um novo terminal e rode de novo."
    }

    $venv = Join-Path $PythonDir '.venv'
    if (-not (Test-Path $venv)) {
        python -m venv $venv
    }

    $pip = Join-Path $venv 'Scripts\pip.exe'
    & $pip install --quiet --upgrade pip
    & $pip install --quiet -r (Join-Path $PythonDir 'requirements.txt')
    Write-Ok "venv Python pronto em $venv"
    return (Join-Path $venv 'Scripts\python.exe')
}

function Invoke-PythonScript {
    param(
        [Parameter(Mandatory)][string]$PythonExe,
        [Parameter(Mandatory)][string]$ScriptPath
    )
    $dir = Split-Path -Parent $ScriptPath
    Push-Location $dir
    try {
        & $PythonExe $ScriptPath
        if ($LASTEXITCODE -ne 0) {
            throw "$(Split-Path -Leaf $ScriptPath) saiu com codigo $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}
