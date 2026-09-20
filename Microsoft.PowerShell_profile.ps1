# ================================================================
# POWERSHELL PROFILE
# ================================================================

# ==========================================
# ALIAS MANAGEMENT
# ==========================================

@('h', 'k', 'g') | ForEach-Object {
    if (Test-Path Alias:$_) {
        Remove-Item Alias:$_ -Force
    }
}

Set-Alias -Name h -Value help-profile -Force
Set-Alias -Name g -Value goto -Force


# ==========================================
# NAVIGATION
# ==========================================

function goto {
    param (
        [Parameter(Mandatory=$false)]
        [string]$location
    )

    $project_path = $HOME

    $locationParts = $location -split '/'

    $locations = @{
        "all"  = "$project_path"
        "avnt" = "$project_path/avnt"
    }

    $basePath = $locations[$locationParts[0]]

    if ($basePath) {
        if ($locationParts.Length -gt 1) {
            $fullPath = Join-Path $basePath (
                $locationParts[1..($locationParts.Length-1)] -join '\'
            )
        }
        else {
            $fullPath = $basePath
        }
    }
    else {
        $fullPath = Join-Path $project_path $location
    }

    if (Test-Path $fullPath) {
        Set-Location -Path $fullPath
        Write-Host "Changed directory to: $fullPath" -ForegroundColor Green
    }
    else {
        Write-Warning "Path '$fullPath' does not exist"

        Write-Host "`nAvailable base locations:" -ForegroundColor Cyan

        $locations.GetEnumerator() | ForEach-Object {
            Write-Host "$($_.Key) => $($_.Value)" -ForegroundColor Yellow
        }
    }
}


# ==========================================
# TOOL DETECTION
# ==========================================

$script:HasKubectl = [bool](
    Get-Command kubectl -ErrorAction SilentlyContinue
)

if ($script:HasKubectl) {

    $kubeConfigPaths = @(
        ".kube/prod-k8s-clcreative-kubeconfig.yaml",
        ".kube/civo-k8s_test_1-kubeconfig",
        ".kube/k8s_test_1.yml"
    )

    $ENV:KUBECONFIG = $kubeConfigPaths -join ";"

    Set-Alias -Name k -Value kubectl -Force

    function kn {
        param (
            [Parameter(Mandatory=$false)]
            [string]$namespace
        )

        try {
            if (
                [string]::IsNullOrEmpty($namespace) -or
                $namespace -in @("default", "d")
            ) {
                kubectl config set-context --current --namespace=default
            }
            else {
                kubectl config set-context --current --namespace=$namespace
            }
        }
        catch {
            Write-Error "Failed to set namespace: $_"
        }
    }
}


# ==========================================
# IDE DETECTION
# ==========================================

$androidStudioPath =
    "C:\Users\anthe\AppData\Local\Programs\Android Studio\bin\studio64.exe"

$script:HasAndroidStudio = Test-Path $androidStudioPath

if ($script:HasAndroidStudio) {
    Set-Alias as $androidStudioPath
}


$pycharmPath =
    "C:\Users\anthe\AppData\Local\Programs\PyCharm\bin\pycharm64.exe"

$script:HasPyCharm = Test-Path $pycharmPath

if ($script:HasPyCharm) {
    Set-Alias pc $pycharmPath
}


$webstormBase = "C:\Program Files\JetBrains"
$script:WebStormExe = $null

if (Test-Path $webstormBase) {

    $webstormDir =
        Get-ChildItem `
            -Path $webstormBase `
            -Directory `
            -Filter "WebStorm*" `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($webstormDir) {

        $candidate =
            Join-Path $webstormDir.FullName "bin\webstorm64.exe"

        if (Test-Path $candidate) {
            $script:WebStormExe = $candidate
        }
    }
}

$script:HasWebStorm = [bool]$script:WebStormExe

if ($script:HasWebStorm) {
    Set-Alias ws $script:WebStormExe
}


# ==========================================
# QUICK INSTALLERS
# ==========================================

function install-kubectl {

    Write-Host "Instalando kubectl..." -ForegroundColor Cyan

    winget install -e --id Kubernetes.kubectl

    Write-Host `
        "Pronto. Rode 'reload' para o profile reconhecer o kubectl." `
        -ForegroundColor Green
}


function install-android-studio {

    Write-Host "Instalando Android Studio..." -ForegroundColor Cyan

    winget install -e --id Google.AndroidStudio

    Write-Host `
        "Pronto. Rode 'reload' para o profile reconhecer o alias 'as'." `
        -ForegroundColor Green
}


function install-pycharm {

    Write-Host "Instalando PyCharm..." -ForegroundColor Cyan

    winget install -e --id JetBrains.PyCharm.Community

    Write-Host `
        "Pronto. Rode 'reload' para o profile reconhecer o alias 'pc'." `
        -ForegroundColor Green
}


function install-webstorm {

    Write-Host "Instalando WebStorm..." -ForegroundColor Cyan

    winget install -e --id JetBrains.WebStorm

    Write-Host `
        "Pronto. Rode 'reload' para o profile reconhecer o alias 'ws'." `
        -ForegroundColor Green
}


function install-missing {

    if (-not $script:HasKubectl) {
        install-kubectl
    }

    if (-not $script:HasAndroidStudio) {
        install-android-studio
    }

    if (-not $script:HasPyCharm) {
        install-pycharm
    }

    if (-not $script:HasWebStorm) {
        install-webstorm
    }

    if (
        $script:HasKubectl -and
        $script:HasAndroidStudio -and
        $script:HasPyCharm -and
        $script:HasWebStorm
    ) {
        Write-Host "Nada faltando para instalar." -ForegroundColor Green
    }
}


# ==========================================
# STARSHIP
# ==========================================

$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"
$ENV:STARSHIP_DISTRO = "者 xcad"

if (Get-Command starship -ErrorAction SilentlyContinue) {

    Invoke-Expression (&starship init powershell)

}
else {

    Write-Warning `
        "Starship is not installed. Install it with: winget install Starship.Starship"
}


# ==========================================
# DATREE COMPLETION
# ==========================================

function __datree_debug {

    if ($env:BASH_COMP_DEBUG_FILE) {
        "$args" |
            Out-File `
                -Append `
                -FilePath "$env:BASH_COMP_DEBUG_FILE"
    }
}


filter __datree_escapeStringWithSpecialChars {

    $_ -replace `
        '\s|#|@|\$|;|,''|\{|\}|\(|\)|"|`|\||<|>|&',
        '`$&'
}


