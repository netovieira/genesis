# Enables the Windows features that WSL2 / Docker Desktop / Ubuntu (winget)
# need. This can require a reboot before those apps work - the function
# reports that back so the orchestrator can warn the user at the end.

function Enable-WSLFeatures {
    $features = @(
        'Microsoft-Windows-Subsystem-Linux',
        'VirtualMachinePlatform'
    )
    $rebootNeeded = $false
    foreach ($f in $features) {
        $state = Get-WindowsOptionalFeature -Online -FeatureName $f
        if ($state.State -ne 'Enabled') {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart
            if ($result.RestartNeeded) { $rebootNeeded = $true }
            Write-Ok "Feature habilitada: $f"
        }
        else {
            Write-Ok "Feature ja habilitada: $f"
        }
    }

    if (Test-CommandExists 'wsl') {
        try { wsl --update --web-download | Out-Null } catch { }
        try { wsl --set-default-version 2 | Out-Null } catch { }
    }

    if ($rebootNeeded) {
        Write-Warn2 "Reboot necessario para WSL2/Docker funcionarem. Reinicie antes de usar Ubuntu/Docker Desktop."
        $script:RebootRecommended = $true
    }
}
