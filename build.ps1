#Requires -Version 5.1
<#
    Compila o Genesis.exe a partir do codigo-fonte, usando o modulo ps2exe.

    O resultado e UM ARQUIVO SO: modules/, config/, gui/wizard/,
    gui/webview2/, python/ e o raycast-installer.exe entram embutidos num
    payload comprimido (gerado por scripts/build-payload.ps1) e sao
    extraidos em %LOCALAPPDATA%\Genesis\app\<versao> na primeira execucao -
    quem faz isso e o gui/GenesisBootstrap.ps1. Ou seja: da pra copiar o
    Genesis.exe sozinho, pra qualquer pasta, sem levar nada junto.

    O exe sai em dist/ (isolado, longe das fontes) para provar que ele roda
    sem nenhum arquivo extra por perto.

    Passos daqui:
      1. gera .build/payload.ps1 (todos os assets: zip -> gzip -> base64)
      2. monta .build/Genesis.ps1 = bootstrap + wizard host (+ payload so
         como dados, via leitura em runtime - NUNCA concatenado inline,
         porque o param() da parte 3 seria invalido fora do topo e o
         parser do ps2exe reclamaria "O termo 'param' nao e reconhecido")
      3. compila esse script unico em dist/Genesis.exe

    Rodar direto da pasta do projeto continua valendo, sem compilar nada:
    .\genesis.ps1 (console) e .\gui\WizardHost.ps1 (janela).
#>

$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
# O exe sai em dist/, isolado e longe das fontes: assim fica provado que ele
# roda sem nenhum arquivo extra por perto (o bug "O termo 'param' nao e
# reconhecido" veio justamente de um teste rodando o exe do lado das fontes).
$OutDir = Join-Path $Root 'dist'
$OutExe = Join-Path $OutDir 'Genesis.exe'
# Artefatos intermediarios do build (payload + script unico) - gitignored.
$BuildDir = Join-Path $Root '.build'

if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando provedor NuGet (necessario pro PowerShellGet baixar modulos)..." -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
}

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Instalando modulo ps2exe..." -ForegroundColor Cyan
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe

$iconFile = Join-Path $Root 'gui\Genesis.ico'
if (-not (Test-Path $iconFile)) {
    Write-Host "Icone nao encontrado, gerando de genesis-icon-app-512x512.png..." -ForegroundColor Cyan
    & (Join-Path $Root 'scripts\make-exe-icon.ps1')
}

# 1) payload embutido --------------------------------------------------------
Write-Host "`n[1/3] Gerando o payload embutido..." -ForegroundColor Cyan
& (Join-Path $Root 'scripts\build-payload.ps1')

