# Runs `python thero.py` (no args = full flow) from the myscripts/thero
# submodule that comes with the "myscripts" clone in config/projects.json.
# That flow installs Claude Code skills globally (~/.claude/skills),
# consolidates the global CLAUDE.md, and installs/updates the `thero`
# shortcut command - which, on Windows, means adding a function to
# $PROFILE. That's why this runs AFTER the "PowerShellProfile" step: it
# appends onto the profile this project already restored, instead of the
# profile-restore step later overwriting what thero just added.

function Install-TheroGlobal {
    param([string]$ProjectsDir = (Join-Path $HOME 'projects'))

    $theroScript = Join-Path $ProjectsDir 'myscripts\thero\thero.py'
    if (-not (Test-Path $theroScript)) {
        throw "thero.py nao encontrado em $theroScript - confirme que 'myscripts' esta em config/projects.json e foi clonado (com submodulos)"
    }
    if (-not (Test-CommandExists 'python')) {
        throw "python nao encontrado no PATH (deveria ter vindo do winget)"
    }

    Push-Location (Split-Path -Parent $theroScript)
    try {
        python thero.py
        if ($LASTEXITCODE -ne 0) {
            throw "thero.py saiu com codigo $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
    Write-Ok "thero instalado globalmente (skills, CLAUDE.md, comando 'thero')"
}
