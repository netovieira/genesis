import { createFileRoute } from "@tanstack/react-router";
import {
  ArrowDown,
  ArrowRight,
  Check,
  ChevronRight,
  CircleCheck,
  Clock3,
  Download,
  ExternalLink,
  Gamepad2,
  Github,
  Globe,
  Linkedin,
  Menu,
  ShieldCheck,
  Sparkles,
  Terminal,
  X,
} from "lucide-react";
import { useState } from "react";

import profileAssetUrl from "../assets/anthero-profile.jpg";

const GITHUB = "https://github.com/theroverse/genesis";
const RELEASES = "https://github.com/theroverse/genesis/releases/latest";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Genesis — o setup pós-formatação do Windows 11" },
      {
        name: "description",
        content:
          "Assistente de 17 etapas que instala terminal, navegadores, jogos e a suíte Claude Code num Windows 11 recém-formatado — marque o que quiser, revise numa página só, clique em instalar.",
      },
      { property: "og:title", content: "Genesis — o setup pós-formatação do Windows 11" },
      {
        property: "og:description",
        content: "Escolha tudo o que entra no seu PC recém-formatado, revise numa página só, e clique em instalar.",
      },
      { property: "og:type", content: "website" },
      { property: "og:url", content: "https://theroverse.github.io/genesis/" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
    links: [{ rel: "canonical", href: "https://theroverse.github.io/genesis/" }],
  }),
  component: Index,
});

const features = [
  ["Catálogo agrupado por categoria", "68 apps reais via winget, com ícone, versão e descrição — marque o que quiser"],
  ["Apps já instalados ficam travados", "Detecta o que já existe na máquina (winget list) e não deixa desmarcar sem querer"],
  ["Busca ao vivo pra mais apps", "Não achou no catálogo? Busca contra a API do winget.run, com ícone e descrição reais"],
  ["Ponto de restauração antes de tudo", "Se algo der errado, é só voltar — o Windows cuida disso sozinho"],
  ["Ajusta seu profile do PowerShell", "Copia o profile, cria a pasta de projetos e reescreve o goto/g pra apontar pra ela"],
  ["Minimiza pra bandeja", "Deixa instalando em segundo plano — a janela volta sozinha quando termina"],
  ["Suíte Claude Code inclusa", "Instala thero, Athena e Zeus — o Engineering OS que prepara o Claude Code pra trabalho sério"],
  ["Arquivo único, sem instalador", "Genesis.exe roda direto — pede UAC sozinho, extrai o que precisa e não deixa lixo"],
];

// Glifo real do Genesis (mesmo de theroverse/src/components/icons/
// EcosystemIcon.tsx e das cores oficiais em ecosystem.ts: #A855F7/#C084FC) -
// o mesmo diamante de 4 pontas usado no genesis-icon-app.svg / ícone do exe.
function GenesisMark({ size = 40 }: { size?: number }) {
  return (
    <span className="brand-mark" style={{ width: size, height: size }} aria-hidden="true">
      <svg viewBox="0 0 64 64" width={Math.round(size * 0.85)} height={Math.round(size * 0.85)}>
        <path d="M32 7 L57 32 L32 57 L7 32 Z" fill="#A855F7" fillOpacity="0.12" stroke="#A855F7" strokeWidth="3" strokeLinejoin="round" />
        <path d="M32 14 V50 M14 32 H50" stroke="#C084FC" strokeWidth="1.5" strokeDasharray="3 3" strokeOpacity="0.55" />
        <path d="M32 18 Q32 32 46 32 Q32 32 32 46 Q32 32 18 32 Q32 32 32 18 Z" fill="#A855F7" fillOpacity="0.3" stroke="#A855F7" strokeWidth="2.75" strokeLinejoin="round" />
        <circle cx="32" cy="7" r="2.5" fill="#A855F7" />
        <circle cx="57" cy="32" r="2.5" fill="#A855F7" />
        <circle cx="32" cy="57" r="2.5" fill="#A855F7" />
        <circle cx="7" cy="32" r="2.5" fill="#A855F7" />
        <circle cx="32" cy="32" r="2.5" fill="#C084FC" />
      </svg>
    </span>
  );
}