Register-ArgumentCompleter -CommandName 'datree' -ScriptBlock {

    param(
        $WordToComplete,
        $CommandAst,
        $CursorPosition
    )

    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __datree_debug ""
    __datree_debug "========= starting completion logic =========="
    __datree_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    if ($Command.Length -gt $CursorPosition) {
        $Command = $Command.Substring(0, $CursorPosition)
    }

    $ShellCompDirectiveError = 1
    $ShellCompDirectiveNoSpace = 2
    $ShellCompDirectiveNoFileComp = 4
    $ShellCompDirectiveFilterFileExt = 8
    $ShellCompDirectiveFilterDirs = 16

    $Program, $Arguments = $Command.Split(" ", 2)

    $RequestComp = "$Program __complete $Arguments"

    if ($WordToComplete -ne "") {
        $WordToComplete = $Arguments.Split(" ")[-1]
    }

    $IsEqualFlag = ($WordToComplete -Like "--*=*")

    if ($IsEqualFlag) {
        $Flag, $WordToComplete = $WordToComplete.Split("=", 2)
    }

    if (
        $WordToComplete -eq "" -And
        (-Not $IsEqualFlag)
    ) {
        $RequestComp = "$RequestComp" + ' `"`"'
    }

    Invoke-Expression `
        -OutVariable out `
        "$RequestComp" `
        2>&1 |
        Out-Null

    [int]$Directive = $Out[-1].TrimStart(':')

    if ($Directive -eq "") {
        $Directive = 0
    }

    $Out = $Out |
        Where-Object {
            $_ -ne $Out[-1]
        }

    if (
        ($Directive -band $ShellCompDirectiveError) -ne 0
    ) {
        return
    }

    $Longest = 0

    $Values = $Out |
        ForEach-Object {

            $Name, $Description = $_.Split("`t", 2)

            if ($Longest -lt $Name.Length) {
                $Longest = $Name.Length
            }

            if (-Not $Description) {
                $Description = " "
            }

            @{
                Name = "$Name"
                Description = "$Description"
            }
        }

    $Space = " "

    if (
        ($Directive -band $ShellCompDirectiveNoSpace) -ne 0
    ) {
        $Space = ""
    }

    if (
        ($Directive -band $ShellCompDirectiveNoFileComp) -ne 0
    ) {

        if ($Values.Length -eq 0) {
            ""
            return
        }
    }

    if (
        (($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0) -or
        (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0)
    ) {
        return
    }

    $Values = $Values |
        Where-Object {

            $_.Name -like "$WordToComplete*"

            if ($IsEqualFlag) {
                $_.Name = $Flag + "=" + $_.Name
            }
        }

    $Mode =
        (
            Get-PSReadLineKeyHandler |
            Where-Object {
                $_.Key -eq "Tab"
            }
        ).Function

    $Values |
        ForEach-Object {

            $comp = $_

            switch ($Mode) {

                "Complete" {

                    if ($Values.Length -eq 1) {

                        [System.Management.Automation.CompletionResult]::new(
                            $($comp.Name |
                                __datree_escapeStringWithSpecialChars) + $Space,
                            "$($comp.Name)",
                            'ParameterValue',
                            "$($comp.Description)"
                        )
                    }
                    else {

                        while ($comp.Name.Length -lt $Longest) {
                            $comp.Name = $comp.Name + " "
                        }

                        if ($comp.Description -eq " ") {
                            $Description = ""
                        }
                        else {
                            $Description =
                                "  ($($comp.Description))"
                        }

                        [System.Management.Automation.CompletionResult]::new(
                            "$($comp.Name)$Description",
                            "$($comp.Name)$Description",
                            'ParameterValue',
                            "$($comp.Description)"
                        )
                    }
                }

                "MenuComplete" {

                    [System.Management.Automation.CompletionResult]::new(
                        $($comp.Name |
                            __datree_escapeStringWithSpecialChars) + $Space,
                        "$($comp.Name)",
                        'ParameterValue',
                        "$($comp.Description)"
                    )
                }

                Default {

                    [System.Management.Automation.CompletionResult]::new(
                        $($comp.Name |
                            __datree_escapeStringWithSpecialChars),
                        "$($comp.Name)",
                        'ParameterValue',
                        "$($comp.Description)"
                    )
                }
            }
        }
}


# ==========================================
# NODE MODULES CLEANER
# ==========================================

function Clear-NodeModules {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false)]
        [switch]$Log,

        [Parameter(Mandatory=$false)]
        [string]$Path = ".",

        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $totalSize = 0
    $count = 0

    if ($Log) {

        $logFile =
            "node_modules_removal_log_$(
                (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
            ).txt"

        "Node Modules Removal Log - $date" |
            Out-File $logFile
    }

    Write-Host `
        "`nSearching for node_modules in: $((Resolve-Path $Path).Path)" `
        -ForegroundColor Cyan

    Get-ChildItem `
        -Path $Path `
        -Include "node_modules" `
        -Recurse `
        -Directory |
    ForEach-Object {

        $count++

        $folderSize =
            (
                Get-ChildItem $_.FullName -Recurse |
                Measure-Object -Property Length -Sum
            ).Sum / 1MB

        $totalSize += $folderSize

        $message =
            "`nFound node_modules: $($_.FullName)"

        $sizeMessage =
            "Size: $([Math]::Round($folderSize, 2)) MB"

        Write-Host $message -ForegroundColor Yellow
        Write-Host $sizeMessage -ForegroundColor Cyan

        if ($Log) {
            $message | Out-File $logFile -Append
            $sizeMessage | Out-File $logFile -Append
        }

        if (-not $WhatIf) {

            try {

                Remove-Item `
                    $_.FullName `
                    -Recurse `
                    -Force

                $success = "Successfully removed!"

                Write-Host $success -ForegroundColor Green

                if ($Log) {
                    $success | Out-File $logFile -Append
                }
            }
            catch {

                $errorMessage =
                    "Error removing $($_.FullName): $($_.Exception.Message)"

                Write-Host $errorMessage -ForegroundColor Red

                if ($Log) {
                    $errorMessage | Out-File $logFile -Append
                }
            }
        }

        if ($Log) {
            "------------------------" |
                Out-File $logFile -Append
        }
    }

    $summary = "`nSummary:"
    $summary += "`nTotal folders found: $count"
    $summary +=
        "`nTotal size freed: $([Math]::Round($totalSize, 2)) MB"

    Write-Host $summary -ForegroundColor Magenta

    if ($Log) {

        $summary | Out-File $logFile -Append

        Write-Host `
            "`nLog file created at: $((Get-Item $logFile).FullName)" `
            -ForegroundColor Magenta
    }
}

Set-Alias `
    -Name clear-modules `
    -Value Clear-NodeModules


# ==========================================
# UTILS
# ==========================================

function reload {

    . $PROFILE

    Write-Host `
        "Profile recarregado com sucesso!" `
        -ForegroundColor Green
}


function profile {
    code $PROFILE
}


function myip {

    $local =
        (
            Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.InterfaceAlias -like "*Wi-Fi*" -or
                $_.InterfaceAlias -like "*Ethernet*"
            }
        ).IPAddress

    $public =
        Invoke-RestMethod -Uri "https://api.ipify.org"

    Write-Host "Local IP : " -NoNewline
    Write-Host $local -ForegroundColor Cyan

    Write-Host "Public IP: " -NoNewline
    Write-Host $public -ForegroundColor Green
}


function ports {

    Get-NetTCPConnection -State Listen |
        Select-Object `
            LocalAddress,
            LocalPort,
            OwningProcess,
            @{
                Name = "ProcessName"
                Expression = {
                    (Get-Process -Id $_.OwningProcess).Name
                }
            } |
        Format-Table -AutoSize
}


function gl {

    git log `
        --graph `
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' `
        --abbrev-commit
}


function make {
    .\make.bat @args
}


# ================================================================
# SECRET HAND
# ================================================================
#
# O estado do lockout existe somente em memoria.
#
# Arquivo persistente:
#   $HOME\.powershell-secret.json
#
# O arquivo guarda somente:
#   ExitKey
#   ShowKey
#
# NAO sao salvos:
#   - tentativas
#   - contador
#   - tempo restante
#   - estado do bloqueio
#
# ================================================================

# ==========================================
# BYPASS PARA IA / AUTOMACAO
# ==========================================
#
# Para agentes (IA, scripts, pipelines) NAO
# travar na lockscreen do Secret Hand:
#
#   1) variavel de ambiente (so na sessao do agente):
#        $env:PSH_PROFILE_BYPASS = '1'
#
#      NAO rode 'setx PSH_PROFILE_BYPASS 1' (global): isso desligaria o
#      lock tambem para humanos.
#
#   2) o profile detecta sozinho contextos
#      nao interativos (stdin redirecionado,
#      -Command / -File / -NonInteractive)
#      e pula o lock automaticamente.
#
# Para forcar o lock de novo a qualquer
# momento (mesmo com bypass): rode 'secret'
# ou 'secret-off'.
#
# ==========================================

function Get-SecretBypassReason {

    $truthy = @('1','true','on','yes','enabled')

    if (
        $env:PSH_PROFILE_BYPASS -and
        $env:PSH_PROFILE_BYPASS.Trim().ToLower() -in $truthy
    ) {
        return "env PSH_PROFILE_BYPASS"
    }

    if (-not [Environment]::UserInteractive) {
        return "sessao nao interativa"
    }

    if ([Console]::IsInputRedirected) {
        return "input redirecionado (pipe/agent)"
    }

    $cmdArgs = [Environment]::GetCommandLineArgs()

    foreach ($flag in @('-Command','-File','-EncodedCommand','-NonInteractive')) {
        if ($cmdArgs -contains $flag) {
            return "invocacao scriptada ($flag)"
        }
    }

    return $null
}


$script:SecretBypassReason = Get-SecretBypassReason
$script:SecretBypass = [bool]$script:SecretBypassReason


$script:SecretConfigPath =
    Join-Path $HOME ".powershell-secret.json"


# ==========================================
# CONFIGURACAO DE TECLAS
# ==========================================

$script:SecretKeyMap = @{

    "LEFT"   = [ConsoleKey]::LeftArrow
    "RIGHT"  = [ConsoleKey]::RightArrow
    "UP"     = [ConsoleKey]::UpArrow
    "DOWN"   = [ConsoleKey]::DownArrow

    "HOME"   = [ConsoleKey]::Home
    "END"    = [ConsoleKey]::End

    "INSERT" = [ConsoleKey]::Insert
    "DELETE" = [ConsoleKey]::Delete

    "PGUP"   = [ConsoleKey]::PageUp
    "PGDN"   = [ConsoleKey]::PageDown

    "TAB"    = [ConsoleKey]::Tab
    "SPACE"  = [ConsoleKey]::Spacebar
    "ESC"    = [ConsoleKey]::Escape
}


function Get-SecretKeyInfo {

    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyName
    )

    $normalized =
        $KeyName.Trim().ToUpperInvariant()


    if ($normalized -match '^F([1-9]|1[0-2])$') {

        return @{
            Name = $normalized
            Key  = [ConsoleKey]::$normalized
        }
    }


    if ($normalized.Length -eq 1) {

        $char = $normalized[0]

        if (
            $char -ge 'A' -and
            $char -le 'Z'
        ) {

            return @{
                Name = $normalized
                Key  = [System.Enum]::Parse(
                    [ConsoleKey],
                    $normalized
                )
            }
        }


        if (
            $char -ge '0' -and
            $char -le '9'
        ) {

            return @{
                Name = $normalized
                Key  = [System.Enum]::Parse(
                    [ConsoleKey],
                    "D$char"
                )
            }
        }
    }


    if ($script:SecretKeyMap.ContainsKey($normalized)) {

        return @{
            Name = $normalized
            Key  = $script:SecretKeyMap[$normalized]
        }
    }


    throw @"
Tecla '$KeyName' nao e suportada.

Exemplos:
J
H
LEFT
RIGHT
UP
DOWN
HOME
END
INSERT
DELETE
PGUP
PGDN
TAB
SPACE
ESC
F1..F12
"@
}


