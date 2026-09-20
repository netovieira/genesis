// Wizard engine. Runs two ways:
//   - Real: hosted inside gui/WizardHost.ps1's WebView2 control. Talks to
//     PowerShell via window.chrome.webview.postMessage / addEventListener.
//   - Preview: opened directly in a normal browser (e.g. for visual work
//     on this file) - falls back to MOCK_CONFIG and a simulated install
//     run below, so every screen renders without a live backend.
'use strict';

const ICON_CHECK = '<svg viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.2 11.7L13 4.5" stroke="#06111f" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const ICON_SPARKLE = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2z"/></svg>';

const CATEGORY_COLORS = {
  'Terminal & Sistema': '#22d3ee',
  'Navegadores': '#8b5cf6',
  'Comunicacao & Produtividade': '#2dd9b9',
  'Midia': '#fbbf5b',
  'Streaming': '#f472b6',
  'Desenvolvimento': '#60a5fa',
  'Infraestrutura & Virtualizacao': '#a78bfa',
  'Utilitarios': '#94a3b8',
  'Torrent': '#38bdf8',
  'Acesso Remoto': '#fb923c',
  'Jogos': '#f87171',
};

const CATEGORY_LABELS = {
  'Terminal & Sistema': 'Terminal & Sistema',
  'Navegadores': 'Navegadores',
  'Comunicacao & Produtividade': 'Comunicação & Produtividade',
  'Midia': 'Mídia',
  'Streaming': 'Streaming',
  'Desenvolvimento': 'Desenvolvimento',
  'Infraestrutura & Virtualizacao': 'Infraestrutura & Virtualização',
  'Utilitarios': 'Utilitários',
  'Torrent': 'Torrent',
  'Acesso Remoto': 'Acesso Remoto',
  'Jogos': 'Jogos',
};

// Short PT-BR one-liners, hand-written (winget's own descriptions are
// English marketing copy of wildly inconsistent length per vendor - wrong
// tone/language for this wizard). Version/updated date, by contrast, ARE
// real winget data (see scripts/fetch-app-metadata.ps1).
const APP_DESCRIPTIONS = {
  'Starship.Starship': 'Prompt de terminal rápido e customizável, com o mesmo visual em qualquer shell.',
  'Microsoft.PowerToys': 'Utilitários oficiais da Microsoft: FancyZones, PowerToys Run, redimensionar imagens e mais.',
  'UnifiedIntents.UnifiedRemote': 'Transforma o celular num controle remoto pro PC — mouse, teclado, mídia.',
  'RamenSoftware.Windhawk': 'Loja de mods pra customizar o visual e comportamento do Windows.',
  'Google.Chrome': 'Navegador mais usado do mundo, rápido e com a maior base de extensões.',
  'Mozilla.Firefox': 'Navegador open-source focado em privacidade, mantido pela Mozilla.',
  'Opera.Opera': 'Navegador com VPN grátis embutida e painéis de redes sociais integrados.',
  '9NBDXK71NK08': 'Cliente oficial do WhatsApp pra Windows, sincronizado com o celular.',
  'Discord.Discord': 'Chat de voz, vídeo e texto usado por comunidades e times de jogos.',
  'Notion.Notion': 'Workspace tudo-em-um pra notas, documentos e organização de projetos.',
  'Obsidian.Obsidian': 'Base de conhecimento em Markdown local, conectando notas por links.',
  'Microsoft.Office': 'Word, Excel, PowerPoint e Outlook — suíte de produtividade da Microsoft.',
  'TheDocumentFoundation.LibreOffice': 'Suíte de escritório gratuita e open-source, compatível com arquivos do Office.',
  'ONLYOFFICE.DesktopEditors': 'Alternativa gratuita ao Office com altíssima fidelidade ao formato .docx/.xlsx/.pptx.',
  'Telegram.TelegramDesktop': 'Mensagens rápidas com histórico sincronizado em nuvem entre todos os dispositivos.',
  'Spotify.Spotify': 'Streaming de música e podcast, com playlists e recomendações.',
  'Apple.iTunes': 'Player de mídia da Apple — sincroniza música e faz backup de iPhone.',
  'CodecGuide.K-LiteCodecPack.Standard': 'Pacote de codecs pra tocar qualquer formato de vídeo e áudio no Windows.',
  'OBSProject.OBSStudio': 'Gravação e transmissão ao vivo gratuita e open-source — o padrão pra streaming.',
  '9WZDNCRFJ3TJ': 'App oficial da Netflix — séries e filmes direto no Windows.',
  '9P6RC76MSMMJ': 'App oficial do Prime Video pra assistir o catálogo da Amazon.',
  'Stremio.Stremio': 'Central de streaming com add-ons — organiza filmes/séries de várias fontes num só player.',
  'PopcornTime.Popcorn-Time': 'Streaming via torrent direto no player, sem baixar o arquivo inteiro antes.',
  'OpenJS.NodeJS': 'Runtime JavaScript server-side — base de praticamente todo projeto web moderno.',
  'Git.Git': 'Controle de versão distribuído — a base de todo fluxo de trabalho com GitHub.',
  'GitHub.cli': 'Gerencia PRs, issues e repositórios do GitHub direto do terminal.',
  'Microsoft.VisualStudioCode': 'Editor de código mais usado atualmente, extensível pra qualquer linguagem.',
  'Python.Python.3.13': 'Linguagem de propósito geral — scripts, automação, dados e backend.',
  'Postman.Postman': 'Cliente de API pra testar e documentar endpoints REST/GraphQL.',
  'Insomnia.Insomnia': 'Alternativa ao Postman pra testar APIs REST, GraphQL e gRPC.',
  'pnpm.pnpm': 'Gerenciador de pacotes Node.js mais rápido e econômico em disco que o npm.',
  'Yarn.Yarn': 'Gerenciador de pacotes Node.js alternativo ao npm, mantido pela Meta.',
  'LeNgocKhoa.Laragon': 'Ambiente de dev local (Apache/Nginx, MySQL, PHP, Node) — sobe um projeto em minutos.',
  'Google.Antigravity': 'IDE agêntica do Google — codifica com IA operando o editor, terminal e navegador.',
  'DevToys-app.DevToys': 'Canivete suíço de dev: JSON, regex, base64, hash, diff e mais, tudo offline.',
  'Docker.DockerDesktop': 'Roda containers Docker no Windows — a base de ambientes de dev reproduzíveis.',
  'Oracle.VirtualBox': 'Virtualização gratuita — roda outro sistema operacional dentro de uma janela.',
  'Canonical.Ubuntu.2204': 'Distribuição Linux completa rodando nativamente dentro do Windows via WSL.',
  'Tailscale.Tailscale': 'VPN mesh que conecta seus dispositivos como se estivessem na mesma rede.',
  '7zip.7zip': 'Compactador de arquivos gratuito, abre praticamente qualquer formato.',
  'RevoUninstaller.RevoUninstaller': 'Desinstala programas por completo, limpando registro e arquivos que sobram.',
  'ShareX.ShareX': 'Captura de tela e gravação com anotação, upload automático incluso.',
  'Guru3D.Afterburner': 'Overclock e monitoramento de GPU — mostra FPS e temperatura em jogo.',
  'SumatraPDF.SumatraPDF': 'Leitor de PDF leve e rápido, abre também ePub e quadrinhos (CBZ/CBR).',
  'voidtools.Everything': 'Busca de arquivos instantânea no Windows inteiro — indexa e acha em milissegundos.',
  'Bitwarden.Bitwarden': 'Gerenciador de senhas gratuito e open-source, sincronizado entre todos os dispositivos.',
  'Rufus.Rufus': 'Cria pendrive bootável (Windows, Linux) de forma rápida e confiável.',
  'qBittorrent.qBittorrent': 'Cliente de torrent open-source, sem anúncios.',
  'Transmission.Transmission': 'Cliente de torrent minimalista e leve.',
  'DelugeTeam.Deluge': 'Cliente de torrent modular, roda como serviço em segundo plano.',
  'AnyDesk.AnyDesk': 'Acesso remoto rápido e leve pra suporte técnico ou uso do PC à distância.',
  'TeamViewer.TeamViewer': 'Acesso remoto completo, com transferência de arquivo e apresentação de tela.',
  'Valve.Steam': 'Loja e launcher de jogos mais usado no PC.',
  'EpicGames.EpicGamesLauncher': 'Launcher da Epic Games — dono do Fortnite e de jogos grátis semanais.',
  'Blizzard.BattleNet': 'Launcher da Blizzard — WoW, Overwatch, Diablo e Hearthstone.',
  'ElectronicArts.EADesktop': 'Launcher da EA — EA Sports FC, Battlefield e o catálogo do EA Play.',
  'Mojang.MinecraftLauncher': 'Launcher oficial do Minecraft.',
  'Overwolf.CurseForge': 'Gerenciador de mods pra Minecraft e outros jogos moderados pela comunidade.',
  'ebkr.r2modman': 'Gerenciador de mods do Thunderstore — Valheim, Lethal Company e outros.',
};

