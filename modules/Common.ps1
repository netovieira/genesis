# Shared helpers for all Genesis modules. Dot-sourced by genesis.ps1 and the
# wizard host (gui/WizardHost.ps1).
#
# Reporting goes through optional hooks so the exact same module code runs
# unchanged whether it's driven by the console (genesis.ps1) or the wizard:
#   $Global:GenesisLogSink  - scriptblock(string $Message)                 free-text log lines
#   $Global:GenesisStepSink - scriptblock(string $Key, string $Status)     per pipeline-step status
#   $Global:GenesisAppSink  - scriptblock(string $Id, string $Status)      per winget-app status (drives the wizard's app-card grid)
# When none are set (plain console run) everything falls back to
# Write-Host, so genesis.ps1 behaves exactly as before.

function Write-Log2 {
    param([string]$Message, [string]$Color = 'Gray')
    if ($Global:GenesisLogSink) {
        & $Global:GenesisLogSink $Message
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Step {
    param([string]$Message)
    Write-Log2 "`n==> $Message" -Color 'Cyan'
}

function Write-Ok {
    param([string]$Message)
    Write-Log2 "    OK: $Message" -Color 'Green'
}

function Write-Warn2 {
    param([string]$Message)
    Write-Log2 "    WARN: $Message" -Color 'Yellow'
}

function Write-Err2 {
    param([string]$Message)
    Write-Log2 "    ERROR: $Message" -Color 'Red'
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Step {
    <#
        Runs $Action under a named step. Logs success/failure and never
        throws out of the orchestrator - one failing step must not stop
        the rest of the run. Reports 'Running'/'Ok'/'Fail' via
        $Global:GenesisStepSink (keyed by -Key, defaults to -Name) for the
        GUI's per-step status list.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action,
        [string]$Key = $Name
    )
    if ($Global:GenesisStepSink) { & $Global:GenesisStepSink $Key 'Running' }
    Write-Step $Name
    try {
        & $Action
        Write-Ok "$Name concluido"
        if ($Global:GenesisStepSink) { & $Global:GenesisStepSink $Key 'Ok' }
        return $true
    }
    catch {
        Write-Err2 "$Name falhou: $($_.Exception.Message)"
        if ($script:LogFile) {
            Add-Content -Path $script:LogFile -Value "[FAIL] $Name : $($_.Exception.Message)"
        }
        if ($Global:GenesisStepSink) { & $Global:GenesisStepSink $Key 'Fail' }
        return $false
    }
}

function Write-AppStatus {
    <#
        Reports one winget app's own install status (Running/Ok/Fail),
        independent of the "WingetApps" pipeline step as a whole - this is
        what lets the wizard light up each app card individually instead
        of showing one lump progress bar for the entire step.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][ValidateSet('Running', 'Ok', 'Fail')][string]$Status
    )
    if ($Global:GenesisAppSink) { & $Global:GenesisAppSink $Id $Status }
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}
