#Requires -Version 5.1
<#
    One-off dev tool: downloads each app's real favicon (via Google's
    public favicon service, keyed off the "homepage" field
    fetch-app-metadata.ps1 just wrote) into gui/wizard/assets/icons/, so
    the wizard shows the app's own real brand mark instead of a made-up
    generic icon. Re-run whenever the catalog changes. Not part of the
    shipped install pipeline - these files ARE shipped (committed), this
    script just produces them.
#>

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $Root 'config\winget-apps.json'
$iconsDir = Join-Path $Root 'gui\wizard\assets\icons'
New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null

$apps = Get-Content -Raw -Path $path | ConvertFrom-Json

foreach ($app in $apps) {
    if (-not $app.homepage) { continue }
    $safeName = ($app.id -replace '[^A-Za-z0-9._-]', '_')
    $dest = Join-Path $iconsDir "$safeName.png"
    if (Test-Path $dest) { continue }

    try {
        $domain = ([Uri]$app.homepage).Host
        $url = "https://www.google.com/s2/favicons?domain=$domain&sz=128"
        Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 15
        Write-Host "OK $($app.id) <- $domain" -ForegroundColor Green
    }
    catch {
        Write-Host "FALHOU $($app.id): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host "`nIcones em: $iconsDir" -ForegroundColor Cyan