function iconFileName(id) { return id.replace(/[^A-Za-z0-9._-]/g, '_') + '.png'; }

const TASK_GROUPS = [
  {
    title: 'Sistema',
    keys: ['RestorePoint', 'ExecutionPolicy', 'EnableWSL', 'WingetUpgradeTask', 'AutoBackup'],
  },
  {
    title: 'Contas & Projetos',
    keys: ['GitHubSsh', 'Projects'],
  },
  {
    title: 'Ferramentas',
    keys: ['ClaudeCode', 'PowerShellProfile'],
  },
  {
    title: 'Navegador & Rede',
    keys: ['DefaultBrowserAndSearch', 'SearchRedirect', 'Bluetooth'],
  },
  {
    title: 'Casa & Avançado',
    keys: ['HomeAssistant', 'Autologin'],
  },
];

const TASK_META = {
  RestorePoint: { label: 'Ponto de restauração', desc: 'Cria um ponto de restauração do Windows antes de mexer em qualquer coisa.' },
  ExecutionPolicy: { label: 'Execution Policy → Bypass', desc: 'Libera scripts PowerShell (padrão do Windows bloqueia por segurança).' },
  EnableWSL: { label: 'WSL2 / Virtual Machine Platform', desc: 'Habilita os recursos que Docker, Ubuntu e WSL precisam. Pode pedir reboot.' },
  WingetUpgradeTask: { label: 'Atualização automática', desc: 'Cria uma tarefa agendada semanal: winget upgrade --all.' },
  AutoBackup: { label: 'Backup automático de pastas', desc: 'Cria uma tarefa diária que espelha cada pasta escolhida pra ~/Backups.' },
  GitHubSsh: { label: 'Chave SSH + login no GitHub', desc: 'Gera chave ed25519 e roda gh auth login (único passo que pede confirmação no navegador).' },
  Projects: { label: 'Clonar projetos', desc: 'Cria ~/projects e clona os repositórios configurados.' },
  ClaudeCode: { label: 'Claude Code', desc: 'Instala o Claude Code (irm https://claude.ai/install.ps1).' },
  PowerShellProfile: { label: 'Profile do PowerShell', desc: 'Restaura seu Microsoft.PowerShell_profile.ps1 pessoal.' },
  DefaultBrowserAndSearch: { label: 'Chrome como padrão', desc: 'Define Chrome como navegador padrão e Google como buscador.' },
  SearchRedirect: { label: 'Busca do Windows → navegador padrão', desc: 'Instala o MSEdgeRedirect pra Search/Widgets/News pararem de forçar o Edge.' },
  Bluetooth: { label: 'Bluetooth auto-reconnect', desc: 'Garante que dispositivos já pareados reconectem sozinhos.' },
  HomeAssistant: { label: 'Home Assistant', desc: 'VM existente ou um container Docker novo — escolha na Revisão.' },
  Autologin: { label: 'Autologin', desc: 'Configura login automático do Windows.', risk: true },
};

// Colors, icon and hero image are pulled straight from each project's own
// landing page (netovieira/thero, /athena, /zeus - src/styles.css'
// --primary token and src/assets/) so this screen reads as that app's own
// pitch, not a generic wizard panel wearing its name. Version/updated come
// from src/*/__init__.py and each repo's last commit date - real data, not
// invented copy.
const SUITE_CONTENT = {
  thero: {
    name: 'thero',
    color: '#F97316',
    colorSecondary: '#EA580C',
    colorAccent: '#FB923C',
    version: '0.1.0',
    updated: '18/09/2026',
    role: 'habitante',
    tagline: 'Configura seu Claude Code como se um time sênior tivesse revisado antes de você abrir o terminal.',
    // heroSubheadline/punchline: texto identico ao card do proprio
    // theroverse (theroverse/src/data/landingPages.ts) - mesma copia, nao
    // parafraseado.
    heroSubheadline: 'Configura o Claude Code com um Engineering Operating System enxuto, Agent Skills sob demanda e regras de conduta implacáveis antes de você digitar a primeira linha.',
    punchline: 'Impeça a IA de reescrever 500 linhas de código legado que já funcionavam só pra trocar por uma biblioteca experimental.',
    points: [
      'Você para de reexplicar o óbvio — regras de como você trabalha valem desde a primeira mensagem, em qualquer projeto.',
      'Conhecimento especializado sob demanda (React, Supabase, TypeScript, testes) como Agent Skills, só entram quando a tarefa precisa.',
      'Zero dependências além do Python e do próprio Claude Code. Nunca apaga nada seu — sempre faz backup antes de mudar algo.',
      'Parte de uma suíte: integra com Athena e Zeus, mas funciona sozinho também.',
    ],
    hasToggle: true,
    taskKey: 'TheroGlobal',
  },
  athena: {
    name: 'Athena',
    color: '#10B981',
    colorSecondary: '#059669',
    colorAccent: '#34D399',
    version: '0.1.0',
    updated: '18/09/2026',
    role: 'nave',
    tagline: 'A planta baixa do seu projeto para IA — contexto de arquitetura sem reler o repositório inteiro.',
    heroSubheadline: 'O radar de código que percorre seu repositório de baixo para cima, sintetizando arquivos e pastas em resumos hierárquicos com cache incremental de hash.',
    punchline: 'Pare de queimar dezenas de dólares em tokens a cada sessão do Claude por falta de uma planta baixa do seu código.',
    points: [
      'Você entende um projeto grande sem ler tudo — útil de quem está começando a quem já é sênior.',
      'A IA para de "esquecer" o projeto a cada pergunta: o contexto de arquitetura já existe em disco.',
      'Cache incremental por hash de verdade — rodar de novo só re-resume o que mudou.',
      'O thero já configura o Claude Code pra consultar os resumos da Athena automaticamente.',
    ],
    hasToggle: false,
    note: 'Vem junto quando o thero roda (clonado como parte do myscripts) — nada pra configurar aqui.',
  },
  zeus: {
    name: 'Zeus',
    color: '#EAB308',
    colorSecondary: '#CA8A04',
    colorAccent: '#FDE047',
    version: '0.1.0',
    updated: '18/09/2026',
    role: 'habitante',
    tagline: 'Antes de mexer em código, saiba quais arquivos realmente importam — sem adivinhar.',
    heroSubheadline: 'Cruza a tarefa que você quer realizar com o índice arquitetural da Athena e escreve um plano de ação em Markdown antes de qualquer linha de código mudar.',
    punchline: 'Pare de adivinhar arquivos no escuro e pare de deixar a IA editar 15 arquivos errados por pura precipitação.',
    points: [
      'Você descreve a tarefa em português e o Zeus cruza com o índice da Athena pra listar os arquivos que realmente importam.',
      'Escreve um plano de ação (objetivo, arquivos, passo a passo, riscos) antes de qualquer linha de código mudar.',
      'Não custa nada rodar de novo — o cache incremental da Athena torna reindexações baratas.',
      'Use direto ou via thero --plan "<tarefa>", que já cuida de instalar o Zeus e a Athena se faltarem.',
    ],
    hasToggle: false,
    note: 'Vem junto quando o thero roda — nada pra configurar aqui.',
  },
};

// Rotulos e icones dos "papeis" (mesmo texto de theroverse/src/data/
// i18n.ts -> hub.roles), usados no badge de cada card.
const SUITE_ROLE_LABELS = { habitante: 'Habitante Sênior', nave: 'Nave Cósmica' };
const SUITE_ROLE_ICON_SVG = {
  nave: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2 L19 21 L12 17 L5 21 Z"/></svg>',
  habitante: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="m16 11 2 2 4-4"/></svg>',
};