# ==========================================
# PERSISTENCIA
# ==========================================

function Save-SecretConfig {

    param(
        [Parameter(Mandatory=$true)]
        [string]$ExitKey,

        [Parameter(Mandatory=$true)]
        [string]$ShowKey
    )

    @{
        ExitKey = $ExitKey
        ShowKey = $ShowKey
    } |
        ConvertTo-Json |
        Set-Content `
            -Path $script:SecretConfigPath `
            -Encoding UTF8
}


function Get-SecretConfig {

    $default = @{
        ExitKey = "INSERT"
        ShowKey = "HOME"
    }


    if (-not (Test-Path $script:SecretConfigPath)) {

        Save-SecretConfig `
            -ExitKey $default.ExitKey `
            -ShowKey $default.ShowKey

        return $default
    }


    try {

        $config =
            Get-Content `
                $script:SecretConfigPath `
                -Raw |
            ConvertFrom-Json

        $exit = [string]$config.ExitKey
        $show = [string]$config.ShowKey


        [void](Get-SecretKeyInfo $exit)
        [void](Get-SecretKeyInfo $show)


        return @{
            ExitKey = $exit.ToUpperInvariant()
            ShowKey = $show.ToUpperInvariant()
        }
    }
    catch {

        Write-Warning `
            "Configuracao de secret keys invalida. Voltando para CTRL+SHIFT+INSERT / CTRL+SHIFT+HOME."

        Save-SecretConfig `
            -ExitKey $default.ExitKey `
            -ShowKey $default.ShowKey

        return $default
    }
}


$script:SecretConfig = Get-SecretConfig


$script:SecretStatusLine = ''
$script:SecretStatusColor = [ConsoleColor]::Yellow


function Get-SecretChord {

    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyName
    )

    return "Ctrl+Shift+$($KeyName.ToUpperInvariant())"
}


# ==========================================
# LOCKOUT
# ==========================================

$script:SecretMaxAttempts = 3
$script:SecretLockoutSeconds = 15

# Estado somente em memoria.
$script:SecretFailedAttempts = 0
$script:SecretLockoutUntil = $null
$script:SecretSecurityMessageUntil = $null


function Test-SecretKey {

    param(
        [Parameter(Mandatory=$true)]
        [System.ConsoleKeyInfo]$KeyInfo,

        [Parameter(Mandatory=$true)]
        [string]$ExpectedKey
    )

    $expected =
        Get-SecretKeyInfo $ExpectedKey


    return (
        $KeyInfo.Key -eq $expected.Key -and

        (
            $KeyInfo.Modifiers -band
            [ConsoleModifiers]::Control
        ) -ne 0 -and

        (
            $KeyInfo.Modifiers -band
            [ConsoleModifiers]::Shift
        ) -ne 0
    )
}


function Test-SecretWrongChord {

    param(
        [Parameter(Mandatory=$true)]
        [System.ConsoleKeyInfo]$KeyInfo
    )

    $isCtrl =
        (
            $KeyInfo.Modifiers -band
            [ConsoleModifiers]::Control
        ) -ne 0

    $isShift =
        (
            $KeyInfo.Modifiers -band
            [ConsoleModifiers]::Shift
        ) -ne 0


    return (
        $isCtrl -and
        $isShift
    )
}


# ==========================================
# MENSAGENS DO LOCK
# ==========================================

function Write-SecretSecurityMessage {

    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ConsoleColor]$Color =
            [ConsoleColor]::Yellow
    )


    try {

        $width =
            [Console]::WindowWidth

        if ($width -le 0) {
            return
        }


        $display =
            "  $Message  "


        if ($display.Length -ge $width) {

            $display =
                $display.Substring(
                    0,
                    [Math]::Max(0, $width - 1)
                )
        }


        $left =
            [Math]::Max(
                0,
                [int][Math]::Floor(
                    ($width - $display.Length) / 2
                )
            )


        $top =
            [Console]::WindowHeight - 2


        if ($top -lt 0) {
            $top = 0
        }


        [Console]::SetCursorPosition(
            $left,
            $top
        )


        $oldColor =
            [Console]::ForegroundColor

        [Console]::ForegroundColor =
            $Color


        $available =
            [Math]::Max(
                0,
                $width - $left
            )


        [Console]::Write(
            $display.PadRight($available)
        )


        [Console]::ForegroundColor =
            $oldColor
    }
    catch {
        # A mensagem jamais deve derrubar a animacao.
    }
}


function Clear-SecretSecurityMessage {

    try {

        $width =
            [Console]::WindowWidth

        $top =
            [Console]::WindowHeight - 2


        if ($top -ge 0 -and $width -gt 0) {

            [Console]::SetCursorPosition(
                0,
                $top
            )

            [Console]::Write(
                (' ' * $width)
            )
        }
    }
    catch {}


    $script:SecretStatusLine = ''
    $script:SecretStatusColor = [ConsoleColor]::Yellow
}


# ==========================================
# REGISTRO DE ERRO
# ==========================================

function Update-SecretLockout {

    # Atualiza o lockout sem bloquear o loop da animacao.
    # O status fica persistente e e re-pintado a cada frame.
    if ($null -ne $script:SecretLockoutUntil) {

        $remaining = [Math]::Ceiling(
            ($script:SecretLockoutUntil - [DateTime]::UtcNow).TotalSeconds
        )

        if ($remaining -gt 0) {

            $script:SecretStatusLine =
                "ACESSO BLOQUEADO — tente novamente em ${remaining}s"

            $script:SecretStatusColor =
                [ConsoleColor]::Red

            return $true
        }

        $script:SecretLockoutUntil = $null
        $script:SecretFailedAttempts = 0

        $script:SecretStatusLine =
            "BLOQUEIO ENCERRADO — tente novamente"

        $script:SecretStatusColor =
            [ConsoleColor]::Green

        $script:SecretSecurityMessageUntil =
            [DateTime]::UtcNow.AddSeconds(1)

        return $false
    }

    if (
        $null -ne $script:SecretSecurityMessageUntil -and
        [DateTime]::UtcNow -ge $script:SecretSecurityMessageUntil
    ) {

        $script:SecretStatusLine = ''
        $script:SecretSecurityMessageUntil = $null
    }

    return $false
}


function Register-SecretFailedAttempt {

    if (Update-SecretLockout) {
        return $false
    }

    $script:SecretFailedAttempts++

    $remaining =
        $script:SecretMaxAttempts -
        $script:SecretFailedAttempts

    if ($remaining -gt 0) {

        $word = if ($remaining -eq 1) { "tentativa" } else { "tentativas" }

        # Persistente: fica visivel ate o proximo evento.
        $script:SecretStatusLine =
            "COMBINACAO INCORRETA — faltam $remaining $word"

        $script:SecretStatusColor =
            [ConsoleColor]::Yellow

        return $false
    }

    $script:SecretLockoutUntil =
        [DateTime]::UtcNow.AddSeconds($script:SecretLockoutSeconds)

    $script:SecretStatusLine =
        "ACESSO BLOQUEADO — tente novamente em $($script:SecretLockoutSeconds)s"

    $script:SecretStatusColor =
        [ConsoleColor]::Red

    return $false
}

# ==========================================
# LEITURA DA TECLA
# ==========================================

function Read-SecretAttempt {

    param(
        [Parameter(Mandatory=$true)]
        [System.ConsoleKeyInfo]$KeyInfo
    )


    # A combinacao correta encerra imediatamente.
    if (
        Test-SecretKey `
            -KeyInfo $KeyInfo `
            -ExpectedKey $script:SecretConfig.ExitKey
    ) {

        return "CORRECT"
    }


    # Somente combinacoes Ctrl+Shift sao
    # consideradas tentativas.
    if (
        Test-SecretWrongChord `
            -KeyInfo $KeyInfo
    ) {

        return "WRONG"
    }


    # Outras teclas sao simplesmente ignoradas.
    return "IGNORE"
}


