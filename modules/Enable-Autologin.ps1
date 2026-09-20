# Uses Sysinternals Autologon (official Microsoft-hosted "live" build, so
# it's always the current version - no version-pinned URL to go stale).
# The password is only kept in memory for this call and is never written
# to disk by this script; Autologon.exe itself stores it as an LSA secret
# (the same mechanism Windows uses internally), not plaintext in the
# registry.
#
# This step is OFF by default in config/tasks.json because it stores a
# logon credential on the machine - opt in deliberately.

function Enable-WindowsAutologin {
    $exeDir = Join-Path $env:TEMP 'Autologon'
    $exe = Join-Path $exeDir 'Autologon64.exe'
    if (-not (Test-Path $exe)) {
        New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
        Invoke-WebRequest -Uri 'https://live.sysinternals.com/Autologon64.exe' -OutFile $exe
    }

    $cred = Get-Credential -Message "Usuario e senha para autologin (deixe em branco pra pular)" -UserName "$env:USERDOMAIN\$env:USERNAME"
    if (-not $cred) {
        Write-Warn2 "Autologin pulado (nenhuma credencial informada)"
        return
    }

    $plain = $cred.GetNetworkCredential().Password
    if ([string]::IsNullOrEmpty($plain)) {
        Write-Warn2 "Autologin pulado (senha vazia)"
        return
    }

    & $exe $cred.GetNetworkCredential().UserName $env:USERDOMAIN $plain /accepteula
    Write-Ok "Autologin configurado para $($cred.UserName)"
}