// Glifos vetoriais portados 1:1 de theroverse/src/components/icons/
// EcosystemIcon.tsx (mesmo ecossistema, mesma fonte visual - thero/Athena/
// Zeus la sao React+JSX, aqui viram string de SVG com as cores de cada
// ferramenta injetadas via template).
function suiteGlyphSvg(id, s) {
  const p = s.color;
  const sec = s.colorSecondary;
  const acc = s.colorAccent;
  const glyphs = {
    thero: `
      <path d="M15 27 C15 16.5 22.6 8 32 8 C41.4 8 49 16.5 49 27 C49 37.5 42 49 32 56 C22 49 15 37.5 15 27 Z" fill="${p}" fill-opacity="0.12" stroke="${p}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M20 26 H44" stroke="${acc}" stroke-width="3.5" stroke-linecap="round"/>
      <path d="M32 26 V44" stroke="${acc}" stroke-width="3.5" stroke-linecap="round"/>
      <circle cx="32" cy="26" r="3.5" fill="#0B0F17" stroke="${p}" stroke-width="2.5"/>
      <path d="M22 36 H26 M38 36 H42" stroke="${p}" stroke-width="2" stroke-linecap="round" stroke-opacity="0.8"/>`,
    athena: `
      <path d="M20 17 A 19 19 0 0 1 44 17" fill="none" stroke="${acc}" stroke-width="2" stroke-linecap="round" stroke-dasharray="4 3" stroke-opacity="0.8"/>
      <path d="M32 9 L52 43 L32 35 L12 43 Z" fill="${p}" fill-opacity="0.16" stroke="${p}" stroke-width="3.25" stroke-linejoin="round" stroke-linecap="round"/>
      <path d="M32 16 V35" stroke="${acc}" stroke-width="2" stroke-linecap="round"/>
      <circle cx="20" cy="53" r="2.5" fill="${sec}"/>
      <circle cx="32" cy="53" r="2.5" fill="${p}"/>
      <circle cx="44" cy="53" r="2.5" fill="${sec}"/>
      <path d="M20 50 L28 41 M32 50 V41 M44 50 L36 41" stroke="${p}" stroke-width="1.75" stroke-linecap="round" stroke-opacity="0.8"/>`,
    zeus: `
      <path d="M24 10 H20 A 4 4 0 0 0 16 14 V18" fill="none" stroke="${p}" stroke-width="2" stroke-linecap="round" stroke-opacity="0.6"/>
      <path d="M40 10 H44 A 4 4 0 0 1 48 14 V18" fill="none" stroke="${p}" stroke-width="2" stroke-linecap="round" stroke-opacity="0.6"/>
      <path d="M48 46 V50 A 4 4 0 0 1 44 54 H40" fill="none" stroke="${p}" stroke-width="2" stroke-linecap="round" stroke-opacity="0.6"/>
      <path d="M16 46 V50 A 4 4 0 0 0 20 54 H24" fill="none" stroke="${p}" stroke-width="2" stroke-linecap="round" stroke-opacity="0.6"/>
      <path d="M37 11 L22 32 H33 L26 53 L45 28 H33 Z" fill="${p}" fill-opacity="0.22" stroke="${p}" stroke-width="3.25" stroke-linejoin="round" stroke-linecap="round"/>
      <path d="M32 5 V8 M32 56 V59 M5 32 H8 M56 32 H59" stroke="${acc}" stroke-width="1.75" stroke-linecap="round" stroke-opacity="0.5"/>`,
  };
  return `<svg viewBox="0 0 64 64" width="100%" height="100%"><g>${glyphs[id]}</g></svg>`;
}

// ---------------------------------------------------------------- bridge --

const isHosted = !!(window.chrome && window.chrome.webview);

const Bridge = {
  _handlers: [],
  send(type, payload) {
    if (isHosted) {
      window.chrome.webview.postMessage(JSON.stringify({ type, payload }));
    } else {
      mockHandle(type, payload);
    }
  },
  on(fn) { this._handlers.push(fn); },
  _dispatch(msg) { this._handlers.forEach((fn) => fn(msg)); },
};

if (isHosted) {
  window.chrome.webview.addEventListener('message', (e) => {
    const msg = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
    Bridge._dispatch(msg);
  });
}

// -------------------------------------------------------- mock (preview) --

const MOCK_CONFIG = {
  wingetApps: [
    { id: 'Starship.Starship', label: 'Starship (prompt)', category: 'Terminal & Sistema', default: true, version: '1.26.0', updated: '2026-06-28' },
    { id: 'Microsoft.PowerToys', label: 'PowerToys', category: 'Terminal & Sistema', default: true, version: '0.101.2362.0', updated: '2026-08-25' },
    { id: 'RamenSoftware.Windhawk', label: 'Windhawk', category: 'Terminal & Sistema', default: false, version: '1.7.3', updated: '2025-12-09' },
    { id: 'Google.Chrome', label: 'Google Chrome', category: 'Navegadores', default: true, version: '153.0.8010.53', updated: '2026-09-17' },
    { id: 'Mozilla.Firefox', label: 'Firefox', category: 'Navegadores', default: false, version: '156.0', updated: '2026-09-15' },
    { id: 'Opera.Opera', label: 'Opera', category: 'Navegadores', default: false, version: '136.0.6008.22', updated: '2026-09-17' },
    { id: 'Valve.Steam', label: 'Steam', category: 'Jogos', default: false, version: '2.10.91.91', updated: '2024-05-20' },
    { id: 'Mojang.MinecraftLauncher', label: 'Minecraft Launcher', category: 'Jogos', default: true, version: '2.0.0.0', updated: '' },
  ],
  tasks: {
    RestorePoint: true, ExecutionPolicy: true, EnableWSL: true, GitHubSsh: true,
    Projects: true, Raycast: true, ClaudeCode: true, WinUtil: true,
    PowerShellProfile: true, TheroGlobal: true, NvidiaApp: true, Qoder: true,
    DefaultBrowserAndSearch: true, SearchRedirect: true, Bluetooth: true,
    HomeAssistant: true, WingetUpgradeTask: true, AutoBackup: false, Autologin: false,
  },
  homeAssistant: { mode: 'vm', vdiPath: 'D:\\HomeAssistantOS\\haos_ova-18.2.vdi', backupPath: '' },
  backupFolders: [],
  projects: ['git@github.com:netovieira/myscripts.git'],
  projectsFolder: 'D:\\projects',
  stepDefs: [
    { key: 'RestorePoint', label: 'Ponto de restauração' },
    { key: 'ExecutionPolicy', label: 'Execution Policy → Bypass' },
    { key: 'WingetApps', label: 'Apps via winget' },
    { key: 'ClaudeCode', label: 'Claude Code' },
  ],
};

function mockHandle(type, payload) {
  if (type === 'get-config') {
    setTimeout(() => Bridge._dispatch({ type: 'config', payload: MOCK_CONFIG }), 50);
    setTimeout(() => Bridge._dispatch({ type: 'installed-apps', payload: ['Starship.Starship', 'Google.Chrome'] }), 400);
  }
  if (type === 'start-install') {
    simulateInstall();
  }
  if (type === 'get-launchable') {
    setTimeout(() => Bridge._dispatch({
      type: 'launchable',
      payload: [
        { label: 'Google Chrome', action: { kind: 'app', appId: 'mock' } },
        { label: 'Claude Code (terminal)', action: { kind: 'claude' } },
      ],
    }), 50);
  }
  if (type === 'search-apps') {
    const q = payload.query.toLowerCase();
    const pool = [
      { id: 'VideoLAN.VLC', label: 'VLC media player', version: '3.0.20', homepage: 'https://www.videolan.org/vlc/', description: 'Free and open source cross-platform multimedia player.' },
      { id: 'Figma.Figma', label: 'Figma', version: '125.4.4', homepage: 'https://www.figma.com/', description: 'Collaborative interface design tool.' },
      { id: 'Zoom.Zoom', label: 'Zoom Workplace', version: '6.3.5', homepage: 'https://zoom.us/', description: 'Video conferencing and online meetings.' },
    ];
    const results = pool.filter((p) => p.label.toLowerCase().includes(q) || p.id.toLowerCase().includes(q));
    setTimeout(() => Bridge._dispatch({ type: 'search-results', payload: results.map((r) => ({ ...r, category: 'Extra', icon: null })) }), 400);
  }
  if (type === 'browse-folder') {
    setTimeout(() => Bridge._dispatch({ type: 'browse-result', payload: { field: payload.field, index: payload.index, path: 'C:\\Users\\exemplo\\Documentos' } }), 200);
  }
  if (type === 'ensure-projects-folder') {
    setTimeout(() => Bridge._dispatch({ type: 'projects-folder-result', payload: { ok: true } }), 150);
  }
  if (type === 'browse-file') {
    setTimeout(() => Bridge._dispatch({ type: 'browse-result', payload: { field: payload.field, index: payload.index, path: 'C:\\exemplo\\arquivo-escolhido.tar' } }), 200);
  }
}

function simulateInstall() {
  const apps = installedApps();
  let ai = 0;
  const tickApps = () => {
    if (ai >= apps.length) { simulateSteps(); return; }
    const a = apps[ai];
    Bridge._dispatch({ type: 'app-status', payload: { id: a.id, status: 'Running' } });
    Bridge._dispatch({ type: 'log', payload: `    Instalando ${a.label} ...` });
    setTimeout(() => {
      Bridge._dispatch({ type: 'app-status', payload: { id: a.id, status: 'Ok' } });
      Bridge._dispatch({ type: 'log', payload: `    OK: ${a.label} instalado` });
      ai += 1;
      setTimeout(tickApps, 250);
    }, 450);
  };

  const steps = (MOCK_CONFIG.stepDefs || []).filter((s) => s.key !== 'WingetApps');
  let i = 0;
  function simulateSteps() {
    if (i >= steps.length) {
      Bridge._dispatch({ type: 'done', payload: { reboot: true, logFile: 'C:\\...\\logs\\genesis-mock.log' } });
      return;
    }
    const s = steps[i];
    Bridge._dispatch({ type: 'step', payload: { key: s.key, status: 'Running' } });
    Bridge._dispatch({ type: 'log', payload: `==> ${s.label}` });
    setTimeout(() => {
      Bridge._dispatch({ type: 'step', payload: { key: s.key, status: 'Ok' } });
      Bridge._dispatch({ type: 'log', payload: `    OK: ${s.label} concluído` });
      i += 1;
      setTimeout(simulateSteps, 350);
    }, 500);
  }

  setTimeout(tickApps, 300);
}