# 2) script unico = bootstrap + wizard host ----------------------------------
# O payload.ps1 NAO e concatenado como codigo: ele e lido aqui como TEXTO,
# convertido pra base64 (linha unica, sem aspas) e avaliado em runtime via
# [ScriptBlock]::Create, DEPOIS que as funcoes ja existem. Dois motivos:
#   a) o WizardHost.ps1 tem um bloco param() que so e valido no topo do
#      script - concatenado atras do payload, ele virava o "O termo 'param'
#      nao e reconhecido" e matava o exe na abertura;
#   b) o payload.ps1 contem a linha terminadora '@ (do proprio here-string
#      dele) - embuti-lo dentro de outro here-string quebraria o parse.
# (Os param() DENTRO de scriptblocks - AddScript, WebMessageReceived - sao
# legais onde estao e entram intocados.)
Write-Host "[2/3] Montando o script unico do exe..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$singleScript = Join-Path $BuildDir 'Genesis.ps1'
$payloadFile = Join-Path $BuildDir 'payload.ps1'
if (-not (Test-Path $payloadFile)) { throw "Payload nao encontrado: $payloadFile (rode scripts/build-payload.ps1)" }
$bootstrapFile = Join-Path $Root 'gui\GenesisBootstrap.ps1'
$hostFile = Join-Path $Root 'gui\WizardHost.ps1'
foreach ($part in @($bootstrapFile, $hostFile)) {
    if (-not (Test-Path $part)) { throw "Parte do script unico nao encontrada: $part" }
}
# ReadAllText(UTF8) ja descarta o BOM: o texto avaliado em runtime comeca
# limpo, e cada parte entra sem BOM no arquivo final (só ele leva BOM).
$payloadSource = [System.IO.File]::ReadAllText($payloadFile, [System.Text.Encoding]::UTF8)
$payloadB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadSource))
$single = New-Object System.Text.StringBuilder
[void]$single.AppendLine('# Gerado pelo build.ps1 - NAO edite. O payload vai EMBUTIDO abaixo em')
[void]$single.AppendLine('# base64 e e avaliado em runtime, NAO como codigo (ver comentario no build).')
[void]$single.AppendLine('$__GenesisPayloadB64 = ''')
[void]$single.AppendLine($payloadB64)
[void]$single.AppendLine('''')
[void]$single.AppendLine('$__GenesisPayloadSource = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($__GenesisPayloadB64))')
[void]$single.AppendLine('. ([ScriptBlock]::Create($__GenesisPayloadSource))')
[void]$single.AppendLine('Remove-Variable -Name __GenesisPayloadB64, __GenesisPayloadSource -Scope Script -ErrorAction SilentlyContinue')
[void]$single.AppendLine([System.IO.File]::ReadAllText($bootstrapFile, [System.Text.Encoding]::UTF8))
# Do host entra tudo, menos o bloco param() do topo (so e valido como
# primeiro comando do script - concatenado atras do bootstrap virava o
# 'O termo param nao e reconhecido' que matava o exe na abertura). Ele vira
# uma leitura de $args, que o ps2exe repassa do exe pro script: sem admin,
# relanca com -SkipElevationCheck, e o filho elevado pula a checagem.
$hostText = [System.IO.File]::ReadAllText($hostFile, [System.Text.Encoding]::UTF8)
$skipReplacement = '$SkipElevationCheck = [bool]$args.Count'
$hostBody = $hostText -replace '(?m)^param\(\[switch\]\$SkipElevationCheck\)\s*\r?$', $skipReplacement
[void]$single.AppendLine($hostBody)
[System.IO.File]::WriteAllText($singleScript, $single.ToString(), (New-Object System.Text.UTF8Encoding($true)))

# 3) compila -----------------------------------------------------------------
Write-Host "[3/3] Compilando com ps2exe (pode demorar um pouco)..." -ForegroundColor Cyan
# ps2exe substitui o exe de saida. Apagar um .exe recem-gerado as vezes e
# negado pelo Windows (handle de antivirus/indexer) MESMO sem ninguem usando:
# por isso o delete aqui e via [System.IO.File]::Delete, que nesses casos passa.
if (Test-Path $OutExe) {
    try { [System.IO.File]::Delete((Resolve-Path $OutExe)) }
    catch {
        Write-Warning "Nao deu pra apagar o Genesis.exe atual ($($_.Exception.Message)). Feche o exe se estiver aberto e rode o build de novo."
    }
}
Invoke-ps2exe `
    -inputFile $singleScript `
    -outputFile $OutExe `
    -iconFile $iconFile `
    -title 'Genesis' `
    -description 'Genesis - setup pos-formatacao do Windows 11' `
    -company 'Anthero' `
    -product 'Genesis - setup pos-formatacao' `
    -version '1.0.0.0' `
    -noConsole `
    -requireAdmin `
    -x64

if (-not (Test-Path $OutExe)) {
    throw "ps2exe rodou mas $OutExe nao foi criado - veja a saida acima pro erro real."
}

$size = [math]::Round((Get-Item $OutExe).Length / 1MB, 1)
Write-Host "`nGerado: $OutExe ($size MB)" -ForegroundColor Green
Write-Host "Arquivo unico em dist/: pode copiar o .exe sozinho pra qualquer pasta. Ele extrai o proprio payload em %LOCALAPPDATA%\Genesis\app\<versao> na primeira execucao." -ForegroundColor Yellow
Write-Host "Opcional: se houver config\*.json, presetup.json ou raycast-installer.exe do lado do .exe, eles ganham dos defaults embutidos." -ForegroundColor DarkGray
