# Windows Search / Widgets / News force-open links in Edge no matter your
# default browser - Microsoft treats that as protected Edge behavior and
# patches most registry-only workarounds within a release or two.
#
# MSEdgeRedirect (github.com/rcmaehl/MSEdgeRedirect) is a maintained,
# open-source, purpose-built tool for exactly this: it installs itself as
# the handler for those launches and forwards them to your real default
# browser.

function Install-SearchRedirect {
    $releaseApi = 'https://api.github.com/repos/rcmaehl/MSEdgeRedirect/releases/latest'
    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'genesis-script' }
    $asset = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1
    if (-not $asset) {
        throw "Nenhum instalador .exe no release mais recente do MSEdgeRedirect"
    }

    $dest = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -Headers @{ 'User-Agent' = 'genesis-script' }

    Start-Process -FilePath $dest -ArgumentList '/silentinstall' -Wait
    Write-Ok "MSEdgeRedirect instalado - Search/Widgets/News agora abrem no navegador padrao"
}
