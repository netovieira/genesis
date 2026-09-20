# Registers a weekly scheduled task that runs "winget upgrade --all" so
# apps stay current without re-running the whole setup.

function Register-WingetUpgradeTask {
    $taskName = 'Genesis-WingetUpgrade'
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Ok "Tarefa agendada '$taskName' ja existe"
        return
    }

    $action = New-ScheduledTaskAction -Execute 'winget.exe' `
        -Argument 'upgrade --all --silent --accept-source-agreements --accept-package-agreements'
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings | Out-Null
    Write-Ok "Tarefa agendada criada: winget upgrade --all toda segunda as 9h"
}
