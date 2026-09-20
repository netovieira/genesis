<#
    Bootstrap do Genesis.exe de arquivo unico.

    Este arquivo e concatenado DEPOIS de .build/payload.ps1 pelo build.ps1:
    o payload define $Global:GenesisPayloadBase64 / ...Version e este script
    transforma isso em arquivos em disco, devolvendo a pasta que o
    gui/WizardHost.ps1 usa como $Root (modules/, config/, gui/, python/...).

    Rodando direto da pasta do projeto (sem compilar), o payload nao existe:
    Expand-GenesisPayload devolve $ExeDir e nada muda.

    Em runtime:
      1. descompacta o payload em %LOCALAPPDATA%\Genesis\app\<versao> - so
         na primeira vez de cada versao, depois reaproveita o cache (abrir o
         exe de novo e instantaneo);
      2. copia por cima o que o usuario tenha do lado do .exe
         (config\*.json, presetup.json, raycast-installer.exe) - assim
         continua dando pra ajustar config/overrides sem recompilar;
      3. devolve essa pasta como $Root.
#>

function Expand-GenesisPayload {
    param(
        [Parameter(Mandatory)][string]$ExeDir,
        [string]$PayloadBase64 = $Global:GenesisPayloadBase64,
        [string]$PayloadVersion = $Global:GenesisPayloadVersion
    )

    if (-not $PayloadBase64) { return $ExeDir }
    if (-not $PayloadVersion) { $PayloadVersion = 'dev' }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $cacheRoot = Join-Path $env:LOCALAPPDATA 'Genesis\app'
    $target = Join-Path $cacheRoot $PayloadVersion

    # Pipeline.ps1 como sentinela: se ele nao esta la, a extracao nao terminou
    # (ou a pasta foi limpa) e o payload precisa ser descompactado de novo.
    if (-not (Test-Path (Join-Path $target 'modules\Pipeline.ps1'))) {
        New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null

        $gzipBytes = [Convert]::FromBase64String($PayloadBase64)
        $input = New-Object System.IO.MemoryStream
        $input.Write($gzipBytes, 0, $gzipBytes.Length)
        $input.Position = 0
        $gzip = New-Object System.IO.Compression.GZipStream($input, [System.IO.Compression.CompressionMode]::Decompress)
        $zipStream = New-Object System.IO.MemoryStream
        $gzip.CopyTo($zipStream)
        $gzip.Dispose()
        $input.Dispose()

        # extrai pra uma pasta temporaria e so depois promove (nada de cache
        # pela metade se algo falhar no meio)
        $staging = "$target.tmp"
        if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
        New-Item -ItemType Directory -Path $staging -Force | Out-Null

        $tmpZip = Join-Path $cacheRoot 'payload.zip'
        [System.IO.File]::WriteAllBytes($tmpZip, $zipStream.ToArray())
        $zipStream.Dispose()
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $staging)
        }
        finally {
            Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        }

        # Aproveita os logs da versao anterior - recompilar o exe muda a pasta
        # de cache, e perder o historico de execucoes seria chato.
        $previous = Get-ChildItem $cacheRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne $PayloadVersion -and $_.Name -notlike '*.tmp' } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($previous) {
            $previousLogs = Join-Path $previous.FullName 'logs'
            if (Test-Path $previousLogs) {
                Copy-Item $previousLogs (Join-Path $staging 'logs') -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # limpa versoes antigas antes de promover a atual
        Get-ChildItem $cacheRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne $PayloadVersion -and $_.Name -notlike '*.tmp' } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $target) { Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue }
        Move-Item -Path $staging -Destination $target -Force
    }

    # Overlay: o que o usuario deixou do lado do .exe ganha dos defaults
    # embutidos (permite editar config sem recompilar o exe).
    foreach ($name in 'presetup.json', 'raycast-installer.exe') {
        $external = Join-Path $ExeDir $name
        if (Test-Path $external) { Copy-Item $external (Join-Path $target $name) -Force }
    }
    $externalConfig = Join-Path $ExeDir 'config'
    if (Test-Path $externalConfig) {
        Get-ChildItem -Path $externalConfig -File -Filter '*.json' |
            ForEach-Object { Copy-Item $_.FullName (Join-Path $target 'config') -Force }
    }

    return $target
}
