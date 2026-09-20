# Installs apps from config/winget-apps.json via winget. Each catalog
# entry is { id, label, category, default, source? } - "source" is only
# present for Microsoft Store packages (e.g. Netflix), which need
# --source msstore instead of the default community winget source.
#
# -SelectedIds (passed by the wizard) installs exactly those ids,
# regardless of each entry's "default". Without it (plain console run
# via genesis.ps1), every entry with "default": true installs - the
# catalog IS the config in that mode.
#
# Skips ids already installed. Microsoft.Office and Canonical.Ubuntu.2204
# may open their own installer UI - that's expected, not a failure.

function Install-WingetApps {
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [string[]]$SelectedIds
    )

    if (-not (Test-CommandExists 'winget')) {
        Install-WingetIfMissing
    }
    if (-not (Test-CommandExists 'winget')) {
        throw "winget ainda nao encontrado apos tentar instalar automaticamente. Abra a Microsoft Store, atualize o 'App Installer' e rode de novo."
    }

    $catalog = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    $apps = if ($SelectedIds) {
        $catalog | Where-Object { $_.id -in $SelectedIds }
    }
    else {
        $catalog | Where-Object { $_.default }
    }

    foreach ($app in $apps) {
        $id = $app.id
        $source = if ($app.source) { $app.source } else { 'winget' }
        $sourceArgs = @('--source', $source)
        Write-AppStatus -Id $id -Status 'Running'

        $already = winget list --id $id --exact --accept-source-agreements @sourceArgs 2>$null |
            Select-String -SimpleMatch $id
        if ($already) {
            Write-Ok "$($app.label) ($id) ja instalado"
            Write-AppStatus -Id $id -Status 'Ok'
            continue
        }

        Write-Host "    Instalando $($app.label) ($id) ..." -ForegroundColor DarkCyan
        winget install -e --id $id --accept-source-agreements --accept-package-agreements --silent @sourceArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$($app.label) instalado"
            Write-AppStatus -Id $id -Status 'Ok'
        }
        else {
            Write-Warn2 "$($app.label) ($id) retornou codigo $LASTEXITCODE (pode precisar instalar manualmente)"
            Write-AppStatus -Id $id -Status 'Fail'
        }
    }
}
