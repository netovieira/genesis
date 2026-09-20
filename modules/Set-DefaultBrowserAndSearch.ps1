# Windows blocks scripted changes to the default-browser association
# (Set-Association was patched out years ago). The reliable community
# workaround is SetUserFTA by Christoph Kolbicz, which writes the same
# per-user "UserChoice" hash Windows itself writes when you click through
# Settings - this is what actually makes it stick.
#
# Forcing Windows Search web results to open in Chrome instead of Edge is
# an OS-level restriction Microsoft actively re-patches; there is no
# reliable scripted fix as of this writing. That part is left as a manual
# note instead of a fragile hack that breaks on the next Windows update.

function Set-DefaultBrowserAndSearch {
    param(
        [string]$SetUserFtaDir = (Join-Path $env:TEMP 'SetUserFTA')
    )

    if (-not (Test-CommandExists 'choco') -and -not (Test-Path (Join-Path $SetUserFtaDir 'SetUserFTA.exe'))) {
        New-Item -ItemType Directory -Path $SetUserFtaDir -Force | Out-Null
        $zip = Join-Path $SetUserFtaDir 'SetUserFTA.zip'
        Invoke-WebRequest -Uri 'https://kolbi.cz/SetUserFTA.zip' -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $SetUserFtaDir -Force
    }

    $exe = Get-ChildItem -Path $SetUserFtaDir -Filter 'SetUserFTA.exe' -Recurse | Select-Object -First 1
    if (-not $exe) {
        throw "SetUserFTA.exe nao encontrado apos download"
    }

    $assocs = @('http', 'https', '.htm', '.html')
    foreach ($a in $assocs) {
        & $exe.FullName $a 'ChromeHTML'
    }
    Write-Ok "Chrome definido como navegador padrao (http/https/.htm/.html)"

    # Force Chrome's own default search engine to Google via policy, in case
    # it was changed - this part IS reliably scriptable.
    $policyPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
    if (-not (Test-Path $policyPath)) {
        New-Item -Path $policyPath -Force | Out-Null
    }
    New-ItemProperty -Path $policyPath -Name 'DefaultSearchProviderEnabled' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $policyPath -Name 'DefaultSearchProviderSearchURL' -Value 'https://www.google.com/search?q={searchTerms}' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $policyPath -Name 'DefaultSearchProviderName' -Value 'Google' -PropertyType String -Force | Out-Null
    Write-Ok "Google forcado como buscador padrao do Chrome"

    Write-Warn2 "Windows Search (barra de tarefas) abrir resultados no Chrome: sem forma confiavel via script, a Microsoft repatcha os hacks a cada update. Manual: nao ha correcao permanente conhecida hoje."
}