// ------------------------------------------------------------------ state --

const state = {
  config: null,
  selectedApps: new Set(),
  installedIds: new Set(),
  extraApps: [],
  catalogQuery: '',
  catalogCategory: 'Todos',
  searchQuery: '',
  searchResults: [],
  searchLoading: false,
  tasks: {},
  homeAssistant: { mode: 'vm', vdiPath: '', backupPath: '' },
  backupFolders: [],
  projectsFolder: '',
  projectsText: '',
  stepIndex: 0,
  installResults: {},
  appInstallStatus: {},
  installLog: [],
  installDone: false,
  installReboot: false,
  installLogFile: '',
};

function buildSteps() {
  const steps = [
    { id: 'welcome', group: 'início', title: 'Bem-vindo' },
    { id: 'catalog', group: 'aplicativos', title: 'Catálogo de apps' },
    { id: 'search-more', group: 'aplicativos', title: 'Adicionar mais' },
  ];

  steps.push({ id: 'tasks', group: 'sistema', title: 'Etapas do sistema' });

  if (state.tasks.ClaudeCode) {
    steps.push({ id: 'suite', group: 'theroverse', title: 'Theroverse' });
  }

  steps.push({ id: 'review', group: 'revisão', title: 'Revisão' });
  steps.push({ id: 'progress', group: 'instalação', title: 'Instalação' });
  steps.push({ id: 'done', group: 'instalação', title: 'Concluído' });
  steps.push({ id: 'about', group: 'instalação', title: 'Sobre o autor' });

  return steps;
}

// ------------------------------------------------------------------- init --

function init() {
  Bridge.on(onBridgeMessage);
  Bridge.send('get-config');
}

function onBridgeMessage(msg) {
  if (msg.type === 'config') {
    state.config = msg.payload;
    state.tasks = { ...msg.payload.tasks };
    state.homeAssistant = { mode: 'vm', vdiPath: '', backupPath: '', ...(msg.payload.homeAssistant || {}) };
    state.backupFolders = [...(msg.payload.backupFolders || [])];
    state.projectsFolder = msg.payload.projectsFolder || '';
    state.projectsText = (msg.payload.projects || [])
      .map((p) => (typeof p === 'string' ? p : `${p.url} => ${p.name}`))
      .join('\n');
    (msg.payload.wingetApps || []).forEach((a) => { if (a.default) state.selectedApps.add(a.id); });
    render();
  }
  if (msg.type === 'browse-result') {
    const { field, index, path } = msg.payload;
    if (field === 'backupFolder') state.backupFolders[index] = path;
    if (field === 'haVdiPath') state.homeAssistant.vdiPath = path;
    if (field === 'haBackupPath') state.homeAssistant.backupPath = path;
    if (field === 'projectsFolder') state.projectsFolder = path;
    render();
  }
  if (msg.type === 'projects-folder-result') {
    // PS ja criou a pasta (ou ja existia) e liberou pra instalar; se falhou,
    // ele mesmo mostrou o MessageBox com o erro real - aqui so garante que
    // a instalação NÃO avança e devolve o foco pro campo do caminho.
    if (msg.payload.ok) {
      startInstall();
    } else {
      const el = document.getElementById('projects-folder-path');
      if (el) el.focus();
    }
  }
  if (msg.type === 'step') {
    state.installResults[msg.payload.key] = msg.payload.status;
    if (!updateStepRow(msg.payload.key, msg.payload.status)) render();
  }
  if (msg.type === 'log') {
    state.installLog.push(msg.payload);
    if (!appendLogLine(msg.payload)) render();
  }
  if (msg.type === 'app-status') {
    state.appInstallStatus[msg.payload.id] = msg.payload.status;
    if (!updateAppCardStatus(msg.payload.id, msg.payload.status)) render();
  }
  if (msg.type === 'done') {
    state.installDone = true;
    state.installReboot = msg.payload.reboot;
    state.installLogFile = msg.payload.logFile;
    const steps = buildSteps();
    state.stepIndex = steps.findIndex((s) => s.id === 'done');
    Bridge.send('get-launchable');
    render();
  }
  if (msg.type === 'launchable') {
    state.launchable = msg.payload;
    render();
  }
  if (msg.type === 'search-results') {
    state.searchLoading = false;
    state.searchResults = msg.payload;
    // Com a tela de busca aberta, atualiza SÓ a lista: um render() completo
    // aqui recriaria o input e o usuário perderia o foco no meio da
    // digitação (o winget responde em ~1s, ou seja, em pleno typing).
    const step = buildSteps()[state.stepIndex];
    if (step && step.id === 'search-more') refreshSearchMore(); else render();
  }
  if (msg.type === 'installed-apps') {
    // Chega em background, depois do config inicial (winget list demora
    // alguns segundos) - apps já instalados ficam marcados e travados
    // (não dá pra desmarcar) assim que a lista aparece.
    state.installedIds = new Set(msg.payload);
    (state.config.wingetApps || []).forEach((a) => {
      if (state.installedIds.has(a.id)) state.selectedApps.add(a.id);
    });
    const step = buildSteps()[state.stepIndex];
    if (step && step.id === 'catalog') refreshCatalog(); else render();
  }
}

// ---------------------------------------------------------------- render --

const $sidebar = document.getElementById('sidebar');
const $content = document.getElementById('content');
const $btnBack = document.getElementById('btn-back');
const $btnSkip = document.getElementById('btn-skip');
const $btnNext = document.getElementById('btn-next');
const $navStatus = document.getElementById('navbar-status');

document.getElementById('btn-close').addEventListener('click', () => Bridge.send('window-close'));
document.getElementById('btn-min').addEventListener('click', () => Bridge.send('window-minimize'));

// WebView2 doesn't support the Electron-only -webkit-app-region CSS, so
// dragging the borderless host window is wired here: mousedown on the
// titlebar (but not on its buttons) asks the PS host to hand the drag to
// Windows (ReleaseCapture + WM_NCLBUTTONDOWN/HTCAPTION).
document.getElementById('titlebar').addEventListener('mousedown', (e) => {
  if (e.target.closest('.win-btn')) return;
  Bridge.send('window-drag');
});

function render() {
  if (!state.config) return;
  const steps = buildSteps();
  if (state.stepIndex >= steps.length) state.stepIndex = steps.length - 1;
  const step = steps[state.stepIndex];

  renderSidebar(steps, step);
  renderContent(step);
  renderNav(steps, step);
}

function renderSidebar(steps, current) {
  const groups = [];
  steps.forEach((s) => {
    let g = groups.find((x) => x.title === s.group);
    if (!g) { g = { title: s.group, items: [] }; groups.push(g); }
    g.items.push(s);
  });

  $sidebar.innerHTML = groups.map((g) => `
    <div class="side-group">
      <div class="side-group-title">${escapeHtml(g.title)}</div>
      ${g.items.map((s) => {
        const idx = steps.indexOf(s);
        const cls = ['side-item'];
        if (s.id === current.id) cls.push('is-current');
        else if (idx < state.stepIndex) cls.push('is-done');
        return `<div class="${cls.join(' ')}" data-step="${idx}"><span class="dot"></span>${escapeHtml(s.title)}</div>`;
      }).join('')}
    </div>
  `).join('');

  $sidebar.querySelectorAll('.side-item').forEach((el) => {
    el.addEventListener('click', () => {
      const idx = Number(el.dataset.step);
      if (idx <= state.stepIndex || state.installDone) { state.stepIndex = idx; render(); }
    });
  });
}

function renderNav(steps, step) {
  $btnBack.disabled = state.stepIndex === 0 || step.id === 'progress';
  $btnNext.disabled = false;
  $btnNext.textContent = 'Avançar';
  $btnSkip.style.display = 'none';

  if (step.id === 'suite') {
    // Avançar SEMPRE quer dizer "prosseguir com o thero" (liga de novo se
    // tinha sido pulado antes - ver onNext); Pular e o unico jeito de
    // desligar. Rotulo fixo pra nao contradizer esse comportamento.
    $btnSkip.style.display = '';
  }
  if (step.id === 'review') $btnNext.textContent = 'Instalar agora';
  if (step.id === 'progress') { $btnNext.disabled = true; $btnNext.textContent = 'Instalando…'; $btnBack.disabled = true; }
  if (step.id === 'done') { $btnNext.textContent = 'Avançar'; $btnBack.disabled = true; }
  if (step.id === 'about') { $btnNext.textContent = 'Fechar'; }

  $navStatus.textContent = `ETAPA ${state.stepIndex + 1} / ${steps.length} — ${step.title.toUpperCase()}`;
}

$btnBack.addEventListener('click', () => { state.stepIndex = Math.max(0, state.stepIndex - 1); render(); });
$btnNext.addEventListener('click', onNext);
$btnSkip.addEventListener('click', onSkip);

