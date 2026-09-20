# Genesis — setup pós-formatação do Windows 11

O **Genesis** é o planeta-matriz do ecossistema
[Theroverse](https://theroverse.github.io/): *"O Berço da Criação & Matriz
do Universo"* — a fundação que terraforma o solo estéril de um Windows 11
recém-formatado, instalando terminal, navegadores, jogos e a suíte completa
de Claude Code (thero, Athena, Zeus) antes que você perca o sábado caçando
instalador em anúncio patrocinado.

Referência completa do projeto: o que existe, pra que serve, e todos os
comandos. Leia isto antes de formatar de novo ou de mexer em qualquer
coisa — não precisa abrir cada arquivo pra lembrar como funciona.

**Baixar sem compilar**: [Releases](https://github.com/theroverse/genesis/releases)
— pegue o `Genesis.exe` da versão mais recente.

## Comandos rápidos

```powershell
cd C:\Users\anthe\.myscripts\genesis

# gerar/regerar o Genesis.exe (sempre que mudar algo que ele embute:
# modules/, config/, gui/, raycast-installer.exe)
.\build.ps1

# rodar o instalador de verdade (com janela, WebView2)
.\dist\Genesis.exe

# testar a interface SEM instalar nada (abre no navegador, dados de exemplo)
.\gui\wizard\dev.ps1

# rodar sem janela, so console (util pra debugar um modulo)
.\genesis.ps1

# atualizar versao/data/site de cada app do catalogo (winget real)
.\scripts\fetch-app-metadata.ps1
# baixar os icones (favicons reais) de cada app do catalogo
.\scripts\fetch-app-icons.ps1
```

## Build, versionar e publicar um release

```powershell
# 1) gera dist\Genesis.exe (payload + compilacao ps2exe)
.\build.ps1

# 2) commit + tag semver (vX.Y.Z)
git add -A
git commit -m "..."
git tag v1.0.0

# 3) push do codigo e da tag
git push origin main --tags

# 4) release no GitHub com o exe anexado como asset baixavel
gh release create v1.0.0 dist\Genesis.exe `
  --title "Genesis v1.0.0" `
  --notes "..."
```

`gh release create` precisa do GitHub CLI autenticado (`gh auth status`) e do
remote `origin` apontando pro repositorio certo. O `Genesis.exe` sobe como
**asset da release**, nao fica commitado no repo (`dist/` e gitignored) -
quem quiser baixar direto sem compilar pega o `.exe` na pagina de releases.

`Genesis.exe` e `genesis.ps1` pedem UAC sozinhos e rodam a mesma lógica
(`modules/Pipeline.ps1`) — só muda a interface. `Genesis.exe` é uma
janela nativa (WinForms) hospedando um controle **WebView2** que carrega
`gui/wizard/index.html` — a interface é HTML/CSS/JS de verdade, não
WinForms puro.

## O `Genesis.exe` é um arquivo único

Não precisa carregar pasta nenhuma junto: `modules/`, `config/`,
`gui/wizard/`, `gui/webview2/` e o
`raycast-installer.exe` **entram embutidos** no exe, num payload comprimido
(zip → gzip → base64) gerado por `scripts/build-payload.ps1`. Na primeira
execução o `gui/GenesisBootstrap.ps1` descompacta isso em
`%LOCALAPPDATA%\Genesis\app\<versão>` e roda dali; as próximas aberturas
reaproveitam o cache. A "versão" é o hash do próprio payload, então
recompilar o exe extrai uma pasta nova — as antigas são descartadas, mas os
`logs/` da anterior são preservados.

- **Copiar só o `.exe` pra qualquer pasta funciona** (pendrive, Desktop, `C:\`).
- **Overrides opcionais ao lado do exe**: se houver `config\*.json`,
  `presetup.json` ou `raycast-installer.exe` na mesma pasta do `Genesis.exe`,
  eles ganham dos defaults embutidos — dá pra ajustar config e atualizar o
  Raycast sem recompilar nada.
- **Rodar da pasta do projeto continua igual**: sem payload, `$Root` é a
  própria pasta (`.\genesis.ps1` no console, `.\gui\WizardHost.ps1` com
  janela). `.build/` e `Genesis.exe` são gerados e não versionados.

## Inventário — o que existe e pra que serve

```
genesis/
├── dist/                         <- GERADO por build.ps1: Genesis.exe final, isolado das fontes - NAO versionado. Rodar direto.
│   └── Genesis.exe               <- arquivo unico: nao precisa de mais nada ao lado
├── genesis.ps1                   <- orquestrador em modo console
├── build.ps1                     <- monta o payload + compila tudo num dist/Genesis.exe unico
├── .build/                       <- GERADO pelo build.ps1: payload.ps1 (assets) + Genesis.ps1 (script unico) - gitignored
├── PRODUCT.md / DESIGN.md        <- contexto de produto e sistema visual (skill impeccable)
├── Microsoft.PowerShell_profile.ps1  <- seu profile do PowerShell, copiado pro $PROFILE
├── raycast-installer.exe         <- instalador oficial do Raycast
├── ninite-downloader.exe         <- NAO USADO MAIS (apps foram pro winget) - pode apagar
├── prompt.txt                    <- rascunho original - so historico
│
├── gui/
│   ├── WizardHost.ps1             <- shell nativo: janela sem borda + WebView2 + ponte JS<->PowerShell
│   ├── GenesisBootstrap.ps1       <- extrai o payload embutido em %LOCALAPPDATA%\Genesis\app\<versao> (arquivo unico)
│   ├── webview2/                  <- DLLs do WebView2 (Core + WinForms), vindas do NuGet - vao embutidas no exe
│   └── wizard/                    <- a interface inteira (HTML/CSS/JS)
│       ├── index.html
│       ├── style.css              <- sistema visual: navy escuro + gradiente violeta (cor propria do Genesis - genesis-icon-app.svg / ecosystem.ts do theroverse)
│       ├── app.js                 <- toda a logica de telas, catalogo, textos, bridge
│       ├── dev.ps1                <- abre index.html no navegador em modo preview (mock, nao instala nada)
│       └── assets/                <- icones reais (favicons) + assets do thero (mark/screenshot)
│
├── scripts/                       <- ferramentas de desenvolvimento, NAO entram no payload
│   ├── build-payload.ps1          <- junta tudo que o exe precisa num payload comprimido (.build/payload.ps1)
│   ├── fetch-app-metadata.ps1     <- consulta `winget show` de cada app e grava versao/data/site real em winget-apps.json
│   └── fetch-app-icons.ps1        <- baixa o favicon real de cada app (via site do Google) pra gui/wizard/assets/icons/
│
├── modules/                      <- toda a logica de instalacao, um arquivo por responsabilidade
│   ├── Common.ps1                <- Write-Step/Write-Ok/Write-Warn2/Write-Err2/Invoke-Step + hooks pra GUI
│   ├── Pipeline.ps1               <- lista TODAS as etapas, em ordem - fonte unica pra console e GUI
│   ├── Ensure-Winget.ps1          <- instala o App Installer (winget) na mao se nao existir
│   ├── New-GenesisRestorePoint.ps1  <- cria ponto de restauracao do Windows antes de tudo
│   ├── Set-ExecutionPolicyBypass.ps1
│   ├── Enable-WSLFeatures.ps1     <- habilita WSL2 / VirtualMachinePlatform (pode pedir reboot)
│   ├── Install-WingetApps.ps1     <- instala o que foi selecionado (ou todo "default":true, no modo console)
│   ├── Setup-GitHubSsh.ps1        <- gera chave SSH + gh auth login + cadastra a chave no GitHub
│   ├── Setup-Projects.ps1         <- cria a pasta de projetos (config/projects-folder.json, default ~/projects) e clona tudo de config/projects.json
│   ├── Invoke-Raycast.ps1
│   ├── Install-ClaudeCode.ps1
│   ├── Install-WinUtil.ps1        <- baixa o WinUtil (Chris Titus Tech) pra Area de Trabalho
│   ├── Setup-PowerShellProfile.ps1  <- copia o profile pro $PROFILE; se a pasta de projetos foi informada, reescreve o `$project_path = $HOME` do `goto`/`g` pra esse caminho
│   ├── Install-TheroGlobal.ps1    <- roda `python thero.py` pra instalar skills + CLAUDE.md + comando `thero`
│   ├── Set-DefaultBrowserAndSearch.ps1
│   ├── Setup-SearchRedirect.ps1   <- MSEdgeRedirect (Search/Widgets/News abrirem no navegador padrao)
│   ├── Setup-Bluetooth.ps1
│   ├── Setup-HomeAssistant.ps1    <- registra/liga a VM existente no VirtualBox
│   ├── Register-WingetUpgradeTask.ps1
│   └── Enable-Autologin.ps1       <- off por padrao em tasks.json
│
├── docs/
│   └── design-assets-prompts.md  <- prompts pra regerar o icone do .exe / assets visuais (opcional)
│
└── config/
    ├── tasks.json                <- liga/desliga cada etapa
    ├── winget-apps.json          <- catalogo de apps: id, label, categoria, default, e (via scripts/fetch-*) version/updated/homepage
    ├── projects.json             <- repositorios a clonar
    ├── projects-folder.json      <- onde clonar ({"path": "..."}) - tambem reescreve o `goto`/`g` do profile
    ├── backup-folders.json
    └── home-assistant-vm.json
```

## A interface (wizard)

`Genesis.exe` abre uma janela sem moldura própria (título/minimizar/fechar
desenhados em HTML) que carrega `gui/wizard/index.html` num controle
WebView2. O fluxo:

1. **Bem-vindo** e **Sobre o autor** (com link pro portfólio/GitHub).
2. **Catálogo de apps** — grade do catálogo (`config/winget-apps.json`)
   **agrupada por categoria** (seções com cabeçalho, não só filtro por
   chip), com o ícone real do app (favicon oficial), nome, versão e data
   de lançamento reais, descrição curta em português, e um card
   clicável pra marcar/desmarcar. Chips de categoria mostram
   `marcados/total` (ex: "Navegadores 2/5"). Apps **já instalados na
   máquina** (detectado via `winget list` em background) vêm marcados e
   **travados** — não dá pra desmarcar um app que já está aí.
3. **Adicionar mais apps** — busca ao vivo contra a
   [API pública do winget.run](https://docs.winget.run) (nome, ícone,
   descrição e homepage reais, sem depender de raspar texto de `winget
   show`), com resultado incremental enquanto digita.
4. **Etapas do sistema** — os toggles de `config/tasks.json`, agrupados
   (Sistema, Contas & Projetos, Ferramentas, Navegador & Rede, Casa &
   Avançado).
5. **Theroverse** (thero, Athena, Zeus) — só aparece se "Claude Code"
   estiver marcado na tela de etapas. Uma tela só, reproduzindo a seção
   "Escolha uma Entidade & Salte Através do Portal" do próprio
   [theroverse.github.io](https://theroverse.github.io/): grade de cards
   com o mesmo texto (tagline/heroSubheadline/punchline) e cor/glifo
   reais de cada ferramenta (`theroverse/src/data/ecosystem.ts` +
   `EcosystemIcon.tsx`, portado 1:1 pro SVG do `app.js`). thero é a única
   escolha real — em vez de checkbox, um **glow animado** na cor dele
   indica que vai instalar; o botão **"Pular"** (ao lado do "Voltar") é
   quem desliga, em vez de desmarcar o card. Athena/Zeus são sempre
   automáticos junto do thero (dependem dele), só avisam por quê.
6. **Revisão** — resumo, Home Assistant (`.vdi` ou container Docker), a
   **pasta de projetos** (de onde vem o `~/projects` e a base que o
   comando `g`/`goto` do profile passa a usar em vez do `$HOME`
   hardcoded — aceita caminho que ainda não existe, ele é criado ao
   avançar; falha de criação mostra um dialog de erro e devolve o foco
   pro campo) e a lista de repositórios a clonar.
7. **Instalação** (progresso ao vivo) — nessa etapa aparece o botão
   **"Minimizar para o tray"** (ao lado do "Voltar"): esconde a janela e
   mostra um ícone na bandeja do Windows; quando a instalação termina, a
   janela volta sozinha. Fechar pelo **X** da titlebar sempre pede
   confirmação (o "Fechar" do fim do fluxo, não).
8. **Concluído** (botões pra abrir os apps recém-instalados).

Testar sem instalar nada: `.\gui\wizard\dev.ps1` abre a página direto num
navegador comum. O `app.js` detecta que não está dentro do WebView2
(`window.chrome.webview` não existe) e usa dados de exemplo + uma
instalação simulada — nenhum comando real roda.

**Manter o catálogo de apps atualizado**: rode `scripts/fetch-app-metadata.ps1`
(versão/data real via `winget show`) e `scripts/fetch-app-icons.ps1`
(favicon real via o site do Google) sempre que adicionar/remover um app
de `config/winget-apps.json` — sem isso a tela dele fica sem ícone/versão.

## Estado atual dos configs (snapshot)

**`config/tasks.json`** — tudo ligado, exceto Autologin:
```json
{
  "RestorePoint": true, "ExecutionPolicy": true, "EnableWSL": true,
  "WingetApps": true, "GitHubSsh": true, "Projects": true,
  "Raycast": true, "ClaudeCode": true, "WinUtil": true,
  "PowerShellProfile": true, "TheroGlobal": true,
  "DefaultBrowserAndSearch": true, "SearchRedirect": true, "Bluetooth": true,
  "HomeAssistant": true, "WingetUpgradeTask": true, "Autologin": false
}
```

**`config/winget-apps.json`** — 70 apps reais em 12 categorias (Terminal
& Sistema, Navegadores, Comunicação, Produtividade, Mídia, Streaming,
Desenvolvimento, Infraestrutura & Virtualização, Utilitários, Torrent,
Acesso Remoto, Jogos). Desligados por padrão: Firefox, Opera, Windhawk,
LibreOffice, ONLYOFFICE, Telegram, Insomnia, Yarn, DevToys, Rufus,
SumatraPDF, Popcorn Time, AnyDesk, TeamViewer, Steam, Epic Games Launcher,
Battle.net, EA App, CurseForge, Thunderstore (r2modman), Transmission,
Deluge, Amazon Prime Video. Tudo o mais vem marcado.

**`config/projects.json`**: `myscripts` (traz `thero`/`athena`/`zeus` juntos
via `--recurse-submodules`), `hunteradeck` (pasta local `huntera-launcher`),
`nexo`, `onplay-m3u`. *(`sv` ficou de fora: sem remote configurado.)*

**`config/home-assistant-vm.json`**: aponta pra `D:\HomeAssistantOS\haos_ova-18.2.vdi`, 2048MB/2 CPUs, porta 8123.

## Etapas, em ordem (o que `Invoke-GenesisPipeline` roda)

1. Ponto de restauração do Windows
2. Execution Policy -> Bypass
3. Habilitar WSL2 / VirtualMachinePlatform (pode pedir reboot)
4. Apps via winget (seleção feita na wizard, ou todo `"default":true` no modo console)
5. Chave SSH + `gh auth login` (único passo com interação: confirmar no navegador)
6. Pasta `~/projects` + clone dos repositórios
7. Raycast
8. Claude Code
9. WinUtil (baixa pra Área de Trabalho, não roda — é interativo)
10. Profile do PowerShell
11. thero — instalação global (só se "Claude Code" estiver marcado)
12. Chrome como navegador/buscador padrão
13. Windows Search abrir no navegador padrão (MSEdgeRedirect)
14. Bluetooth auto-reconnect
15. Home Assistant — sobe a VM existente no VirtualBox
16. Tarefa agendada semanal: `winget upgrade --all`
17. Autologin (off por padrão)

## Depois de rodar (checklist manual)

- **Reboot**: se o resumo final avisar, reinicie antes de usar WSL/Docker/Ubuntu/VirtualBox.
- **`gh auth login`**: confirme no navegador se pedir — sem isso a chave SSH não fica registrada no GitHub.
- **Bluetooth**: pareie cada dispositivo uma vez (Config > Bluetooth); depois reconecta sozinho.
- **Home Assistant**: confira `http://localhost:8123` — é a VM antiga subindo de novo.
- **Autologin**: fica de fora por padrão — mude `tasks.json` se quiser ligar.
- **Ícone do .exe**: já resolvido — `Genesis.exe` usa `gui/Genesis.ico`, gerado por `scripts/make-exe-icon.ps1` a partir de `genesis-icon-app-512x512.png` (o `build.ps1` chama o script sozinho se o `.ico` estiver faltando). Ver `docs/design-assets-prompts.md` §1 pra regerar/trocar a arte.

## Manutenção / instruções futuras

- **Adicionar um app do winget**: acrescente `{ "id", "label", "category", "default" }` em `config/winget-apps.json`, depois rode `scripts\fetch-app-metadata.ps1` e `scripts\fetch-app-icons.ps1` pra preencher versão/data/ícone real.
- **Adicionar um repositório**: incluir a URL em `config/projects.json`.
- **Ligar/desligar uma etapa**: editar o `true`/`false` em `config/tasks.json`.
- **Trocar o Raycast**: gerar um novo `.exe` no site oficial e substituir o arquivo.
- **K-Lite Codec Pack**: instalando a edição Standard; troque por `.Basic`, `.Full` ou `.Mega` se quiser outra.
- **Trocar a VM do Home Assistant**: só editar `config/home-assistant-vm.json`.
- **Adicionar uma etapa nova**: criar o módulo em `modules/`, registrar em `Get-GenesisStepDefinitions` e `Invoke-GenesisPipeline` (`modules/Pipeline.ps1`) — os dois front-ends pegam a mudança sozinhos.
- **Mudar a interface**: edite `gui/wizard/*` e teste na hora com `.\gui\wizard\dev.ps1` (abre no navegador, instala nada) ou com `.\gui\WizardHost.ps1` (janela real). Como agora o exe embute tudo, rode `.\build.ps1` de novo pra mudança valer no `Genesis.exe`.
- **Mudar o que entra no exe**: a lista de pastas/arquivos embutidos está em `scripts/build-payload.ps1` (`$includeDirs` / `$includeFiles`) — mudou lá, rode `.\build.ps1`.
- **Validar sintaxe de tudo sem rodar nada**:
  ```powershell
  Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object {
      $e = $null
      [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e) | Out-Null
      if ($e) { Write-Host "ERRO em $($_.Name)" -ForegroundColor Red; $e }
  }
  ```

## Limitações conhecidas (sem solução scriptável confiável)

- **Pareamento inicial de Bluetooth**: precisa de confirmação/PIN na tela pelo menos uma vez por dispositivo.
- **MSEdgeRedirect**: depende de scraping/API de terceiros. Se a página mudar, o script para com erro claro em vez de instalar algo errado.
- **`gh auth login`**: precisa de confirmação no navegador — não dá pra automatizar sem guardar senha/token no disco.
- **Backup automático** (OneDrive/Backblaze): avaliado e descartado — KFM silencioso do OneDrive só funciona em conta corporativa; numa pessoal sempre pede login manual.
- **Descrições dos apps**: escritas à mão em `gui/wizard/app.js` (`APP_DESCRIPTIONS`) — winget só tem texto em inglês, de tamanho/tom muito inconsistente entre fornecedores, pra usar direto numa interface em português.
- **`api.winget.run`**: serviço comunitário (não oficial da Microsoft) — se sair do ar, a busca em "Adicionar mais apps" volta vazia (sem crash; o catálogo principal, que não depende dele, continua funcionando normal).

## Coisas que talvez valha a pena adicionar (não incluídas ainda)

- **dotfiles / configs de outros apps** (VS Code settings.json, extensões, Windows Terminal settings.json) — só o profile do PowerShell é restaurado hoje.
- **Hosts/DNS** (ex.: DNS específico, Tailscale MagicDNS) se você usa isso entre máquinas.
