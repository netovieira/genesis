# Creates one daily scheduled task per folder in config/backup-folders.json,
# mirroring that folder into ~/Backups/<nome-da-pasta> with robocopy. No
# external destination is configured anywhere in the wizard, so this picks
# the simplest self-contained default (a dated local mirror) rather than
# inventing a cloud/remote destination nobody asked for - swap the
# -DestinationRoot below if you want it to go somewhere else (an external
# drive, a network share, etc.).

function Register-BackupTasks {
    param(
        [Parameter(Mandatory)][string]$FoldersPath,
        [string]$DestinationRoot = (Join-Path $HOME 'Backups')
    )

    if (-not (Test-Path $FoldersPath)) {
        Write-Warn2 "config/backup-folders.json nao encontrado, nada pra configurar"
        return
    }

    $folders = @(Get-Content -Raw -Path $FoldersPath | ConvertFrom-Json)
    if ($folders.Count -eq 0) {
        Write-Warn2 "Nenhuma pasta configurada pra backup automatico"
        return
    }

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            Write-Warn2 "Pasta nao encontrada, pulando: $folder"
            continue
        }

        $name = Split-Path -Leaf ($folder.TrimEnd('\', '/'))
        $dest = Join-Path $DestinationRoot $name
        $taskName = "Genesis-Backup-$name"

        $action = New-ScheduledTaskAction -Execute 'robocopy.exe' `
            -Argument "`"$folder`" `"$dest`" /MIR /R:2 /W:5 /NFL /NDL /NP"
        $trigger = New-ScheduledTaskTrigger -Daily -At 3am
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
            -Principal $principal -Settings $settings | Out-Null

        Write-Ok "Backup diario (3h) configurado: $folder -> $dest"
    }
}
