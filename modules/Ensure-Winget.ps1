# winget vem do pacote "App Installer" (Microsoft.DesktopAppInstaller),
# normalmente pre-provisionado no Windows 11 - mas em imagens offline,
# LTSC, ISO customizada, ou quando a primeira conta local nunca sincronizou
# com a Store, ele pode simplesmente nao existir ainda. Isso instala o
# App Installer e as duas dependencias dele (VCLibs, UI.Xaml) direto dos
# releases oficiais no GitHub, sem precisar abrir a Store.

function Install-WingetIfMissing {
    if (Test-CommandExists 'winget') {
        return
    }
    Write-Warn2 "winget nao encontrado (comum logo apos formatar) - instalando App Installer manualmente"

    $tmp = Join-Path $env:TEMP 'winget-bootstrap'
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $headers = @{ 'User-Agent' = 'genesis-script' }

    $vcLibs = Join-Path $tmp 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
    Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile $vcLibs
    try { Add-AppxPackage -Path $vcLibs -ErrorAction Stop } catch { Write-Warn2 "VCLibs: $($_.Exception.Message)" }

    try {
        $xamlRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/microsoft-ui-xaml/releases/latest' -Headers $headers
        $xamlAsset = $xamlRelease.assets | Where-Object { $_.name -like '*x64.appx' } | Select-Object -First 1
        if ($xamlAsset) {
            $xamlFile = Join-Path $tmp $xamlAsset.name
            Invoke-WebRequest -Uri $xamlAsset.browser_download_url -OutFile $xamlFile
            Add-AppxPackage -Path $xamlFile -ErrorAction Stop
        }
    }
    catch { Write-Warn2 "UI.Xaml: $($_.Exception.Message)" }

    $wingetRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -Headers $headers
    $wingetAsset = $wingetRelease.assets | Where-Object { $_.name -like '*.msixbundle' } | Select-Object -First 1
    if (-not $wingetAsset) {
        throw "Nao achei o .msixbundle do winget no release mais recente (github.com/microsoft/winget-cli/releases)"
    }
    $wingetFile = Join-Path $tmp $wingetAsset.name
    Invoke-WebRequest -Uri $wingetAsset.browser_download_url -OutFile $wingetFile
    Add-AppxPackage -Path $wingetFile

    if (Test-CommandExists 'winget') {
        Write-Ok "winget instalado"
    }
    else {
        Write-Warn2 "winget instalado mas ainda nao aparece nesta sessao - se as etapas seguintes falharem, abra um terminal novo e rode de novo"
    }
}
