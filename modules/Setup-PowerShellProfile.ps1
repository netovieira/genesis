# Copies the tracked profile into $PROFILE (works for both Windows
# PowerShell 5.1 and PowerShell 7 - both are handled since $PROFILE
# resolves per-host).  Starship (the only external dependency the
# profile expects) is installed separately via winget.

function Set-UserProfileScript {
    param(
        [Parameter(Mandatory)][string]$SourceProfile,
        # Base do `goto`/`g` (funcao goto no profile): por padrao o profile
        # usa "$project_path = $HOME", que so funciona se os projetos do
        # usuario morarem debaixo do home. Quando informado (pasta de
        # projetos escolhida na Revisao), o valor dinamico $HOME e trocado
        # por esse caminho literal na copia final - o arquivo de origem
        # (tracked no repo) fica intocado.
        [string]$ProjectsPath
    )

    if (-not (Test-Path $SourceProfile)) {
        throw "Profile de origem nao encontrado: $SourceProfile"
    }

    $content = Get-Content -Raw -Path $SourceProfile
    if ($ProjectsPath) {
        $escaped = $ProjectsPath -replace "'", "''"
        $patched = $content -replace '(?m)^\s*\$project_path\s*=\s*\$HOME\s*$', "    `$project_path = '$escaped'"
        if ($patched -eq $content) {
            Write-Warn2 "Nao achei a linha '`$project_path = `$HOME' no profile pra trocar pela pasta de projetos - copiando sem alterar"
        }
        $content = $patched
    }

    $targets = @($PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
    foreach ($target in $targets) {
        $dir = Split-Path -Parent $target
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Set-Content -Path $target -Value $content -Encoding utf8 -Force
        Write-Ok "Profile copiado para $target"
    }

    if (-not (Test-CommandExists 'starship')) {
        Write-Warn2 "starship nao encontrado no PATH ainda (winget pode precisar de um novo terminal)"
    }
}