# ================================================================
# SECRET HAND ASCII ART
# ================================================================

$script:SecretHandArt = @(
    "             ###"
    "            #110#"
    "            #110#"
    "            #100#"
    "            #010#"
    "            #001#"
    "            #111#"
    "          ####100####"
    "         #110#100#000####"
    "         #111#111#100#11#"
    "         #110#100#000#00#"
    "   ##### #011#001#100#11#"
    "  #001####10011011110011#"
    "   #001##10011011110000#"
    "    #001#1001101111000#"
    "     #001100110111100#"
    "      #0010011011110#"
    "      ###############"
)


$script:SecretHandFingerTopRow = 0
$script:SecretHandFingerBaseRow = 6
$script:SecretHandPalmStartRow = 7

$script:SecretHandMinFingerLayers = 0
$script:SecretHandMaxFingerLayers = 7

$script:SecretHandRetractedTop =
    "             #####"


# ==========================================
# GERADOR DE FRAME
# ==========================================

function Get-SecretHandFrame {

    param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(0,7)]
        [int]$FingerLayers,

        [Parameter(Mandatory=$false)]
        [hashtable]$FadeLevels = @{}
    )


    $art =
        $script:SecretHandArt


    $frame =
        New-Object 'System.Collections.Generic.List[string]'


    $firstVisibleFingerRow =
        $script:SecretHandFingerBaseRow -
        $FingerLayers +
        1


    for (
        $row = 0;
        $row -lt $art.Count;
        $row++
    ) {

        $source =
            [string]$art[$row]


        $isPalm =
            (
                $row -ge
                $script:SecretHandPalmStartRow
            )


        $isFinger =
            (
                $row -ge $firstVisibleFingerRow -and
                $row -le $script:SecretHandFingerBaseRow
            )


        $isTransitionRow =
            (
                $FadeLevels -and
                $FadeLevels.ContainsKey($row) -and
                $row -ge $script:SecretHandFingerTopRow -and
                $row -le $script:SecretHandFingerBaseRow
            )


        # Estado retraido.
        if (
            $FingerLayers -eq 0 -and
            $row -eq $script:SecretHandFingerBaseRow -and
            -not $isTransitionRow
        ) {

            [void]$frame.Add(
                $script:SecretHandRetractedTop
            )

            continue
        }


        # A palma permanece fixa.
        if ($isPalm) {

            $chars =
                $source.ToCharArray()


            for (
                $i = 0;
                $i -lt $chars.Length;
                $i++
            ) {

                if (
                    $chars[$i] -eq '0' -or
                    $chars[$i] -eq '1'
                ) {

                    if (
                        (Get-Random -Minimum 0 -Maximum 2) -eq 0
                    ) {
                        $chars[$i] = '0'
                    }
                    else {
                        $chars[$i] = '1'
                    }
                }
            }


            [void]$frame.Add(
                (-join $chars)
            )

            continue
        }


        if (
            -not $isFinger -and
            -not $isTransitionRow
        ) {

            [void]$frame.Add(
                (' ' * $source.Length)
            )

            continue
        }


        $fade = 1.0


        if (
            $FadeLevels -and
            $FadeLevels.ContainsKey($row)
        ) {

            $fade =
                [double]$FadeLevels[$row]
        }


        if (
            $row -eq
            $script:SecretHandFingerTopRow -and
            $FadeLevels.ContainsKey($row)
        ) {

            if ($fade -lt 0.5) {

                [void]$frame.Add(
                    (' ' * $source.Length)
                )

                continue
            }
        }


        $chars =
            $source.ToCharArray()


        for (
            $i = 0;
            $i -lt $chars.Length;
            $i++
        ) {

            if ($chars[$i] -eq '#') {
                continue
            }


            if (
                $chars[$i] -eq '0' -or
                $chars[$i] -eq '1'
            ) {

                if ($fade -le 0.0) {

                    $chars[$i] = ' '
                }

                elseif ($fade -lt 1.0) {

                    $chance =
                        (
                            Get-Random -Minimum 0 -Maximum 1000
                        ) / 1000.0


                    if ($chance -lt $fade) {

                        if (
                            (Get-Random -Minimum 0 -Maximum 2) -eq 0
                        ) {
                            $chars[$i] = '0'
                        }
                        else {
                            $chars[$i] = '1'
                        }
                    }
                    else {
                        $chars[$i] = ' '
                    }
                }
                else {

                    if (
                        (Get-Random -Minimum 0 -Maximum 2) -eq 0
                    ) {
                        $chars[$i] = '0'
                    }
                    else {
                        $chars[$i] = '1'
                    }
                }
            }
        }


        [void]$frame.Add(
            (-join $chars)
        )
    }


    return $frame.ToArray()
}


