# Creates the projects folder and clones every repo listed in
# config/projects.json. Each entry is either a plain URL string (folder
# name derived from the repo name) or an object { "url", "name" } when
# the desired local folder name differs from the repo name (e.g. GitHub
# repo "hunteradeck" checked out locally as "huntera-launcher"). Clones
# with --recurse-submodules so repos with submodules (e.g. myscripts's
# thero/athena/zeus) come fully populated in one shot.

function Set-ProjectsFolder {
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [string]$ProjectsDir = (Join-Path $HOME 'projects')
    )

    if (-not (Test-CommandExists 'git')) {
        throw "git nao encontrado no PATH (deveria ter vindo do winget). Rode de novo apos a etapa WingetApps terminar."
    }

    if (-not (Test-Path $ProjectsDir)) {
        New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null
        Write-Ok "Pasta criada: $ProjectsDir"
    }
    else {
        Write-Ok "Pasta ja existe: $ProjectsDir"
    }

    if (-not (Test-Path $ConfigPath)) {
        Write-Warn2 "config/projects.json nao encontrado, nada pra clonar"
        return
    }

    $repos = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    foreach ($entry in $repos) {
        if ($entry -is [string]) {
            $url = $entry
            $name = [System.IO.Path]::GetFileNameWithoutExtension(($url.TrimEnd('/')))
        }
        else {
            $url = $entry.url
            $name = $entry.name
        }
        $dest = Join-Path $ProjectsDir $name

        if (Test-Path $dest) {
            Write-Ok "$name ja clonado, pulando"
            continue
        }

        Write-Host "    Clonando $url -> $name ..." -ForegroundColor DarkCyan
        git clone --quiet --recurse-submodules $url $dest
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$name clonado em $dest"
        }
        else {
            Write-Warn2 "Falha ao clonar $url (codigo $LASTEXITCODE)"
        }
    }
}
