function Invoke-RaycastInstaller {
    param([Parameter(Mandatory)][string]$ExePath)

    if (-not (Test-Path $ExePath)) {
        throw "raycast-installer.exe nao encontrado em $ExePath"
    }
    Start-Process -FilePath $ExePath -Wait
    Write-Ok "Raycast instalado"
}
