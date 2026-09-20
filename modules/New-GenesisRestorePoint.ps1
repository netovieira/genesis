# Creates a System Restore point before anything else runs, so the whole
# run (execution policy, registry, Windows features, BitLocker if enabled)
# can be rolled back from Windows' own "Restaurar sistema" if something
# goes wrong. Windows only allows one checkpoint per 24h by default, which
# is a non-issue on a just-formatted machine (no prior checkpoints exist).

function New-GenesisRestorePoint {
    $drive = "$env:SystemDrive\"
    try {
        Enable-ComputerRestore -Drive $drive
    }
    catch {
        Write-Warn2 "Nao foi possivel habilitar Protecao do Sistema em $drive : $($_.Exception.Message)"
    }

    try {
        Checkpoint-Computer -Description 'Genesis: antes do setup pos-formatacao' -RestorePointType MODIFY_SETTINGS
        Write-Ok "Ponto de restauracao criado"
    }
    catch {
        Write-Warn2 "Nao criou ponto de restauracao agora (provavelmente ja existe um das ultimas 24h): $($_.Exception.Message)"
    }
}