# ==========================================
# RENDERIZADOR
# ==========================================

function Write-SecretHandFrame {

    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [string[]]$Frame = @(),

        [Parameter(Mandatory=$true)]
        [int]$OldTop,

        [Parameter(Mandatory=$true)]
        [int]$OldLeft,

        [Parameter(Mandatory=$true)]
        [int]$OldWidth,

        [Parameter(Mandatory=$true)]
        [int]$OldHeight
    )


    $consoleWidth =
        [Console]::WindowWidth

    $consoleHeight =
        [Console]::WindowHeight


    if (
        $consoleWidth -le 0 -or
        $consoleHeight -le 0
    ) {

        return @{
            Top    = $OldTop
            Left   = $OldLeft
            Width  = $OldWidth
            Height = $OldHeight
        }
    }


    $artHeight =
        $script:SecretHandArt.Count


    $artWidth =
        (
            $script:SecretHandArt |
            ForEach-Object {
                $_.Length
            } |
            Measure-Object -Maximum
        ).Maximum


    # Limpa somente o frame anterior.
    if (
        $OldWidth -gt 0 -and
        $OldHeight -gt 0
    ) {

        for (
            $y = 0;
            $y -lt $OldHeight;
            $y++
        ) {

            $py =
                $OldTop + $y


            if (
                $py -lt 0 -or
                $py -ge $consoleHeight
            ) {
                continue
            }


            if (
                $OldLeft -ge 0 -and
                $OldLeft -lt $consoleWidth
            ) {

                $width =
                    [Math]::Min(
                        $OldWidth,
                        $consoleWidth - $OldLeft
                    )


                if ($width -gt 0) {

                    try {

                        [Console]::SetCursorPosition(
                            $OldLeft,
                            $py
                        )

                        [Console]::Write(
                            (' ' * $width)
                        )
                    }
                    catch {}
                }
            }
        }
    }


    $drawWidth =
        [Math]::Min(
            $artWidth,
            $consoleWidth
        )


    $drawHeightBase =
        [Math]::Min(
            $artHeight,
            $consoleHeight
        )


    # Reserva a ultima linha do console para o status strip,
    # garantindo que a mensagem nunca seja coberta pela animacao.
    $maxDrawHeight =
        [Math]::Max(
            1,
            $consoleHeight - 2
        )


    $drawHeight =
        [Math]::Min(
            $drawHeightBase,
            $maxDrawHeight
        )


    $left =
        [Math]::Max(
            0,
            [int][Math]::Floor(
                ($consoleWidth - $artWidth) / 2
            )
        )


    $top =
        [Math]::Max(
            0,
            [int][Math]::Floor(
                ($consoleHeight - $artHeight) / 2
            )
        )


    if (
        $top + $drawHeight -gt $consoleHeight
    ) {

        $top =
            [Math]::Max(
                0,
                $consoleHeight - $drawHeight
            )
    }


    if (
        $left + $drawWidth -gt $consoleWidth
    ) {

        $left =
            [Math]::Max(
                0,
                $consoleWidth - $drawWidth
            )
    }


    for (
        $y = 0;
        $y -lt $drawHeight;
        $y++
    ) {

        $py =
            $top + $y


        $line = ''


        if (
            $y -lt $Frame.Count
        ) {

            $line =
                [string]$Frame[$y]
        }


        if (
            $line.Length -gt $drawWidth
        ) {

            $line =
                $line.Substring(
                    0,
                    $drawWidth
                )
        }


        $line =
            $line.PadRight($drawWidth)


        try {

            [Console]::SetCursorPosition(
                $left,
                $py
            )

            [Console]::Write($line)
        }
        catch {}
    }


    # ============================================================
    # STATUS STRIP — mensagem de erro, tentativas e cronometro
    # ============================================================

    $statusRow =
        $consoleHeight - 2


    if ($statusRow -ge 0) {

        $statusText =
            [string]$script:SecretStatusLine


        try {

            [Console]::SetCursorPosition(
                0,
                $statusRow
            )


            if ($statusText) {

                if ($statusText.Length -ge $consoleWidth) {

                    $statusText =
                        $statusText.Substring(
                            0,
                            [Math]::Max(0, $consoleWidth - 1)
                        )
                }


                $oldForeground =
                    [Console]::ForegroundColor

                [Console]::ForegroundColor =
                    $script:SecretStatusColor


                [Console]::Write(
                    $statusText.PadRight($consoleWidth)
                )


                [Console]::ForegroundColor =
                    $oldForeground
            }
            else {

                [Console]::Write(
                    (' ' * $consoleWidth)
                )
            }
        }
        catch {}
    }


    return @{
        Top    = $top
        Left   = $left
        Width  = $drawWidth
        Height = $drawHeight
    }
}


# ================================================================
# PROCESSAMENTO DE INPUT DURANTE O LOCK
# ================================================================

