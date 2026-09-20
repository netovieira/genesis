# Generates an SSH key (if one doesn't already exist) and registers it
# with GitHub via `gh`. `gh auth login` needs a one-time interactive step
# (open a browser, confirm a code) - there is no safe way to script a
# GitHub login without storing a password/token on disk, so this is the
# one deliberate pause in an otherwise unattended run.

function Set-GitHubSsh {
    param([string]$Email = $null)

    if (-not (Test-CommandExists 'ssh-keygen')) {
        throw "ssh-keygen nao encontrado (deveria vir com o OpenSSH Client do Windows)"
    }
    if (-not (Test-CommandExists 'gh')) {
        throw "gh (GitHub CLI) nao encontrado no PATH. Instale via winget primeiro."
    }

    $sshDir = Join-Path $HOME '.ssh'
    $keyPath = Join-Path $sshDir 'id_ed25519'
    if (-not (Test-Path $keyPath)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        $comment = if ($Email) { $Email } else { "$env:USERNAME@$env:COMPUTERNAME" }
        ssh-keygen -t ed25519 -C $comment -f $keyPath -N '""' | Out-Null
        Write-Ok "Chave SSH criada em $keyPath"
    }
    else {
        Write-Ok "Chave SSH ja existe em $keyPath"
    }

    $agentSvc = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
    if ($agentSvc) {
        if ($agentSvc.StartType -ne 'Automatic') { Set-Service -Name ssh-agent -StartupType Automatic }
        if ($agentSvc.Status -ne 'Running') { Start-Service -Name ssh-agent }
        ssh-add $keyPath 2>$null | Out-Null
    }

    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log2 "    Abrindo login do GitHub (gh auth login) - confirme no navegador..." -Color 'Yellow'
        gh auth login --hostname github.com --git-protocol ssh --web
        if ($LASTEXITCODE -ne 0) {
            throw "gh auth login falhou ou foi cancelado"
        }
    }
    else {
        Write-Ok "gh ja autenticado"
    }

    $pubKey = Get-Content "$keyPath.pub"
    $fingerprint = ($pubKey -split ' ')[1]
    $existingKeys = gh ssh-key list 2>$null
    if ($existingKeys -and ($existingKeys | Select-String -SimpleMatch $fingerprint)) {
        Write-Ok "Chave SSH ja cadastrada na conta do GitHub"
    }
    else {
        gh ssh-key add "$keyPath.pub" --title "$env:COMPUTERNAME (genesis)"
        Write-Ok "Chave SSH cadastrada na conta do GitHub"
    }
}
