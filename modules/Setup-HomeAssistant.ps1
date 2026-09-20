# Two ways to get Home Assistant running, chosen via config/home-assistant-vm.json's
# "Mode" field ("vm" or "docker") - set from the wizard's Home Assistant screen.
#
#   vm     - runs the EXISTING HomeAssistantOS disk (VdiPath) as a VirtualBox
#            VM. Full parity with whatever was already running (Supervisor,
#            add-ons, everything) - nothing is copied, the VM just points at
#            that disk. This is the safe default when you're not sure the
#            old install only used Core.
#   docker - starts a fresh "Home Assistant Container" (Docker) instead.
#            This is HA Core only - no Supervisor, no add-on store. If
#            BackupPath points at an exported Home Assistant backup (.tar),
#            it's copied into the new container's backups/ folder so it's
#            ready to restore - but the actual restore click still has to
#            happen in the Home Assistant UI (Settings > System > Backups),
#            since that's inside HA's own web app, not something this
#            script can drive.

function Invoke-HomeAssistantSetup {
    param([Parameter(Mandatory)][string]$ConfigPath)

    $cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    $mode = if ($cfg.Mode) { $cfg.Mode } else { 'vm' }

    if ($mode -eq 'docker') {
        Start-HomeAssistantDocker -Config $cfg
    }
    else {
        Start-HomeAssistantVM -ConfigPath $ConfigPath
    }
}

function Start-HomeAssistantVM {
    param([Parameter(Mandatory)][string]$ConfigPath)

    if (-not (Test-CommandExists 'VBoxManage')) {
        throw "VBoxManage nao encontrado no PATH. Instale o VirtualBox (winget) e rode de novo."
    }

    $cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    if (-not $cfg.VdiPath -or -not (Test-Path $cfg.VdiPath)) {
        throw "VDI do Home Assistant nao encontrado em '$($cfg.VdiPath)'. Informe o caminho na tela do wizard ou em config/home-assistant-vm.json."
    }

    $vmName = $cfg.VmName
    $existing = VBoxManage list vms 2>$null | Select-String -SimpleMatch "`"$vmName`""

    if (-not $existing) {
        Write-Host "    Registrando VM '$vmName' no VirtualBox..." -ForegroundColor DarkCyan
        VBoxManage createvm --name $vmName --ostype "Linux_64" --register | Out-Null
        VBoxManage modifyvm $vmName `
            --memory $cfg.MemoryMb --cpus $cfg.Cpus --firmware efi `
            --nic1 nat --natpf1 "hass,tcp,,$($cfg.HostPort),,8123" --audio-driver none | Out-Null
        VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAHCI | Out-Null
        VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 `
            --type hdd --medium $cfg.VdiPath | Out-Null
        Write-Ok "VM '$vmName' registrada usando o disco existente (nada foi copiado/apagado)"
    }
    else {
        Write-Ok "VM '$vmName' ja registrada"
    }

    $running = VBoxManage list runningvms 2>$null | Select-String -SimpleMatch "`"$vmName`""
    if (-not $running) {
        VBoxManage startvm $vmName --type headless | Out-Null
        Write-Host "    VM iniciada, aguardando Home Assistant responder em http://localhost:$($cfg.HostPort) ..." -ForegroundColor DarkCyan
    }
    else {
        Write-Ok "VM '$vmName' ja estava rodando"
    }

    Wait-HomeAssistantHttp -Port $cfg.HostPort
}

function Start-HomeAssistantDocker {
    param([Parameter(Mandatory)]$Config)

    if (-not (Test-CommandExists 'docker')) {
        throw "docker nao encontrado no PATH. Instale o Docker Desktop (winget) e rode de novo."
    }

    $containerName = 'homeassistant'
    $port = $Config.HostPort
    if (-not $port) { $port = 8123 }

    Write-Host "    Aguardando o Docker Desktop responder..." -ForegroundColor DarkCyan
    $dockerDeadline = (Get-Date).AddSeconds(120)
    $dockerReady = $false
    while ((Get-Date) -lt $dockerDeadline) {
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { $dockerReady = $true; break }
        Start-Sleep -Seconds 5
    }
    if (-not $dockerReady) {
        throw "Docker Desktop nao respondeu a tempo. Abra o Docker Desktop manualmente e rode de novo."
    }

    $exists = docker ps -a --format '{{.Names}}' | Select-String -SimpleMatch $containerName
    if (-not $exists) {
        Write-Host "    Criando container do Home Assistant..." -ForegroundColor DarkCyan
        docker run -d --name $containerName --restart=unless-stopped `
            -p "${port}:8123" -v 'ha_config:/config' -e 'TZ=America/Sao_Paulo' `
            homeassistant/home-assistant:stable | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Falha ao criar o container do Home Assistant (docker run retornou $LASTEXITCODE)" }
        Write-Ok "Container '$containerName' criado"
    }
    else {
        docker start $containerName | Out-Null
        Write-Ok "Container '$containerName' ja existia, iniciado"
    }

    if ($Config.BackupPath) {
        if (-not (Test-Path $Config.BackupPath)) {
            Write-Warn2 "Backup informado nao encontrado: $($Config.BackupPath) - pulando restauracao"
        }
        else {
            Write-Host "    Copiando backup pro container..." -ForegroundColor DarkCyan
            docker exec $containerName mkdir -p /config/backups 2>$null | Out-Null
            $fileName = Split-Path -Leaf $Config.BackupPath
            docker cp $Config.BackupPath "${containerName}:/config/backups/$fileName"
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Backup copiado - abra http://localhost:$port, va em Configuracoes > Sistema > Backups e restaure '$fileName' manualmente (Home Assistant Container nao tem Supervisor, entao a restauracao final e feita pela propria interface)"
            }
            else {
                Write-Warn2 "Falha ao copiar o backup pro container (codigo $LASTEXITCODE)"
            }
        }
    }

    Wait-HomeAssistantHttp -Port $port
}

function Wait-HomeAssistantHttp {
    param([int]$Port)

    $deadline = (Get-Date).AddSeconds(300)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 5 -UseBasicParsing
            if ($resp.StatusCode -eq 200) { $ready = $true; break }
        }
        catch { Start-Sleep -Seconds 5 }
    }

    if ($ready) {
        Write-Ok "Home Assistant disponivel em http://localhost:$Port"
    }
    else {
        Write-Warn2 "Home Assistant nao respondeu em 5 minutos - pode ainda estar inicializando, confira http://localhost:$Port manualmente"
    }
}