function Invoke-SecretInputCheck {

    param(
        [Parameter(Mandatory=$true)]
        [ref]$OldTop,

        [Parameter(Mandatory=$true)]
        [ref]$OldLeft,

        [Parameter(Mandatory=$true)]
        [ref]$OldWidth,

        [Parameter(Mandatory=$true)]
        [ref]$OldHeight
    )


    if (Update-SecretLockout) {
        return $false
    }

    if (-not [Console]::KeyAvailable) {
        return $false
    }


    # Drena a fila de teclas: um unico toque nao vira varias tentativas.
    :secretDrainInput while ([Console]::KeyAvailable) {

        $keyInfo =
            [Console]::ReadKey($true)


        $result =
            Read-SecretAttempt -KeyInfo $keyInfo


        switch ($result) {

            "CORRECT" {

                [void](
                    Write-SecretHandFrame `
                        -Frame @() `
                        -OldTop $OldTop.Value `
                        -OldLeft $OldLeft.Value `
                        -OldWidth $OldWidth.Value `
                        -OldHeight $OldHeight.Value
                )

                return $true
            }


            "WRONG" {

                [void](
                    Register-SecretFailedAttempt
                )


                if (Update-SecretLockout) {
                    break secretDrainInput
                }
            }


            Default {

                # Outras teclas sao ignoradas.
            }
        }
    }

    return $false
}


# ================================================================
# ANIMACAO
# ================================================================

function Show-SecretHandAnimation {

    $maxFinger =
        $script:SecretHandMaxFingerLayers


    $oldCursorVisible = $true

    $oldTop = 0
    $oldLeft = 0
    $oldWidth = 0
    $oldHeight = 0


    try {

        try {

            $oldCursorVisible =
                [Console]::CursorVisible

            [Console]::CursorVisible = $false
        }
        catch {}


        # ========================================================
        # 0. MAO RETRAIDA
        # ========================================================

        $frame =
            @(
                Get-SecretHandFrame `
                    -FingerLayers 0 `
                    -FadeLevels @{}
            )


        $pos =
            Write-SecretHandFrame `
                -Frame $frame `
                -OldTop $oldTop `
                -OldLeft $oldLeft `
                -OldWidth $oldWidth `
                -OldHeight $oldHeight


        $oldTop = $pos.Top
        $oldLeft = $pos.Left
        $oldWidth = $pos.Width
        $oldHeight = $pos.Height


        Start-Sleep -Milliseconds 40


        # ========================================================
        # 1. DEDO SOBE
        # ========================================================

        for (
            $visible = 1;
            $visible -le $maxFinger;
            $visible++
        ) {

            $newRow =
                $script:SecretHandFingerBaseRow -
                $visible +
                1


            for (
                $step = 0;
                $step -le 2;
                $step++
            ) {

                if (
                    Invoke-SecretInputCheck `
                        -OldTop ([ref]$oldTop) `
                        -OldLeft ([ref]$oldLeft) `
                        -OldWidth ([ref]$oldWidth) `
                        -OldHeight ([ref]$oldHeight)
                ) {
                    return
                }


                $fadeLevels = @{
                    $newRow = $step / 2.0
                }


                $frame =
                    @(
                        Get-SecretHandFrame `
                            -FingerLayers $visible `
                            -FadeLevels $fadeLevels
                    )


                $pos =
                    Write-SecretHandFrame `
                        -Frame $frame `
                        -OldTop $oldTop `
                        -OldLeft $oldLeft `
                        -OldWidth $oldWidth `
                        -OldHeight $oldHeight


                $oldTop = $pos.Top
                $oldLeft = $pos.Left
                $oldWidth = $pos.Width
                $oldHeight = $pos.Height


                Start-Sleep -Milliseconds 15
            }
        }


        # ========================================================
        # 2. DEDO COMPLETO POR 4 SEGUNDOS
        # ========================================================

        $holdUntil =
            [DateTime]::UtcNow.AddSeconds(4)


        while (
            [DateTime]::UtcNow -lt $holdUntil
        ) {

            if (
                Invoke-SecretInputCheck `
                    -OldTop ([ref]$oldTop) `
                    -OldLeft ([ref]$oldLeft) `
                    -OldWidth ([ref]$oldWidth) `
                    -OldHeight ([ref]$oldHeight)
            ) {
                return
            }


            $frame =
                @(
                    Get-SecretHandFrame `
                        -FingerLayers $maxFinger `
                        -FadeLevels @{}
                )


            $pos =
                Write-SecretHandFrame `
                    -Frame $frame `
                    -OldTop $oldTop `
                    -OldLeft $oldLeft `
                    -OldWidth $oldWidth `
                    -OldHeight $oldHeight


            $oldTop = $pos.Top
            $oldLeft = $pos.Left
            $oldWidth = $pos.Width
            $oldHeight = $pos.Height


            Start-Sleep -Milliseconds 70
        }


        # ========================================================
        # 3. DEDO DESCE
        # ========================================================

        for (
            $visible = $maxFinger - 1;
            $visible -ge 1;
            $visible--
        ) {

            $removedRow =
                $script:SecretHandFingerBaseRow -
                $visible


            for (
                $step = 0;
                $step -le 2;
                $step++
            ) {

                if (
                    Invoke-SecretInputCheck `
                        -OldTop ([ref]$oldTop) `
                        -OldLeft ([ref]$oldLeft) `
                        -OldWidth ([ref]$oldWidth) `
                        -OldHeight ([ref]$oldHeight)
                ) {
                    return
                }


                $fadeLevels = @{
                    $removedRow = 1.0 - ($step / 2.0)
                }


                $frame =
                    @(
                        Get-SecretHandFrame `
                            -FingerLayers $visible `
                            -FadeLevels $fadeLevels
                    )


                $pos =
                    Write-SecretHandFrame `
                        -Frame $frame `
                        -OldTop $oldTop `
                        -OldLeft $oldLeft `
                        -OldWidth $oldWidth `
                        -OldHeight $oldHeight


                $oldTop = $pos.Top
                $oldLeft = $pos.Left
                $oldWidth = $pos.Width
                $oldHeight = $pos.Height


                Start-Sleep -Milliseconds 15
            }
        }


        # ========================================================
        # 4. RETRAI RAPIDO
        # ========================================================

        for (
            $step = 0;
            $step -le 2;
            $step++
        ) {

            if (
                Invoke-SecretInputCheck `
                    -OldTop ([ref]$oldTop) `
                    -OldLeft ([ref]$oldLeft) `
                    -OldWidth ([ref]$oldWidth) `
                    -OldHeight ([ref]$oldHeight)
            ) {
                return
            }


            if ($step -lt 2) {

                $fadeLevels = @{
                    $script:SecretHandFingerBaseRow =
                        1.0 - ($step / 2.0)
                }


                $frame =
                    @(
                        Get-SecretHandFrame `
                            -FingerLayers 1 `
                            -FadeLevels $fadeLevels
                    )
            }
            else {

                $frame =
                    @(
                        Get-SecretHandFrame `
                            -FingerLayers 0 `
                            -FadeLevels @{}
                    )
            }


            $pos =
                Write-SecretHandFrame `
                    -Frame $frame `
                    -OldTop $oldTop `
                    -OldLeft $oldLeft `
                    -OldWidth $oldWidth `
                    -OldHeight $oldHeight


            $oldTop = $pos.Top
            $oldLeft = $pos.Left
            $oldWidth = $pos.Width
            $oldHeight = $pos.Height


            Start-Sleep -Milliseconds 15
        }


        # ========================================================
        # 5. MODO PERMANENTE
        # ========================================================

        :secretMain while ($true) {

            # ----------------------------------------------------
            # LOCKOUT / INPUT
            # ----------------------------------------------------

            $isLocked = Update-SecretLockout

            # ----------------------------------------------------
            # INPUT (drena fila de teclas: 1 toque != N tentativas)
            # ----------------------------------------------------

            if (-not $isLocked -and [Console]::KeyAvailable) {

                :secretDrain while ([Console]::KeyAvailable) {

                    $keyInfo =
                        [Console]::ReadKey($true)


                    $result =
                        Read-SecretAttempt `
                            -KeyInfo $keyInfo


                    if ($result -eq "CORRECT") {
                        break secretMain
                    }


                    if ($result -eq "WRONG") {

                        [void](
                            Register-SecretFailedAttempt
                        )


                        if (Update-SecretLockout) {
                            break secretDrain
                        }
                    }
                }
            }


            # ----------------------------------------------------
            # GLITCH
            # ----------------------------------------------------

            $glitch =
                Get-Random -Minimum 0 -Maximum 100


            if ($glitch -lt 7) {

                $drop =
                    Get-Random -Minimum 1 -Maximum 4


                $temporaryHeight =
                    [Math]::Max(
                        1,
                        $maxFinger - $drop
                    )


                $frame =
                    @(
                        Get-SecretHandFrame `
                            -FingerLayers $temporaryHeight `
                            -FadeLevels @{}
                    )


                $pos =
                    Write-SecretHandFrame `
                        -Frame $frame `
                        -OldTop $oldTop `
                        -OldLeft $oldLeft `
                        -OldWidth $oldWidth `
                        -OldHeight $oldHeight


                $oldTop = $pos.Top
                $oldLeft = $pos.Left
                $oldWidth = $pos.Width
                $oldHeight = $pos.Height


                Start-Sleep -Milliseconds (
                    Get-Random -Minimum 25 -Maximum 60
                )
            }


            # ----------------------------------------------------
            # REPAINT COMPLETO — mantem o status (erro, tentativas
            # e cronometro) sempre visivel e o terminal sincronizado
            # ----------------------------------------------------

            $frame =
                @(
                    Get-SecretHandFrame `
                        -FingerLayers $maxFinger `
                        -FadeLevels @{}
                )


            $pos =
                Write-SecretHandFrame `
                    -Frame $frame `
                    -OldTop $oldTop `
                    -OldLeft $oldLeft `
                    -OldWidth $oldWidth `
                    -OldHeight $oldHeight


            $oldTop = $pos.Top
            $oldLeft = $pos.Left
            $oldWidth = $pos.Width
            $oldHeight = $pos.Height


            Start-Sleep -Milliseconds 45
        }


        # ========================================================
        # SAIDA NORMAL
        # ========================================================

        [void](
            Write-SecretHandFrame `
                -Frame @() `
                -OldTop $oldTop `
                -OldLeft $oldLeft `
                -OldWidth $oldWidth `
                -OldHeight $oldHeight
        )
    }
    finally {

        Clear-SecretSecurityMessage

        try {
            [Console]::CursorVisible =
                $oldCursorVisible
        }
        catch {}
    }
}


# ================================================================
# COMANDOS SECRET / BYPASS
# ================================================================

function Invoke-SecretHand {

    if ($script:SecretAnimationActive) {

        Write-Warning "Secret Hand ja esta ativo."
        return
    }

    $script:SecretAnimationActive = $true

    try {

        Show-SecretHandAnimation
    }
    finally {

        $script:SecretAnimationActive = $false
    }
}


function Enable-SecretBypass {

    $env:PSH_PROFILE_BYPASS = "1"

    $script:SecretBypass = $true
    $script:SecretBypassReason = "env PSH_PROFILE_BYPASS (manual)"


    if ($script:SecretShowChord) {

        try {

            Remove-PSReadLineKeyHandler `
                -Chord $script:SecretShowChord `
                -ErrorAction SilentlyContinue
        }
        catch {}
    }

    $script:SecretHandlersInstalled = $false

    Write-Host `
        "Secret Hand BYPASS ativo. Lock desativado." `
        -ForegroundColor Yellow

    Write-Host `
        "  Rode 'secret' p/ lock manual; 'secret-off' para voltar." `
        -ForegroundColor DarkGray
}


function Disable-SecretBypass {

    Remove-Item Env:PSH_PROFILE_BYPASS -ErrorAction SilentlyContinue

    $script:SecretBypass = $false
    $script:SecretBypassReason = $null

    Set-SecretKeyHandlers

    Write-Host `
        "Secret Hand reativado." `
        -ForegroundColor Green
}


function Get-SecretBypassStatus {

    if ($script:SecretBypass) {

        Write-Host `
            "Bypass ATIVO ($script:SecretBypassReason)" `
            -ForegroundColor Yellow
    }
    else {

        Write-Host `
            "Bypass INATIVO — Secret Hand ativo." `
            -ForegroundColor Green
    }

    Write-Host `
        "  Sair   : $(Get-SecretChord $script:SecretConfig.ExitKey)" `
        -ForegroundColor DarkGray

    Write-Host `
        "  Exibir : $(Get-SecretChord $script:SecretConfig.ShowKey)" `
        -ForegroundColor DarkGray

    Write-Host `
        "  So a sessao: $env:PSH_PROFILE_BYPASS = '1' (evite setx global)" `
        -ForegroundColor DarkGray
}


# ================================================================
# PSREADLINE HANDLER
# ================================================================

function Set-SecretKeyHandlers {

    if ($script:SecretBypass) {
        $script:SecretHandlersInstalled = $false
        return
    }


    if (
        $script:SecretHandlersInstalled -and
        $script:SecretShowChord
    ) {

        try {

            Remove-PSReadLineKeyHandler `
                -Chord $script:SecretShowChord `
                -ErrorAction SilentlyContinue
        }
        catch {}
    }


    $script:SecretExitChord =
        Get-SecretChord `
            $script:SecretConfig.ExitKey


    $script:SecretShowChord =
        Get-SecretChord `
            $script:SecretConfig.ShowKey


    if (
        Get-Command `
            Set-PSReadLineKeyHandler `
            -ErrorAction SilentlyContinue
    ) {

        Set-PSReadLineKeyHandler `
            -Chord $script:SecretShowChord `
            -ScriptBlock {

                if (-not $script:SecretAnimationActive) {

                    $script:SecretAnimationActive = $true

                    try {

                        Show-SecretHandAnimation
                    }
                    finally {

                        $script:SecretAnimationActive = $false
                    }
                }
            }


        $script:SecretHandlersInstalled = $true
    }
}


# ================================================================
# SET-SECRET
# ================================================================

function Set-Secret {

    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ExitKey,

        [Parameter(Mandatory=$false, Position=1)]
        [string]$ShowKey
    )


    try {

        $exitInfo =
            Get-SecretKeyInfo $ExitKey


        if (
            [string]::IsNullOrWhiteSpace($ShowKey)
        ) {

            $ShowKey =
                $exitInfo.Name
        }


        $showInfo =
            Get-SecretKeyInfo $ShowKey


        $script:SecretConfig = @{

            ExitKey =
                $exitInfo.Name

            ShowKey =
                $showInfo.Name
        }


        Save-SecretConfig `
            -ExitKey $script:SecretConfig.ExitKey `
            -ShowKey $script:SecretConfig.ShowKey


        Set-SecretKeyHandlers


        Write-Host ""

        Write-Host `
            "Secret keys atualizadas!" `
            -ForegroundColor Green

        Write-Host `
            "  Sair    : $(Get-SecretChord $script:SecretConfig.ExitKey)" `
            -ForegroundColor Cyan

        Write-Host `
            "  Exibir  : $(Get-SecretChord $script:SecretConfig.ShowKey)" `
            -ForegroundColor Yellow

        Write-Host `
            "  Arquivo : $script:SecretConfigPath" `
            -ForegroundColor DarkGray
    }
    catch {

        Write-Error $_.Exception.Message
    }
}


Set-Alias `
    -Name set-secret `
    -Value Set-Secret `
    -Force


# ================================================================
# HELP
# ================================================================

function help-profile {

    Clear-Host


    Write-Host `
        "==================================================================" `
        -ForegroundColor Cyan

    Write-Host `
        "              * POWERSHELL PROFILE TOOLBOX * " `
        -ForegroundColor Yellow `
        -Bold

    Write-Host `
        "==================================================================" `
        -ForegroundColor Cyan


    Write-Host `
        " Digite qualquer um dos comandos ou atalhos abaixo para utiliza-los:`n" `
        -ForegroundColor Gray


    Write-Host `
        " [ NAVEGACAO E UTILS ]" `
        -ForegroundColor Cyan `
        -Bold

    Write-Host `
        "   g, goto [loc]   " `
        -NoNewline

    Write-Host `
        "-> Navega para pastas mapeadas (ex: 'g avnt'). Raiz: $HOME." `
        -ForegroundColor Gray


    Write-Host `
        "   reload          " `
        -NoNewline

    Write-Host `
        "-> Recarrega as configuracoes do terminal." `
        -ForegroundColor Gray


    Write-Host `
        "   profile         " `
        -NoNewline

    Write-Host `
        "-> Abre o profile no VS Code." `
        -ForegroundColor Gray


    if ($script:HasKubectl) {

        Write-Host `
            "`n [ KUBERNETES E CLOUD ]" `
            -ForegroundColor Cyan `
            -Bold

        Write-Host `
            "   k [cmd]         " `
            -NoNewline

        Write-Host `
            "-> Atalho rapido para kubectl." `
            -ForegroundColor Gray

        Write-Host `
            "   kn [namespace]  " `
            -NoNewline

        Write-Host `
            "-> Troca o namespace atual." `
            -ForegroundColor Gray
    }


    Write-Host `
        "`n [ DESENVOLVIMENTO E LIMPEZA ]" `
        -ForegroundColor Cyan `
        -Bold


    Write-Host `
        "   clear-modules   " `
        -NoNewline

    Write-Host `
        "-> Apaga recursivamente node_modules." `
        -ForegroundColor Gray


    Write-Host `
        "   gl              " `
        -NoNewline

    Write-Host `
        "-> Exibe o Git log visual." `
        -ForegroundColor Gray


    if (
        $script:HasAndroidStudio -or
        $script:HasPyCharm -or
        $script:HasWebStorm
    ) {

        Write-Host `
            "`n [ IDEs ]" `
            -ForegroundColor Cyan `
            -Bold


        if ($script:HasAndroidStudio) {

            Write-Host `
                "   as              " `
                -NoNewline

            Write-Host `
                "-> Abre o Android Studio." `
                -ForegroundColor Gray
        }


        if ($script:HasWebStorm) {

            Write-Host `
                "   ws              " `
                -NoNewline

            Write-Host `
                "-> Abre o WebStorm." `
                -ForegroundColor Gray
        }


        if ($script:HasPyCharm) {

            Write-Host `
                "   pc              " `
                -NoNewline

            Write-Host `
                "-> Abre o PyCharm." `
                -ForegroundColor Gray
        }
    }


    Write-Host `
        "`n [ REDE E DIAGNOSTICO ]" `
        -ForegroundColor Cyan `
        -Bold


    Write-Host `
        "   myip            " `
        -NoNewline

    Write-Host `
        "-> IP local e publico." `
        -ForegroundColor Gray


    Write-Host `
        "   ports           " `
        -NoNewline

    Write-Host `
        "-> Portas TCP ouvindo." `
        -ForegroundColor Gray


    # ==========================================
    # SECRET HAND
    # ==========================================

    Write-Host `
        "`n [ SECRET HAND ]" `
        -ForegroundColor Cyan `
        -Bold


    Write-Host `
        "   Exibir          " `
        -NoNewline

    Write-Host `
        "-> $(Get-SecretChord $script:SecretConfig.ShowKey)" `
        -ForegroundColor Yellow


    Write-Host `
        "   Sair            " `
        -NoNewline

    Write-Host `
        "-> $(Get-SecretChord $script:SecretConfig.ExitKey)" `
        -ForegroundColor Green


    Write-Host `
        "   set-secret J H  " `
        -NoNewline

    Write-Host `
        "-> Configura novas teclas." `
        -ForegroundColor Gray


    Write-Host `
        "   Protecao        " `
        -NoNewline

    Write-Host `
        "-> 3 erros = bloqueio de 15 segundos." `
        -ForegroundColor DarkGray


    Write-Host `
        "   secret          " `
        -NoNewline

    Write-Host `
        "-> Roda o lock manualmente (mesmo com bypass)." `
        -ForegroundColor Gray


    Write-Host `
        "   secret-status   " `
        -NoNewline

    Write-Host `
        "-> Mostra estado do bypass e teclas atuais." `
        -ForegroundColor Gray


    Write-Host `
        "   secret-on/off   " `
        -NoNewline

    Write-Host `
        "-> Liga/desliga o bypass p/ agentes (env.)." `
        -ForegroundColor Gray


    # ==========================================
    # MISSING TOOLS
    # ==========================================

    $missing = @()


    if (-not $script:HasKubectl) {
        $missing += "   kubectl        -> install-kubectl"
    }

    if (-not $script:HasAndroidStudio) {
        $missing += "   Android Studio -> install-android-studio"
    }

    if (-not $script:HasPyCharm) {
        $missing += "   PyCharm        -> install-pycharm"
    }

    if (-not $script:HasWebStorm) {
        $missing += "   WebStorm       -> install-webstorm"
    }


    if ($missing.Count -gt 0) {

        Write-Host `
            "`n [ FERRAMENTAS NAO INSTALADAS ]" `
            -ForegroundColor Red `
            -Bold

        $missing |
            ForEach-Object {
                Write-Host `
                    $_ `
                    -ForegroundColor DarkYellow
            }


        Write-Host `
            "   (ou rode 'install-missing' para instalar tudo de uma vez)" `
            -ForegroundColor DarkGray
    }


    Write-Host `
        "`n==================================================================" `
        -ForegroundColor Cyan


    Write-Host `
        " DICA: use " `
        -NoNewline

    Write-Host `
        "h" `
        -ForegroundColor Yellow `
        -NoNewline

    Write-Host `
        " ou " `
        -NoNewline

    Write-Host `
        "help-profile" `
        -ForegroundColor Yellow


    Write-Host `
        "==================================================================" `
        -ForegroundColor Cyan
}


# ================================================================
# ALIASES DO SECRET HAND
# ================================================================

Set-Alias secret Invoke-SecretHand -Force
Set-Alias secret-on Enable-SecretBypass -Force
Set-Alias secret-off Disable-SecretBypass -Force
Set-Alias secret-status Get-SecretBypassStatus -Force


# ================================================================
# INSTALA HANDLERS
# ================================================================

Set-SecretKeyHandlers


# ================================================================
# PRIMEIRA EXECUCAO DA SESSAO
# ================================================================

$script:SecretAnimationActive = $true

try {

    if ($script:SecretBypass) {

        $interactiveHuman =
            [Environment]::UserInteractive -and
            -not [Console]::IsInputRedirected

        $startupArgs = [Environment]::GetCommandLineArgs()

        foreach ($flag in @('-Command','-File','-EncodedCommand')) {

            if ($startupArgs -contains $flag) {
                $interactiveHuman = $false
                break
            }
        }

        if ($interactiveHuman -and $env:PSH_PROFILE_BYPASS) {

            Write-Host `
                "Secret Hand desativado (bypass)." `
                -ForegroundColor DarkGray

            Write-Host `
                "  Rode 'secret' p/ lock manual ou 'secret-off' p/ reativar." `
                -ForegroundColor DarkGray
        }

        # Em contextos de agente/script o bypass e silencioso,
        # para nao poluir a saida das IAs.
    }
    else {

        Show-SecretHandAnimation
    }
}
finally {

    $script:SecretAnimationActive = $false
}

# >>> setup_claude global command >>>
# Gerado automaticamente por thero.py --install-command
# Nao edite manualmente entre estes marcadores; rode novamente
# "python thero.py --install-command" para atualizar.
function thero {
    param(
        [Parameter(Position = 0)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    $scriptPath = 'C:\Users\anthe\.myscripts\thero\thero.py'

    $flagMap = @{
        'install'    = @()
        'skills'     = @('--skills-only')
        'merge'      = @('--merge-only')
        'audit'      = @('--audit')
        'audit-only' = @('--audit-only')
        'index'      = @('--index')
        'check'      = @('--check')
        'update'     = @('--update')
        'help'       = @('--help')
    }

    if ([string]::IsNullOrEmpty($Command)) {
        $flags = @()
    }
    elseif ($flagMap.ContainsKey($Command)) {
        $flags = $flagMap[$Command]
    }
    else {
        # Argumento desconhecido: repassa cru para o script
        # (ex.: --skills-only, -h).
        $flags = @($Command) + $Rest
        $Rest = @()
    }

    python $scriptPath @flags @Rest
}
# <<< setup_claude global command <<<