function onNext() {
  const steps = buildSteps();
  const step = steps[state.stepIndex];
  if (step.id === 'suite') { state.tasks.TheroGlobal = true; }
  if (step.id === 'review') {
    // Pasta pode nao existir ainda (campo aceita caminho novo) - PS tenta
    // criar antes; startInstall só roda no 'projects-folder-result' com
    // ok:true (ver onBridgeMessage). Falhou -> fica na Revisão, PS já
    // mostrou o erro e o campo recebe foco de volta.
    Bridge.send('ensure-projects-folder', { path: state.projectsFolder });
    return;
  }
  if (step.id === 'about') { Bridge.send('window-close'); return; }
  state.stepIndex = Math.min(steps.length - 1, state.stepIndex + 1);
  render();
}

function onSkip() {
  const steps = buildSteps();
  const step = steps[state.stepIndex];
  if (step.id === 'suite') { state.tasks.TheroGlobal = false; }
  state.stepIndex = Math.min(steps.length - 1, state.stepIndex + 1);
  render();
}

function startInstall() {
  const projects = state.projectsText.split('\n').map((l) => l.trim()).filter(Boolean).map((line) => {
    const m = line.split('=>').map((x) => x.trim());
    return m.length === 2 ? { url: m[0], name: m[1] } : m[0];
  });
  Bridge.send('start-install', {
    selectedAppIds: [...state.selectedApps],
    extraApps: state.extraApps,
    tasks: state.tasks,
    homeAssistant: state.homeAssistant,
    backupFolders: state.backupFolders.filter((f) => f.trim()),
    projectsFolder: state.projectsFolder,
    projects,
  });
  const steps = buildSteps();
  state.stepIndex = steps.findIndex((s) => s.id === 'progress');
  render();
}

// ----------------------------------------------------------- screen views --

function renderContent(step) {
  const renderers = {
    welcome: viewWelcome,
    about: viewAbout,
    tasks: viewTasks,
    review: viewReview,
    progress: viewProgress,
    done: viewDone,
  };
  if (step.id === 'catalog') { $content.innerHTML = viewCatalog(); bindCatalog(); return; }
  if (step.id === 'search-more') { $content.innerHTML = viewSearchMore(); bindSearchMore(); return; }
  if (step.id === 'suite') { $content.innerHTML = viewSuiteHub(); return; }
  $content.innerHTML = (renderers[step.id] || viewWelcome)();
  if (step.id === 'review') bindReview();
  if (step.id === 'done') bindDone();
}

function viewWelcome() {
  return `
    <div class="screen">
      <h1 class="screen-kicker-free-title">Bem-vindo ao <span class="text-gradient">Genesis</span>.</h1>
      <p class="screen-lede">
        Este assistente escolhe, com você, tudo que entra no seu PC recém-formatado —
        aplicativos, etapas de sistema e as ferramentas do Claude Code — e depois faz
        sozinho, sem mais perguntas (com uma única exceção: confirmar o login do GitHub
        no navegador, quando chegar lá).
      </p>
      <div class="panel">
        <p class="panel-title">Como funciona</p>
        <p class="panel-sub">
          Nas próximas telas você marca o que quer instalar, por categoria, revisa
          tudo numa página só, e clica em "Instalar agora". Pode voltar e mudar
          qualquer escolha antes disso — depois do "Instalar agora" o processo roda
          sozinho até o fim.
        </p>
      </div>
    </div>`;
}

// Real content pulled from netovieira.github.io's own source
// (~/.myscripts/netovieira/src/routes/index.tsx) - same photo, tagline
// and project write-ups as the live portfolio, not paraphrased copy.
const PORTFOLIO_PROJECTS = [
  {
    name: 'MeuWatt', category: 'Energia · SaaS industrial', image: 'assets/project-meuwatt.jpg',
    statement: 'Monitoramento de precisão para operações de energia solar em escala.',
    href: 'https://www.meuwatt.com.br/',
  },
  {
    name: 'Mouraverse', category: 'IA corporativa · Knowledge systems', image: 'assets/project-mouraverse.jpg',
    statement: 'Memória hierárquica para dar contexto real a sistemas de inteligência artificial — o mesmo princípio que depois inspirou Athena e Zeus.',
    href: null,
  },
  {
    name: 'Nexo', category: 'IA local · Open source', image: 'assets/project-nexo.jpg',
    statement: 'Uma máquina organizada sem nuvem, assinatura ou linha de comando.',
    href: 'https://github.com/avnt-sistemas/nexo',
  },
];

function viewAbout() {
  return `
    <div class="screen screen-wide">
      <div class="portfolio-hero">
        <img class="portfolio-photo" src="assets/anthero-portrait.png" alt="Anthero Vieira Neto" />
        <div>
          <span class="chip"><span class="dot" style="background:var(--cyan)"></span>Brasil · Disponível globalmente</span>
          <h1 class="screen-kicker-free-title" style="margin:14px 0 6px">Eu transformo <span class="text-gradient">complexidade</span> em produto.</h1>
          <p class="screen-lede" style="margin-bottom:16px">
            Anthero Vieira Neto — Engenheiro de Software. Há mais de 18 anos construindo software,
            conectando arquitetura, DevOps e inteligência artificial para levar ideias ambiciosas até a produção.
          </p>
          <div class="suite-meta">
            <span class="chip">Arquitetura</span>
            <span class="chip">DevOps</span>
            <span class="chip">IA aplicada</span>
            <span class="chip">18+ anos</span>
          </div>
          <div class="about-links" style="margin-top:16px">
            <a class="about-link" href="https://netovieira.github.io" target="_blank" rel="noopener">PORTFÓLIO COMPLETO ↗</a>
            <a class="about-link" href="https://github.com/netovieira" target="_blank" rel="noopener">GITHUB ↗</a>
          </div>
        </div>
      </div>

      <p class="panel-title" style="margin:28px 0 12px">Trabalho selecionado</p>
      <div class="portfolio-grid">
        ${PORTFOLIO_PROJECTS.map((p) => `
          <a class="portfolio-card" href="${p.href ? escapeAttr(p.href) : '#'}" ${p.href ? 'target="_blank" rel="noopener"' : 'onclick="return false" style="cursor:default"'}>
            <img src="${p.image}" alt="" />
            <div class="portfolio-card-body">
              <div class="app-card-meta">${escapeHtml(p.category)}</div>
              <div class="app-card-name">${escapeHtml(p.name)}${p.href ? '' : ' <span class="chip" style="margin-left:6px">Privado</span>'}</div>
              <p class="app-card-desc">${escapeHtml(p.statement)}</p>
            </div>
          </a>
        `).join('')}
      </div>

      <div class="panel" style="margin-top:24px">
        <p class="panel-sub" style="margin:0">
          Esse instalador nasceu de reformatar o próprio PC e cansar de reconfigurar tudo na mão — é código
          aberto, junto com <strong>thero</strong>, <strong>Athena</strong> e <strong>Zeus</strong>, no repositório <code>myscripts</code>.
        </p>
      </div>
    </div>`;
}

function formatDate(iso) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  return m ? `${m[3]}/${m[2]}/${m[1]}` : iso;
}

// ---------- catalog (winget.run-style: search + category chips + grid) ----

// O filtro/cards ficam separados do input: ao digitar, só este trecho do DOM
// é trocado (ver refreshCatalog), então o campo de busca nunca é recriado e
// não perde o foco nem a posição do cursor a cada tecla.
function catalogCountText() {
  return `${state.selectedApps.size} selecionados no total. Marque o que quiser instalar.`;
}

// Contador por categoria: "marcados / total" exibido em cada chip
// (ex: "Navegadores 2/5"). 'Todos' soma tudo.
function categoryCounts(category) {
  const all = state.config.wingetApps || [];
  const inCat = category === 'Todos' ? all : all.filter((a) => a.category === category);
  const selected = inCat.filter((a) => state.selectedApps.has(a.id)).length;
  return { selected, total: inCat.length };
}

function catalogChipsHtml() {
  const all = state.config.wingetApps || [];
  const categories = ['Todos', ...new Set(all.map((a) => a.category))];
  return categories.map((c) => {
    const { selected, total } = categoryCounts(c);
    const count = ` <span class="chip-count">${selected}/${total}</span>`;
    return `<button class="chip-filter ${c === state.catalogCategory ? 'is-active' : ''}" data-cat="${escapeAttr(c)}">${escapeHtml(CATEGORY_LABELS[c] || c)}${count}</button>`;
  }).join('');
}

