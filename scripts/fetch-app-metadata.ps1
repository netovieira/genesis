#Requires -Version 5.1
<#
    One-off dev tool: queries `winget show` for every app in
    config/winget-apps.json and writes the real Version/ReleaseDate/
    Description/Homepage back into that same file, so the wizard can show
    real data instead of placeholders. Re-run whenever the catalog
    changes. Not part of the shipped install pipeline.
#>

$ErrorActionPreference = 'Continue'
# A freshly-spawned powershell.exe -File process doesn't inherit this
# session's UTF-8 console codepage, so winget's accented output
# ("Versão", "Lançamento") arrives mangled and the regexes below never
# match. Force UTF-8 on both directions before calling winget.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

$Root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $Root 'config\winget-apps.json'
$apps = Get-Content -Raw -Path $path | ConvertFrom-Json

foreach ($app in $apps) {
    $sourceArgs = if ($app.source) { @('--source', $app.source) } else { @('--source', 'winget') }
    Write-Host "-> $($app.id)" -ForegroundColor Cyan
    $out = winget show --id $app.id --exact --accept-source-agreements @sourceArgs 2>&1 | Out-String

    # "." stands in for accented letters (a/c-cedilla) below - a .ps1 saved
    # without a BOM gets its own source misread as the system ANSI codepage
    # by Windows PowerShell 5.1, so a literal "ã"/"ç" typed into the regex
    # itself becomes the wrong byte before it ever reaches the engine. The
    # captured $out is fine (it's real UTF-8) - only the pattern isn't.
    $version = [regex]::Match($out, 'Vers.o:\s*(.+)').Groups[1].Value.Trim()
    $release = [regex]::Match($out, 'Data do Lan.amento:\s*(.+)').Groups[1].Value.Trim()
    $vendorUrl = [regex]::Match($out, 'URL do Fornecedor:\s*(.+)').Groups[1].Value.Trim()
    $homepage = [regex]::Match($out, 'P.gina inicial:\s*(.+)').Groups[1].Value.Trim()
    # Description is deliberately NOT captured here: winget's own text is
    # a mix of English marketing copy and inconsistent length per vendor,
    # wrong for a PT-BR wizard - those are hand-written in
    # gui/wizard/app.js's APP_DESCRIPTIONS instead. Only the objectively
    # real, unopinionated fields (version, release date, homepage for the
    # favicon fetch) come from winget.
    Add-Member -InputObject $app -NotePropertyName 'version' -NotePropertyValue $version -Force
    Add-Member -InputObject $app -NotePropertyName 'updated' -NotePropertyValue $release -Force
    Add-Member -InputObject $app -NotePropertyName 'homepage' -NotePropertyValue (@($vendorUrl, $homepage) | Where-Object { $_ } | Select-Object -First 1) -Force

    if (-not $version) { Write-Host "   (sem dados - checar manualmente)" -ForegroundColor Yellow }
}

$json = $apps | ConvertTo-Json -Depth 6
# Windows PowerShell 5.1's `-Encoding utf8` always adds a BOM; write
# without one so the file stays a plain, portable UTF-8 JSON file.
[System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "`nAtualizado: $path" -ForegroundColor Green