function Header() {
  const [open, setOpen] = useState(false);
  return (
    <header className="site-header">
      <a href="#top" className="brand" aria-label="Genesis, início">
        <GenesisMark size={40} />
        <span>genesis</span>
      </a>
      <nav className="desktop-nav" aria-label="Navegação principal">
        <a href="#suite">O que instala</a>
        <a href="#recursos">Recursos</a>
        <a href="#comparativo">Comparativo</a>
        <a href="#autor">Autor</a>
      </nav>
      <a className="header-cta" href={RELEASES} target="_blank" rel="noreferrer">
        <Download size={17} /> Baixar <ExternalLink size={13} />
      </a>
      <button className="menu-button" type="button" onClick={() => setOpen(!open)} aria-label={open ? "Fechar menu" : "Abrir menu"}>
        {open ? <X /> : <Menu />}
      </button>
      {open && (
        <nav className="mobile-nav" aria-label="Navegação móvel">
          <a href="#suite" onClick={() => setOpen(false)}>O que instala</a>
          <a href="#recursos" onClick={() => setOpen(false)}>Recursos</a>
          <a href="#comparativo" onClick={() => setOpen(false)}>Comparativo</a>
          <a href="#autor" onClick={() => setOpen(false)}>Autor</a>
          <a href={RELEASES} target="_blank" rel="noreferrer">Baixar Genesis.exe</a>
        </nav>
      )}
    </header>
  );
}