function catalogGridHtml() {
  const all = state.config.wingetApps || [];
  const q = state.catalogQuery.trim().toLowerCase();
  const visible = all.filter((a) => {
    const inCategory = state.catalogCategory === 'Todos' || a.category === state.catalogCategory;
    const inQuery = !q || a.label.toLowerCase().includes(q) || a.id.toLowerCase().includes(q);
    return inCategory && inQuery;
  });
  if (!visible.length) return '<p class="panel-sub">Nada encontrado.</p>';

  // Agrupa por categoria (mesmo padrão do viewProgress) - com "Todos"
  // selecionado isso separa o catálogo inteiro em seções; com um chip de
  // categoria ativo vira só um grupo, sem diferença visual de antes.
  const byCategory = [];
  visible.forEach((a) => {
    let g = byCategory.find((x) => x.category === a.category);
    if (!g) { g = { category: a.category, apps: [] }; byCategory.push(g); }
    g.apps.push(a);
  });

  return byCategory.map((g) => `
    <p class="panel-title catalog-group-title">${escapeHtml(CATEGORY_LABELS[g.category] || g.category)}</p>
    <div class="catalog-grid">
      ${g.apps.map((a) => catalogCard(a)).join('')}
    </div>
  `).join('');
}

function viewCatalog() {
  return `
    <div class="screen screen-full">
      <h1 class="screen-kicker-free-title">Catálogo de <span class="text-gradient">aplicativos</span></h1>
      <p class="screen-lede" id="catalog-count">${catalogCountText()}</p>

      <div class="catalog-toolbar">
        <input type="text" id="catalog-search" class="catalog-search" placeholder="Buscar por nome ou id…" value="${escapeAttr(state.catalogQuery)}" />
        <div class="catalog-chips" id="catalog-chips">
          ${catalogChipsHtml()}
        </div>
      </div>

      <div id="catalog-grid">
        ${catalogGridHtml()}
      </div>
    </div>`;
}

function catalogCard(a) {
  const color = CATEGORY_COLORS[a.category] || '#93a1c4';
  // Já instalado: fica marcado e travado (sem dar pra desmarcar) - não faz
  // sentido deixar o usuário desinstalar sem querer daqui.
  const installed = state.installedIds.has(a.id);
  const checked = installed || state.selectedApps.has(a.id);
  const icon = `assets/icons/${iconFileName(a.id)}`;
  const desc = APP_DESCRIPTIONS[a.id] || '';
  const versionText = (!a.version || a.version === 'Unknown' || a.source === 'msstore') ? 'Microsoft Store' : `v${a.version}`;
  const metaText = installed ? 'Já instalado' : versionText;
  return `
    <div class="app-card ${checked ? 'is-checked' : ''} ${installed ? 'is-installed' : ''}" data-id="${escapeAttr(a.id)}" ${installed ? 'data-installed="1" title="Já instalado nesta máquina"' : ''}>
      <div class="app-card-top">
        <span class="app-card-icon"><img src="${icon}" alt="" onerror="this.parentElement.style.background='${color}22';this.remove()" /></span>
        <span class="check-box app-card-check">${ICON_CHECK}</span>
      </div>
      <div class="app-card-name">${escapeHtml(a.label)}</div>
      <div class="app-card-meta"><span class="dot" style="background:${color}"></span>${escapeHtml(CATEGORY_LABELS[a.category] || a.category)} · ${escapeHtml(metaText)}</div>
      <p class="app-card-desc">${escapeHtml(desc)}</p>
    </div>`;
}

function bindCatalog() {
  const search = document.getElementById('catalog-search');
  // Digitar NÃO re-renderiza a tela inteira: o input fica onde está e só a
  // grade/cards + o contador são atualizados. Era isso que fazia o campo
  // perder o foco a cada letra (o input antigo saía do DOM e o .focus()
  // seguinte já apontava pra um elemento destacado).
  search.addEventListener('input', () => {
    state.catalogQuery = search.value;
    refreshCatalog();
  });

  $content.querySelectorAll('.chip-filter').forEach((el) => {
    el.addEventListener('click', () => {
      state.catalogCategory = el.dataset.cat;
      $content.querySelectorAll('.chip-filter').forEach((c) => c.classList.toggle('is-active', c === el));
      refreshCatalog();
    });
  });

  bindCatalogCards($content);
}

function bindCatalogCards(scope) {
  scope.querySelectorAll('.app-card[data-id]').forEach((el) => {
    if (el.dataset.installed) return; // já instalado: não dá pra desmarcar
    el.addEventListener('click', () => {
      const id = el.dataset.id;
      if (state.selectedApps.has(id)) state.selectedApps.delete(id); else state.selectedApps.add(id);
      refreshCatalog();
    });
  });
}

function refreshCatalog() {
  const grid = document.getElementById('catalog-grid');
  if (!grid) return;
  grid.innerHTML = catalogGridHtml();
  bindCatalogCards(grid);
  const count = document.getElementById('catalog-count');
  if (count) count.textContent = catalogCountText();
  // os contadores "marcados/total" dos chips mudam junto com os cliques nos
  // cards - atualiza so o container dos chips (o input de busca e irmao dele
  // no toolbar, continua intacto no DOM)
  const chips = document.getElementById('catalog-chips');
  if (chips) {
    chips.innerHTML = catalogChipsHtml();
    chips.querySelectorAll('.chip-filter').forEach((el) => {
      el.addEventListener('click', () => {
        state.catalogCategory = el.dataset.cat;
        chips.querySelectorAll('.chip-filter').forEach((c) => c.classList.toggle('is-active', c === el));
        refreshCatalog();
      });
    });
  }
}

// ---------- add more apps (live winget search) ----

function viewSearchMore() {
  return `
    <div class="screen">
      <h1 class="screen-kicker-free-title">Adicionar <span class="text-gradient">mais apps</span></h1>
      <p class="screen-lede">Não achou algo no catálogo? Busque direto no winget — qualquer pacote publicado lá pode entrar na instalação.</p>

      <div class="catalog-toolbar">
        <input type="text" id="search-more-input" class="catalog-search" placeholder="Buscar no winget (ex: vlc, figma, zoom)…" value="${escapeAttr(state.searchQuery)}" />
      </div>

      <div class="catalog-grid" id="search-results">${searchResultsHtml()}</div>
      <div id="extra-apps">${extraAppsHtml()}</div>
    </div>`;
}

function searchResultsHtml() {
  if (state.searchLoading) return '<p class="panel-sub">Buscando…</p>';
  if (state.searchQuery.trim().length >= 2 && !state.searchResults.length) return '<p class="panel-sub">Nada encontrado no winget.</p>';
  return state.searchResults.map((r) => searchResultCard(r)).join('');
}

function extraAppsHtml() {
  if (!state.extraApps.length) return '';
  return `
    <div class="panel" style="margin-top:24px">
      <p class="panel-title">Adicionados nesta etapa (${state.extraApps.length})</p>
      ${state.extraApps.map((a) => `
        <div class="check-row is-checked" data-remove="${escapeAttr(a.id)}" style="cursor:pointer">
          <span class="check-box">${ICON_CHECK}</span>
          <span class="check-body">
            <div class="check-label">${escapeHtml(a.label)}</div>
            <div class="check-meta">${escapeHtml(a.id)} · clique pra remover</div>
          </span>
        </div>`).join('')}
    </div>`;
}

function searchResultCard(r) {
  const already = state.extraApps.some((e) => e.id === r.id);
  const icon = searchResultIconHtml(r);
  return `
    <div class="app-card ${already ? 'is-checked' : ''}" data-add="${escapeAttr(r.id)}">
      <div class="app-card-top">
        <span class="app-card-icon">${icon}</span>
        <span class="check-box app-card-check">${ICON_CHECK}</span>
      </div>
      <div class="app-card-name">${escapeHtml(r.label)}</div>
      <div class="app-card-meta">${escapeHtml(r.id)}${r.version ? ' · v' + escapeHtml(r.version) : ''}</div>
      <p class="app-card-desc">${escapeHtml(r.description || '')}</p>
    </div>`;
}

// Fallback local pros resultados do winget: se o backend nao mandou icone
// (ou o favicon do Google falhou), tenta o PNG embutido do catalogo e, por
// fim, a letra inicial com a cor da categoria - card nunca fica sem rosto.
function searchResultIconHtml(r) {
  if (r.icon) return `<img src="${r.icon}" alt="" onerror="this.parentElement.classList.add('icon-fallback');this.remove()" />`;
  const local = `assets/icons/${iconFileName(r.id)}`;
  const letter = escapeHtml((r.label || r.id || '?').trim().charAt(0).toUpperCase());
  return `<img src="${local}" alt="" onerror="this.parentElement.classList.add('icon-fallback');this.parentElement.setAttribute('data-letter','${letter}');this.remove()" />`;
}

let searchDebounce = null;
function bindSearchMore() {
  const input = document.getElementById('search-more-input');
  // Mesma regra do catálogo: digitar só atualiza a lista de resultados, o
  // input continua no DOM (e portanto mantém o foco e o cursor).
  input.addEventListener('input', () => {
    state.searchQuery = input.value;
    clearTimeout(searchDebounce);
    if (state.searchQuery.trim().length < 2) {
      state.searchResults = [];
      state.searchLoading = false;
      refreshSearchMore();
      return;
    }
    state.searchLoading = true;
    refreshSearchMore();
    searchDebounce = setTimeout(() => Bridge.send('search-apps', { query: state.searchQuery.trim() }), 400);
  });

  bindSearchMoreResults($content);
}

