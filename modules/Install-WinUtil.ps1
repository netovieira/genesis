# WinUtil (Chris Titus Tech) is not a winget package - it's meant to be
# run interactively (`irm https://christitus.com/win | iex`, or its own
# standalone .exe from GitHub releases). Since it opens its own GUI and
# expects the user to click through tweaks/installs themselves, it can't
# run unattended inside this pipeline. Instead, this just downloads the
# latest .exe straight to the Desktop so it's one double-click away
# whenever you want to use it - the tool itself is left alone.

function Install-WinUtilShortcut {
    param([string]$DestDir = (Join-Path $HOME 'Desktop'))

    $releaseApi = 'https://api.github.com/repos/ChrisTitusTech/winutil/releases/latest'
    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'genesis-script' }
    $asset = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1
    if (-not $asset) {
        throw "Nenhum .exe no release mais recente do WinUtil (github.com/ChrisTitusTech/winutil/releases)"
    }

    $dest = Join-Path $DestDir 'WinUtil.exe'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -Headers @{ 'User-Agent' = 'genesis-script' }
    Write-Ok "WinUtil.exe salvo em $dest - abra quando quiser mexer em tweaks/programas (ele tem interface propria)"
}
