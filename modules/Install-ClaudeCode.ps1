function Install-ClaudeCode {
    if (Test-CommandExists 'claude') {
        Write-Ok "Claude Code ja instalado"
        return
    }
    Invoke-Expression (Invoke-RestMethod -Uri 'https://claude.ai/install.ps1')
    Write-Ok "Claude Code instalado"
}