function refreshSearchMore() {
  const results = document.getElementById('search-results');
  if (results) results.innerHTML = searchResultsHtml();
  const extras = document.getElementById('extra-apps');
  if (extras) extras.innerHTML = extraAppsHtml();
  bindSearchMoreResults($content);
}

function bindSearchMoreResults(scope) {
  scope.querySelectorAll('.app-card[data-add]').forEach((el) => {
    el.addEventListener('click', () => {
      const id = el.dataset.add;
      const r = state.searchResults.find((x) => x.id === id);
      if (!r) return;
      if (!state.extraApps.some((e) => e.id === id)) {
        state.extraApps.push(r);
        state.selectedApps.add(id);
      }
      refreshSearchMore();
    });
  });

  scope.querySelectorAll('[data-remove]').forEach((el) => {
    el.addEventListener('click', () => {
      const id = el.dataset.remove;
      state.extraApps = state.extraApps.filter((a) => a.id !== id);
      state.selectedApps.delete(id);
      refreshSearchMore();
    });
  });
}

function viewTasks() {
  return `
    <div class="screen">
      <h1 class="screen-kicker-free-title">Etapas do <span class="text-gradient">sistema</span></h1>
      <p class="screen-lede">Cada uma roda uma vez, na ordem certa. Desligue o que não fizer sentido pra essa máquina.</p>
      ${TASK_GROUPS.map((g) => `
        <div class="panel">
          <p class="panel-title">${escapeHtml(g.title)}</p>
          ${g.keys.map(taskRow).join('')}
        </div>
      `).join('')}
    </div>`;
}

function taskRow(key) {
  const meta = TASK_META[key];
  const checked = !!state.tasks[key];
  const row = `
    <div class="check-row ${checked ? 'is-checked' : ''}" data-task="${escapeAttr(key)}">
      <span class="check-box">${ICON_CHECK}</span>
      <span class="check-body">
        <div class="check-label">${escapeHtml(meta.label)} ${meta.risk ? '<span class="chip" style="margin-left:6px"><span class="dot" style="background:#fbbf5b"></span>risco</span>' : ''}</div>
        <div class="check-desc">${escapeHtml(meta.desc)}</div>
      </span>
    </div>`;
  return key === 'AutoBackup' && checked ? row + viewBackupFolders() : row;
}

function viewBackupFolders() {
  return `
    <div class="backup-folders">
      ${state.backupFolders.map((f, i) => `
        <div class="backup-folder-row">
          <input type="text" class="backup-folder-input" data-idx="${i}" value="${escapeAttr(f)}" placeholder="Caminho da pasta..." />
          <button class="btn btn-ghost" data-browse-folder="${i}">Procurar</button>
          <button class="btn btn-subtle" data-remove-folder="${i}" title="Remover">Remover</button>
        </div>
      `).join('')}
      <button class="btn btn-ghost" id="backup-add-folder">+ Adicionar pasta</button>
    </div>`;
}

function bindTasksHandlers(root) {
  root.querySelectorAll('.check-row[data-task]').forEach((el) => {
    el.addEventListener('click', (e) => {
      if (e.target.closest('.backup-folders')) return;
      const key = el.dataset.task;
      state.tasks[key] = !state.tasks[key];
      if (state.tasks[key] && key === 'AutoBackup' && state.backupFolders.length === 0) {
        state.backupFolders.push('');
      }
      render();
    });
  });
  root.querySelectorAll('.backup-folder-input').forEach((el) => {
    el.addEventListener('change', () => { state.backupFolders[Number(el.dataset.idx)] = el.value; });
  });
  root.querySelectorAll('[data-browse-folder]').forEach((el) => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      Bridge.send('browse-folder', { field: 'backupFolder', index: Number(el.dataset.browseFolder) });
    });
  });
  root.querySelectorAll('[data-remove-folder]').forEach((el) => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      state.backupFolders.splice(Number(el.dataset.removeFolder), 1);
      render();
    });
  });
  const addBtn = root.querySelector('#backup-add-folder');
  if (addBtn) {
    addBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      state.backupFolders.push('');
      render();
    });
  }
}

// Uma tela so pras 3 ferramentas (antes eram 3 telas separadas), reproduzindo
// a secao "Escolha uma Entidade & Salte Através do Portal" do proprio
// theroverse (CosmicPortalHub.tsx + i18n.ts hub.portalsBadge/portalsTitle,
// mesmo texto). Cards nao sao clicaveis aqui (sem landing page por tras) -
// so mostram os mesmos dados (papel, tagline, heroSubheadline, punchline).
// thero e a unica escolha real: em vez de checkbox no card, um glow animado
// na cor dele quando vai instalar; o "Pular" no rodape (perto do Voltar) e
// quem desliga - ver renderNav/onNext/onSkip pro step 'suite'.
function viewSuiteHub() {
  const ids = ['thero', 'athena', 'zeus'];
  const theroOn = !!state.tasks.TheroGlobal;
  return `
    <div class="screen screen-wide">
      <div class="suite-hub-kicker">
        <span class="suite-hub-kicker-icon">${ICON_SPARKLE}</span>
        <span>Portais Hiperespaço</span>
      </div>
      <h1 class="screen-kicker-free-title">Escolha uma Entidade & Salte <span class="text-gradient">Através do Portal</span></h1>
      <p class="screen-lede">${theroOn ? 'thero entra com você; Athena e Zeus vêm automáticos junto dele.' : 'thero fica de fora desta instalação (você pulou) — Athena e Zeus dependem dele, então também ficam de fora.'}</p>
      <div class="suite-hub-grid">
        ${ids.map((id) => suiteHubCard(id, theroOn)).join('')}
      </div>
    </div>`;
}

function suiteHubCard(id, theroOn) {
  const s = SUITE_CONTENT[id];
  const isThero = id === 'thero';
  const active = theroOn; // Athena/Zeus seguem o thero (dependem dele)
  const statusHtml = isThero
    ? `<span class="suite-hub-glow ${active ? 'is-on' : ''}" style="--suite-color:${s.color}" title="${active ? 'Vai instalar' : 'Não vai instalar (pulado)'}"></span>`
    : `<span class="chip">${active ? 'Automático' : 'Pulado com o thero'}</span>`;
  return `
    <div class="suite-hub-card ${active ? '' : 'is-off'}" style="--suite-color:${s.color}">
      <div class="suite-hub-top">
        <span class="suite-icon">${suiteGlyphSvg(id, s)}</span>
        <div class="suite-hub-role">
          <span class="chip"><span class="suite-hub-role-icon">${SUITE_ROLE_ICON_SVG[s.role]}</span>${escapeHtml(SUITE_ROLE_LABELS[s.role])}</span>
          <span class="suite-hub-license">Open-Source (MIT)</span>
        </div>
      </div>

      <h2 class="suite-hub-name">${escapeHtml(s.name)}</h2>
      <p class="suite-hub-tagline">${escapeHtml(s.tagline)}</p>
      <p class="panel-sub" style="margin:10px 0 0">${escapeHtml(s.heroSubheadline)}</p>
      <p class="suite-hub-punchline">&ldquo;${escapeHtml(s.punchline)}&rdquo;</p>

      <div class="suite-hub-footer">
        ${statusHtml}
      </div>
    </div>`;
}

function viewReview() {
  const totalApps = state.selectedApps.size;
  const totalTasks = Object.values(state.tasks).filter(Boolean).length;
  const ha = state.homeAssistant;
  return `
    <div class="screen">
      <h1 class="screen-kicker-free-title">Revisar antes de <span class="text-gradient">instalar</span></h1>
      <p class="screen-lede">Confira os números e os campos abaixo. Depois de "Instalar agora" o processo roda sozinho.</p>
      <div class="panel">
        <p class="panel-title">Resumo</p>
        <p class="panel-sub" style="margin:0">${totalApps} aplicativos selecionados · ${totalTasks} etapas de sistema ativas.</p>
      </div>

      ${state.tasks.HomeAssistant ? `
      <div class="panel">
        <p class="panel-title">Home Assistant</p>
        <div class="catalog-chips" style="margin-bottom:14px">
          <button class="chip-filter ${ha.mode === 'vm' ? 'is-active' : ''}" data-ha-mode="vm">VM existente (.vdi)</button>
          <button class="chip-filter ${ha.mode === 'docker' ? 'is-active' : ''}" data-ha-mode="docker">Novo container Docker</button>
        </div>
        ${ha.mode === 'vm' ? `
          <p class="panel-sub">Caminho do disco (.vdi) da VM já existente.</p>
          <div class="field" style="display:flex; gap:8px; align-items:center">
            <input type="text" id="ha-vdi-path" style="flex:1" value="${escapeAttr(ha.vdiPath)}" placeholder="D:\\HomeAssistantOS\\haos_ova-18.2.vdi" />
            <button class="btn btn-ghost" id="ha-vdi-browse">Procurar</button>
          </div>
        ` : `
          <p class="panel-sub">Cria um Home Assistant Container novo (só Core, sem Supervisor/add-ons). Se você tiver um backup exportado (.tar), informe o caminho — ele é copiado pro container, mas a restauração final é feita por você na tela do Home Assistant.</p>
          <div class="field" style="display:flex; gap:8px; align-items:center">
            <input type="text" id="ha-backup-path" style="flex:1" value="${escapeAttr(ha.backupPath)}" placeholder="C:\\backups\\home-assistant.tar (opcional)" />
            <button class="btn btn-ghost" id="ha-backup-browse">Procurar</button>
          </div>
        `}
      </div>` : ''}

      <div class="panel">
        <p class="panel-title">Pasta de projetos</p>
        <p class="panel-sub">Onde os repositórios abaixo são clonados, e a base que o <code>g</code> do profile passa a usar (troca o <code>$HOME</code> padrão). Pode informar uma pasta que ainda não existe — ela é criada ao avançar.</p>
        <div class="field" style="display:flex; gap:8px; align-items:center">
          <input type="text" id="projects-folder-path" style="flex:1" value="${escapeAttr(state.projectsFolder)}" placeholder="D:\\projects" />
          <button class="btn btn-ghost" id="projects-folder-browse">Procurar</button>
        </div>
      </div>

      <div class="panel">
        <p class="panel-title">Repositórios a clonar</p>
        <p class="panel-sub">Um por linha. Pra renomear a pasta local: <code>url =&gt; nome-da-pasta</code>.</p>
        <div class="field">
          <textarea id="projects-text">${escapeHtml(state.projectsText)}</textarea>
        </div>
      </div>
    </div>`;
}

