# Sets ExecutionPolicy to Bypass for LocalMachine so future scripts
# (including this project's own tools) run without prompts.
# Scope LocalMachine requires admin - genesis.ps1 already elevates.

function Set-ExecutionPolicyBypassAll {
    $current = Get-ExecutionPolicy -Scope LocalMachine
    if ($current -eq 'Bypass') {
        Write-Ok "ExecutionPolicy ja e Bypass (LocalMachine)"
        return
    }
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Write-Ok "ExecutionPolicy definido como Bypass (LocalMachine + CurrentUser)"
}