function Index() {
  return (
    <main id="top">
      <Header />

      <section className="hero shell">
        <div className="hero-copy">
          <div className="eyebrow"><span /> PowerShell + WebView2 · Windows 11 · Arquivo único</div>
          <h1>Windows 11 <small>recém-formatado</small>,<br /><em>pronto pra trabalhar em minutos.</em></h1>
          <p className="hero-lede">
            Marque o que quiser instalar — apps, terminal, WSL, SSH, o profile do PowerShell e a suíte Claude Code — revise tudo numa página só, e clique em "Instalar agora". O resto o Genesis faz sozinho.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={RELEASES} target="_blank" rel="noreferrer"><Download size={18} /> Baixar Genesis.exe</a>
            <a className="button button-secondary" href={GITHUB} target="_blank" rel="noreferrer"><Github size={18} /> Ver código</a>
          </div>
          <div className="hero-proof">
            <span><CircleCheck size={16} /> Ponto de restauração antes de tudo</span>
            <span><CircleCheck size={16} /> Pede UAC sozinho, sem instalador</span>
            <span><CircleCheck size={16} /> 68 apps reais no catálogo</span>
          </div>
        </div>

        <div className="hero-visual" aria-label="Demonstração do fluxo de instalação do Genesis">
          <div className="terminal-window">
            <div className="terminal-bar"><i /><i /><i /><span>Genesis - setup pós-formatação</span></div>
            <div className="terminal-body">
              <p><b>$</b> .\genesis.ps1</p>
              <p className="muted">==&gt; Ponto de restauração</p>
              <p><span className="athena-dot">●</span> OK: snapshot criado</p>
              <div className="terminal-divider" />
              <p><strong>✓</strong> Apps via winget (24 selecionados)</p>
              <p><strong>✓</strong> WSL2, SSH, profile do PowerShell</p>
              <p><strong>✓</strong> Claude Code Suite (thero, Athena, Zeus)</p>
              <p className="ready">Pronto. Reinicie quando quiser. <span className="cursor" /></p>
            </div>
          </div>
          <div className="floating-chip chip-one"><ShieldCheck size={15} /> nunca apaga nada seu</div>
          <div className="floating-chip chip-two"><CircleCheck size={15} /> roda sem supervisão</div>
        </div>
      </section>

      <section className="trust-strip" aria-label="Benefícios principais">
        <div className="shell trust-grid">
          <div><strong>17 etapas</strong><span>sistema, apps, dev, Claude Code</span></div>
          <div><strong>68 apps</strong><span>reais no catálogo, via winget</span></div>
          <div><strong>1 clique</strong><span>"Instalar agora" e o resto é sozinho</span></div>
          <div><strong>Zero instalador</strong><span>Genesis.exe é arquivo único</span></div>
        </div>
      </section>

      <section className="problem-section shell">
        <div className="section-kicker">O problema não é formatar, é tudo depois</div>
        <div className="problem-heading">
          <h2>Uma tarde inteira<br />clicando "Avançar" e "Aceito".</h2>
          <p>Chega de passar horas fechando popups do Edge pra baixar o Chrome com instalador falso, um app de cada vez, torcendo pra não esquecer nenhum.</p>
        </div>
        <div className="before-after">
          <article className="pain-column">
            <span className="state-label">Sem Genesis</span>
            <ul>
              <li><X size={16} /> Um app de cada vez, procurando site oficial</li>
              <li><X size={16} /> Configura WSL, SSH e profile na mão, de memória</li>
              <li><X size={16} /> Instala o Claude Code e esquece de preparar contexto</li>
              <li><X size={16} /> Descobre o que faltou dias depois, no meio de um projeto</li>
            </ul>
          </article>
          <div className="transformation-arrow"><ArrowRight /></div>
          <article className="gain-column">
            <span className="state-label">Com Genesis</span>
            <ul>
              <li><Check size={16} /> Catálogo inteiro numa tela, marcado do seu jeito</li>
              <li><Check size={16} /> WSL, SSH, profile e projetos configurados sozinhos</li>
              <li><Check size={16} /> Claude Code já sai com a suíte thero/Athena/Zeus</li>
              <li><Check size={16} /> Uma página de revisão antes de qualquer mudança real</li>
            </ul>
          </article>
        </div>
      </section>

      <section id="suite" className="suite-section">
        <div className="shell">
          <div className="section-head light">
            <div><span className="section-kicker">Quatro pilares, uma instalação</span><h2>Sistema. Navegadores. Jogos. Claude Code.</h2></div>
            <p>Cada quadrante do ícone do Genesis representa uma frente que ele prepara sozinho — sem pular nenhuma.</p>
          </div>
          <div className="suite-flow">
            <article className="suite-item thero-item">
              <div className="suite-number">01</div>
              <div className="suite-icon"><Terminal /></div>
              <div className="suite-copy"><span>Sistema</span><h3>Terminal & base</h3><p>Ponto de restauração, WSL2, Starship, PowerToys, execution policy e o profile do PowerShell — sua base de trabalho pronta.</p></div>
            </article>
            <article className="suite-item athena-item">
              <div className="suite-number">02</div>
              <div className="suite-icon"><Globe /></div>
              <div className="suite-copy"><span>Navegar</span><h3>Navegadores</h3><p>Chrome, Firefox ou Opera — o que você marcar, já configurado como padrão se quiser.</p></div>
            </article>
            <article className="suite-item zeus-item">
              <div className="suite-number">03</div>
              <div className="suite-icon"><Gamepad2 /></div>
              <div className="suite-copy"><span>Jogar</span><h3>Jogos</h3><p>Steam, Epic, Battle.net, EA App, Minecraft — as lojas que você usa, sem procurar cada instalador.</p></div>
            </article>
            <article className="suite-item genesis-item">
              <div className="suite-number">04</div>
              <div className="suite-icon"><Sparkles /></div>
              <div className="suite-copy"><span>Codar com IA</span><h3>Claude Code Suite</h3><p>thero, Athena e Zeus — o Engineering OS que prepara o Claude Code pra trabalho sério desde o primeiro comando.</p></div>
              <a href="https://theroverse.github.io/" target="_blank" rel="noreferrer">Conhecer o Theroverse <ArrowRight size={16} /></a>
            </article>
          </div>
          <div className="flow-diagram" aria-label="Fluxo de instalação do Genesis">
            <div className="flow-step"><span className="flow-index">01</span><strong>Ponto de restauração</strong><p>rede de segurança antes de tudo</p></div>
            <ChevronRight className="flow-arrow" />
            <div className="flow-step"><span className="flow-index">02</span><strong>Catálogo de apps</strong><p>68 apps via winget, marcados por você</p></div>
            <ChevronRight className="flow-arrow" />
            <div className="flow-step"><span className="flow-index">03</span><strong>Sistema & dev</strong><p>WSL, SSH, profile, pasta de projetos</p></div>
            <ChevronRight className="flow-arrow" />
            <div className="flow-step"><span className="flow-index">04</span><strong>Claude Code Suite</strong><p>thero instala Athena e Zeus junto</p></div>
            <ChevronRight className="flow-arrow" />
            <div className="flow-step"><span className="flow-index">05</span><strong>Pronto pra usar</strong><p>reinicia se pedir, e já era</p></div>
          </div>
        </div>
      </section>

      <section id="comparativo" className="comparison-section shell">
        <div className="section-head">
          <div><span className="section-kicker">Menos clique, mais café</span><h2>O tempo economizado<br />não é promessa, é aritmética.</h2></div>
          <p>Sem plano, cada app é uma busca, um download e um "Avançar, Avançar, Concluir" diferente. Com Genesis, a decisão já foi tomada antes.</p>
        </div>
        <div className="scenario-note"><Sparkles size={15} /> Cenário ilustrativo — os números abaixo demonstram o mecanismo, não um benchmark universal.</div>
        <div className="comparison-grid">
          <div className="comparison-card without">
            <div className="comparison-title"><span>Setup manual</span><small>um app de cada vez</small></div>
            <div className="metric"><div><span>Apps instalados por vez</span><strong>1</strong><small>ilustrativo</small></div><div className="meter"><i style={{ width: "85%" }} /></div></div>
            <div className="metric"><div><span>Passos até a máquina pronta</span><strong>50+</strong><small>cliques</small></div><div className="meter"><i style={{ width: "80%" }} /></div></div>
            <div className="timeline"><Clock3 /><span>buscar → baixar → instalar → repetir</span></div>
          </div>
          <div className="comparison-card with">
            <div className="comparison-title"><span>A mesma máquina com Genesis</span><small>fluxo orientado</small></div>
            <div className="metric"><div><span>Apps instalados por vez</span><strong>68</strong><small>de uma vez</small></div><div className="meter"><i style={{ width: "20%" }} /></div></div>
            <div className="metric"><div><span>Passos até a máquina pronta</span><strong>3</strong><small>marcar, revisar, instalar</small></div><div className="meter"><i style={{ width: "10%" }} /></div></div>
            <div className="timeline"><Download /><span>marcar → revisar → instalar agora</span></div>
          </div>
        </div>
        <div className="mechanism-row">
          <div><Terminal /><strong>Sistema</strong><span>WSL, SSH, profile, restauração</span></div>
          <div><Download /><strong>Catálogo</strong><span>68 apps reais, agrupados por categoria</span></div>
          <div><ShieldCheck /><strong>Você</strong><span>revisa antes de instalar agora</span></div>
        </div>
      </section>

      <section id="recursos" className="skills-section">
        <div className="shell skills-layout">
          <div className="skills-copy">
            <span className="section-kicker">Feito pra rodar sem babá</span>
            <h2>Recursos pensados pra reduzir clique.</h2>
            <p>Cada detalhe do Genesis existe porque formatar de novo não devia ser um sábado perdido.</p>
            <div className="context-rule"><ShieldCheck /><div><strong>Nunca apaga nada seu</strong><span>Sempre cria ponto de restauração e faz backup antes de mudar algo existente.</span></div></div>
          </div>
          <div className="skills-list">
            {features.map(([name, description]) => (
              <div className="skill-row" key={name}><span className="skill-check"><Check size={14} /></span><div><strong>{name}</strong><span>{description}</span></div></div>
            ))}
          </div>
        </div>
      </section>

      <section id="instalar" className="install-section shell">
        <div className="install-grid">
          <div>
            <span className="section-kicker">Comece em minutos</span>
            <h2>Baixe o .exe.<br />Marque. Instale.</h2>
            <p>Sem instalador, sem dependência prévia. O Genesis.exe pede elevação (UAC) sozinho, extrai o que precisa e roda a mesma lógica tanto na janela quanto no console.</p>
            <div className="requirements"><span><Check /> Windows 11</span><span><Check /> Conexão com a internet</span><span><Clock3 size={14} /> ~30-40 min pra máquina pronta</span></div>
          </div>
          <div className="install-terminal">
            <div className="terminal-bar"><i /><i /><i /><span>download</span></div>
            <div className="install-commands">
              <a className="button button-primary" href={RELEASES} target="_blank" rel="noreferrer" style={{ width: "100%", justifyContent: "center" }}>
                <Download size={18} /> Baixar Genesis.exe
              </a>
            </div>
            <div className="install-result"><CircleCheck /> Arquivo único · Pede UAC sozinho · Nada fica pela metade</div>
          </div>
        </div>
        <div className="mode-grid">
          <div><code>Genesis.exe</code><span>janela nativa (WebView2), o fluxo completo</span></div>
          <div><code>genesis.ps1</code><span>mesma lógica, direto no console</span></div>
          <div><code>gui\wizard\dev.ps1</code><span>preview da interface, nada é instalado</span></div>
          <div><code>build.ps1</code><span>gera o .exe a partir do código-fonte</span></div>
        </div>
      </section>

      <section id="autor" className="author-section">
        <div className="shell author-grid">
          <div className="author-photo-wrap"><img src={profileAssetUrl} alt="Anthero Vieira Neto" width={200} height={200} loading="lazy" /><span>18 anos<br />construindo<br />software</span></div>
          <div className="author-copy">
            <span className="section-kicker">Código nascido de experiência real</span>
            <h2>Construído por quem já formatou demais.</h2>
            <p className="author-lede">Sou <strong>Anthero Vieira Neto</strong>, arquiteto de software sênior e DevOps Engineer. Trabalho com TypeScript, Python, Kubernetes e IA aplicada a produtos reais — do código à cultura de entrega.</p>
            <p>O Genesis nasceu da mesma vontade de eliminar trabalho repetitivo que gerou o Thero, a Athena e o Zeus — só que apontada pro primeiro boot depois de formatar, não pro código. Terraforma a máquina pra que a suíte Claude Code já chegue num terreno pronto.</p>
            <div className="author-links">
              <a href="https://www.linkedin.com/in/anthero-vieira-neto-aa7a6b8a" target="_blank" rel="noreferrer"><Linkedin size={18} /> LinkedIn <ExternalLink size={13} /></a>
              <a href="https://github.com/netovieira" target="_blank" rel="noreferrer"><Github size={18} /> GitHub <ExternalLink size={13} /></a>
            </div>
          </div>
        </div>
      </section>

      <section className="final-cta">
        <div className="shell final-inner">
          <GenesisMark size={72} />
          <span className="section-kicker">Sua próxima formatação já pode ser a última chata</span>
          <h2>Terraforme a máquina,<br />não perca o sábado.</h2>
          <p>Open source, transparente e pronto pro seu próximo Windows 11 recém-formatado.</p>
          <div className="hero-actions">
            <a className="button button-primary" href={RELEASES} target="_blank" rel="noreferrer"><Download size={18} /> Baixar Genesis.exe</a>
            <a className="button button-dark-outline" href={GITHUB} target="_blank" rel="noreferrer">Ver código-fonte <ArrowRight size={17} /></a>
          </div>
        </div>
      </section>

      <section className="final-cta theroverse-cta">
        <div className="shell final-inner">
          <span className="section-kicker">Parte de um ecossistema maior</span>
          <h2>Genesis é uma peça do <em>Theroverse</em>.</h2>
          <p>Genesis terraforma a máquina e já entrega thero, Athena e Zeus instalados — conheça as outras ferramentas abertas do ecossistema.</p>
          <div className="hero-actions">
            <a className="button button-primary" href="https://theroverse.github.io/" target="_blank" rel="noreferrer">Explorar o Theroverse <ArrowRight size={17} /></a>
          </div>
        </div>
      </section>

      <footer>
        <div className="shell footer-inner">
          <a href="#top" className="brand"><GenesisMark size={36} /><span>genesis</span></a>
          <p>O setup pós-formatação do Windows 11.</p>
          <div><a href="https://theroverse.github.io/" target="_blank" rel="noreferrer">Theroverse</a><a href="https://theroverse.github.io/thero/" target="_blank" rel="noreferrer">Thero</a><a href="https://theroverse.github.io/athena/" target="_blank" rel="noreferrer">Athena</a><a href="https://theroverse.github.io/zeus/" target="_blank" rel="noreferrer">Zeus</a><a href={GITHUB} target="_blank" rel="noreferrer">GitHub</a></div>
          <small>© 2026 Anthero Vieira Neto</small>
        </div>
      </footer>
    </main>
  );
}