function bindReview() {
  const pf = document.getElementById('projects-folder-path');
  pf.addEventListener('change', () => { state.projectsFolder = pf.value; });
  document.getElementById('projects-folder-browse').addEventListener('click', () => Bridge.send('browse-folder', { field: 'projectsFolder' }));

  const pj = document.getElementById('projects-text');
  pj.addEventListener('change', () => { state.projectsText = pj.value; });

  $content.querySelectorAll('[data-ha-mode]').forEach((el) => {
    el.addEventListener('click', () => { state.homeAssistant.mode = el.dataset.haMode; render(); });
  });
  const vdiInput = document.getElementById('ha-vdi-path');
  if (vdiInput) vdiInput.addEventListener('change', () => { state.homeAssistant.vdiPath = vdiInput.value; });
  const vdiBrowse = document.getElementById('ha-vdi-browse');
  if (vdiBrowse) vdiBrowse.addEventListener('click', () => Bridge.send('browse-file', { field: 'haVdiPath', filter: 'Discos VirtualBox (*.vdi)|*.vdi|Todos os arquivos (*.*)|*.*' }));
  const backupInput = document.getElementById('ha-backup-path');
  if (backupInput) backupInput.addEventListener('change', () => { state.homeAssistant.backupPath = backupInput.value; });
  const backupBrowse = document.getElementById('ha-backup-browse');
  if (backupBrowse) backupBrowse.addEventListener('click', () => Bridge.send('browse-file', { field: 'haBackupPath', filter: 'Backup do Home Assistant (*.tar)|*.tar|Todos os arquivos (*.*)|*.*' }));
}

function installedApps() {
  const all = [...(state.config.wingetApps || []), ...state.extraApps];
  const seen = new Set();
  return all.filter((a) => {
    if (seen.has(a.id) || !state.selectedApps.has(a.id)) return false;
    seen.add(a.id);
    return true;
  });
}

function viewProgress() {
  const apps = installedApps();
  const byCategory = [];
  apps.forEach((a) => {
    let g = byCategory.find((x) => x.category === a.category);
    if (!g) { g = { category: a.category, apps: [] }; byCategory.push(g); }
    g.apps.push(a);
  });

  const otherSteps = (state.config.stepDefs || []).filter((s) => s.key !== 'WingetApps');

  return `
    <div class="screen screen-full">
      <h1 class="screen-kicker-free-title">Instalando<span class="text-gradient">…</span></h1>
      <p class="screen-lede">Pode deixar rodando — se o gh auth login pedir, uma janela do navegador vai abrir sozinha.</p>

      ${byCategory.map((g) => `
        <p class="panel-title" style="margin:22px 0 10px">${escapeHtml(CATEGORY_LABELS[g.category] || g.category)}</p>
        <div class="catalog-grid">
          ${g.apps.map((a) => progressCard(a)).join('')}
        </div>
      `).join('')}

      <p class="panel-title" style="margin:26px 0 10px">Outras etapas</p>
      <div class="panel" style="padding:8px 12px">
        ${otherSteps.map((s) => stepRow(s)).join('')}
      </div>

      <div class="panel" style="margin-top:20px">
        <p class="panel-title">Log</p>
        <div class="log-panel" id="log-panel">${state.installLog.map(escapeHtml).join('\n')}</div>
      </div>
    </div>`;
}

function progressCard(a) {
  const color = CATEGORY_COLORS[a.category] || '#93a1c4';
  const status = (state.appInstallStatus[a.id] || 'pending').toLowerCase();
  const icon = a.icon || `assets/icons/${iconFileName(a.id)}`;
  return `
    <div class="app-card progress-card status-${status}" data-id="${escapeAttr(a.id)}">
      <div class="app-card-top">
        <span class="app-card-icon"><img src="${icon}" alt="" onerror="this.remove()" /></span>
        <span class="progress-spinner" aria-hidden="true"></span>
      </div>
      <div class="app-card-name">${escapeHtml(a.label)}</div>
      <div class="app-card-meta"><span class="dot" style="background:${color}"></span>${escapeHtml(statusLabel(status))}</div>
    </div>`;
}

function statusLabel(status) {
  return { pending: 'Aguardando', running: 'Instalando…', ok: 'Instalado', fail: 'Falhou' }[status] || 'Aguardando';
}

function updateAppCardStatus(id, status) {
  const el = $content.querySelector(`.progress-card[data-id="${CSS.escape(id)}"]`);
  if (!el) return false;
  el.classList.remove('status-pending', 'status-running', 'status-ok', 'status-fail');
  const cls = status.toLowerCase();
  el.classList.add(`status-${cls}`);
  el.querySelector('.app-card-meta').innerHTML = `<span class="dot"></span>${escapeHtml(statusLabel(cls))}`;
  if (cls === 'ok' || cls === 'fail') {
    el.classList.remove('pop');
    // eslint-disable-next-line no-void
    void el.offsetWidth; // restart the CSS animation even if the class never left
    el.classList.add('pop');
  }
  return true;
}

function updateStepRow(key, status) {
  const el = $content.querySelector(`.step-row[data-key="${CSS.escape(key)}"]`);
  if (!el) return false;
  const map = { Running: ['running', 'Rodando'], Ok: ['ok', 'OK'], Fail: ['fail', 'Falhou'] };
  const [cls, label] = map[status] || ['pending', 'Pendente'];
  const pill = el.querySelector('.step-status');
  pill.className = `step-status ${cls}`;
  pill.textContent = label;
  return true;
}

function appendLogLine(text) {
  const panel = document.getElementById('log-panel');
  if (!panel) return false;
  panel.textContent += (panel.textContent ? '\n' : '') + text;
  panel.scrollTop = panel.scrollHeight;
  return true;
}

function stepRow(s) {
  const status = state.installResults[s.key] || 'Pending';
  const map = { Pending: ['pending', 'Pendente'], Running: ['running', 'Rodando'], Ok: ['ok', 'OK'], Fail: ['fail', 'Falhou'] };
  const [cls, label] = map[status] || map.Pending;
  return `<div class="step-row" data-key="${escapeAttr(s.key)}"><span class="step-status ${cls}">${label}</span><span>${escapeHtml(s.label)}</span></div>`;
}

function viewDone() {
  const items = state.launchable || [];
  return `
    <div class="screen">
      <h1 class="screen-kicker-free-title">Tudo <span class="text-gradient">pronto</span>.</h1>
      <p class="screen-lede">
        ${state.installReboot ? 'Reinicie o PC antes de usar WSL/Docker/VirtualBox. ' : ''}
        Log completo em <code>${escapeHtml(state.installLogFile)}</code>.
      </p>
      <div class="panel">
        <p class="panel-title">Abrir agora</p>
        <div class="app-grid" id="app-grid">
          ${items.map((it, i) => `<button class="app-tile" data-idx="${i}"><span class="app-tile-dot"></span>${escapeHtml(it.label)}</button>`).join('') || '<p class="panel-sub">Nada detectado pra abrir automaticamente.</p>'}
        </div>
      </div>
    </div>`;
}

function bindDone() {
  document.querySelectorAll('#app-grid .app-tile').forEach((el) => {
    el.addEventListener('click', () => {
      const item = state.launchable[Number(el.dataset.idx)];
      Bridge.send('open-app', item.action);
    });
  });
}

// content delegation for tasks screen (rendered fresh each time)
new MutationObserver(() => {
  const root = document.querySelector('.screen');
  if (root && root.querySelector('[data-task]')) bindTasksHandlers($content);
}).observe($content, { childList: true });

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
function escapeAttr(s) { return escapeHtml(s); }

init();
