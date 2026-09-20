#Requires -Version 5.1
<#
    Genesis - orquestrador do setup de PC Windows pos-formatacao
    (versao console). A mesma logica (modules/Pipeline.ps1) roda por baixo
    da GUI (gui/WizardHost.ps1) - use este arquivo pra rodar sem GUI, ou
    pra debugar.
#>

param(
    [switch]$SkipElevationCheck
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$script:RebootRecommended = $false

. (Join-Path $Root 'modules\Common.ps1')

if (-not $SkipElevationCheck -and -not (Test-IsAdmin)) {
    Write-Host "Reabrindo como administrador..." -ForegroundColor Yellow
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$($MyInvocation.MyCommand.Path)`"", '-SkipElevationCheck')
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
    exit
}

$logDir = Join-Path $Root 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$script:LogFile = Join-Path $logDir "genesis-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $script:LogFile -Append | Out-Null

Get-ChildItem -Path (Join-Path $Root 'modules') -Filter '*.ps1' | Where-Object {
    $_.Name -ne 'Common.ps1'
} | ForEach-Object { . $_.FullName }

$tasks = Get-Content -Raw -Path (Join-Path $Root 'config\tasks.json') | ConvertFrom-Json

Write-Host "=========================================" -ForegroundColor Magenta
Write-Host " Genesis - setup pos-formatacao - $(Get-Date)" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta

$run = Invoke-GenesisPipeline -Root $Root -Tasks $tasks

Write-Host "`n=========================================" -ForegroundColor Magenta
Write-Host " Resumo" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta
foreach ($k in $run.Results.Keys) {
    $mark = if ($run.Results[$k]) { 'OK' } else { 'FALHOU' }
    $color = if ($run.Results[$k]) { 'Green' } else { 'Red' }
    Write-Host ("  {0,-24} {1}" -f $k, $mark) -ForegroundColor $color
}
if ($run.RebootRecommended) {
    Write-Host "`nReinicie o PC antes de usar WSL/Docker/Ubuntu." -ForegroundColor Yellow
}
Write-Host "`nLog completo em: $script:LogFile" -ForegroundColor DarkGray

Stop-Transcript | Out-Null
