# Windows already auto-reconnects previously PAIRED Bluetooth devices
# when they come in range - there is no supported API to script pairing
# itself (it needs the PIN/confirmation dance on both sides at least once).
# What this does: make sure the Bluetooth support service is enabled and
# set to auto-start, so devices paired once always reconnect after a
# reboot instead of needing the tray icon clicked first.

function Set-BluetoothAutoReconnect {
    $svc = Get-Service -Name bthserv -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Warn2 "Servico bthserv nao encontrado (sem adaptador Bluetooth?)"
        return
    }
    if ($svc.StartType -ne 'Automatic') {
        Set-Service -Name bthserv -StartupType Automatic
    }
    if ($svc.Status -ne 'Running') {
        Start-Service -Name bthserv
    }
    Write-Ok "bthserv automatico e rodando (dispositivos pareados reconectam sozinhos)"
    Write-Warn2 "Pareamento inicial de cada dispositivo ainda precisa ser feito manualmente uma vez (Config > Bluetooth)"
}
