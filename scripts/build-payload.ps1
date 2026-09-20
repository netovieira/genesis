#Requires -Version 5.1
<#
    Gera .build/payload.ps1 - o pacote embutido do Genesis.exe.

    O Genesis.exe compilado e um arquivo UNICO: ele nao precisa de modules/,
    config/ nem gui/ do lado dele. Este script junta tudo o que o
    pipeline e a interface precisam em tempo de execucao num zip, comprime
    (gzip) e grava como base64 num here-string do PowerShell. O build.ps1
    concatena esse arquivo + gui/GenesisBootstrap.ps1 + gui/WizardHost.ps1
    pra compilar o exe (ver gui/GenesisBootstrap.ps1 pra extracao em runtime).

    Ficam FORA do payload (gerado em runtime ou coisa de desenvolvimento):
      - logs/, .build/, Genesis.exe, README/PRODUCT/DESIGN/docs/scripts
#>

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $Root '.build'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# Pastas inteiras embutidas (caminhos relativos a raiz do projeto).
$includeDirs = @(
    'modules'
    'config'
    'gui\wizard'
    'gui\webview2'
)

# Arquivos soltos que o pipeline usa direto na raiz de $Root.
$includeFiles = @(
    'Microsoft.PowerShell_profile.ps1'
    'Microsoft.Services.Store.winmd'
    'raycast-installer.exe'
    # gui/Genesis.ico: o WizardHost.ps1 carrega como $form.Icon na abertura
    # (e o que a barra de tarefas mostra - o -iconFile do ps2exe so marca o
    # arquivo .exe no Explorer).
    'gui\Genesis.ico'
)

# Nunca entram: venv e bytecode do python.
$exclude = '\\.venv\\|__pycache__|\.pyc$'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$tmpZip = Join-Path $OutDir 'payload.zip'
if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }

$count = 0
$archive = [System.IO.Compression.ZipFile]::Open($tmpZip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $add = {
        param([string]$FullPath)
        # dentro do zip o caminho e sempre relativo a raiz, com barras "/"
        $entry = $FullPath.Substring($Root.Length + 1) -replace '\\', '/'
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $FullPath, $entry, [System.IO.Compression.CompressionLevel]::Optimal)
        $script:count++
    }

    foreach ($rel in $includeDirs) {
        $dir = Join-Path $Root $rel
        if (-not (Test-Path $dir)) { throw "Pasta obrigatoria nao encontrada: $rel" }
        Get-ChildItem -Path $dir -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch $exclude } |
            ForEach-Object { & $add $_.FullName }
    }

    foreach ($rel in $includeFiles) {
        $file = Join-Path $Root $rel
        if (Test-Path $file) { & $add $file }
        else { Write-Warning "Arquivo opcional ausente, ficando fora do payload: $rel" }
    }
}
finally { $archive.Dispose() }

# zip -> gzip -> base64 (o exe carrega isso como texto puro)
$zipBytes = [System.IO.File]::ReadAllBytes($tmpZip)
$gzipStream = New-Object System.IO.MemoryStream
$gzip = New-Object System.IO.Compression.GZipStream($gzipStream, [System.IO.Compression.CompressionMode]::Compress, $true)
$gzip.Write($zipBytes, 0, $zipBytes.Length)
$gzip.Dispose()
$base64 = [Convert]::ToBase64String($gzipStream.ToArray())
$gzipStream.Dispose()

# A versao e o hash do proprio payload: muda o conteudo, muda a pasta de
# cache em runtime (%LOCALAPPDATA%\Genesis\app\<versao>).
$sha = [System.Security.Cryptography.SHA256]::Create()
$digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($base64))
$version = (($digest | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 16)

$payloadFile = Join-Path $OutDir 'payload.ps1'
$text = @"
# Gerado por scripts/build-payload.ps1 - NAO versionado, NAO edite a mao.
# $count arquivos embutidos (zip + base64), versao $version.
`$Global:GenesisPayloadVersion = '$version'
`$Global:GenesisPayloadBase64 = @'
$base64
'@
"@
[System.IO.File]::WriteAllText($payloadFile, $text, (New-Object System.Text.UTF8Encoding($true)))
Remove-Item $tmpZip -Force

$kb = [math]::Round((Get-Item $payloadFile).Length / 1KB)
Write-Host "Payload: $count arquivos, $kb KB em base64 -> $payloadFile (versao $version)" -ForegroundColor Green
