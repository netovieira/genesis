# Prompts de imagem — assets visuais do instalador

Nenhuma ferramenta de geração de imagem está disponível neste ambiente,
então os únicos assets visuais que faltam pra deixar isso 100% profissional
são externos — gere com o modelo de imagem que preferir (Midjourney,
DALL-E, Ideogram, etc.) e salve nos caminhos indicados. O resto da
interface (telas, ícones de checklist, cores) já é só CSS/SVG — não
depende de nenhuma imagem gerada.

## 1. Ícone do `Genesis.exe` (já resolvido — só refaça se quiser trocar a arte)

O ícone já existe e é versionado: `gui/Genesis.ico`, gerado de
`genesis-icon-app-512x512.png` (na raiz do projeto) por
`scripts/make-exe-icon.ps1` — e o `build.ps1` chama esse script sozinho
quando o `.ico` está faltando. O prompt abaixo serve pra gerar uma arte
alternativa no mesmo espírito.

**Prompt:**

> Minimalist app icon for a Windows installer/setup tool, flat vector
> style, no text, no letters. A single geometric mark suggesting "a
> machine being assembled/configured" — think a hexagonal or rounded-
> square badge containing an abstract circuit/checklist motif (a few
> connected nodes, or a checkmark integrated into a gear-like shape).
> Color palette: deep navy background (#0a0e1a to #10162a gradient),
> single accent gradient from cyan (#22d3ee) to violet (#8b5cf6) on the
> mark itself. Flat design, no drop shadows, no photorealism, no gloss/
> glass effect, no gradients on the background beyond the two named
> colors. Must read clearly at 16x16px (favicon size) — keep the shape
> extremely simple, 1-2 strokes max. Square canvas, centered composition,
> generous padding (mark occupies ~60% of canvas).

**Exportar como:**
- Gere em alta resolução (1024×1024 PNG) e depois converta pra `.ico`
  multi-resolução (16/32/48/256px) com uma ferramenta como
  [icoconvert.com](https://icoconvert.com) ou `magick convert` (ImageMagick).
- Salvar em: `gui/Genesis.ico` — ou salve o PNG 1024×1024 como
  `genesis-icon-app-512x512.png` na raiz do projeto e rode
  `scripts/make-exe-icon.ps1`, que já monta o `.ico` multi-resolução.

O `build.ps1` já passa o ícone pro `Invoke-ps2exe` (`-iconFile
(Join-Path $Root 'gui\Genesis.ico')`), então trocar a arte não exige editar
mais nada.

## 2. Fundo do "Bem-vindo" / "Sobre o autor" (opcional)

As telas de abertura hoje usam só gradientes CSS (`#app` no
`gui/wizard/style.css`). Um fundo sutil aqui é opcional, não bloqueia
nada — só eleve se quiser.

**Prompt:**

> Abstract dark technical background, subtle, meant to sit BEHIND text
> (very low contrast, mostly negative space). Deep navy base (#0a0e1a),
> extremely faint circuit-board / network-graph linework in cyan
> (#22d3ee) and violet (#8b5cf6) at 8-15% opacity, concentrated in the
> top-right and bottom-left corners, fading to pure flat navy in the
// center 60% of the frame so text stays readable on top. No visible
> objects, no characters, no logos, no readable text. Widescreen 16:9,
> 1920x1080.

**Salvar em:** `gui/wizard/assets/hero-bg.jpg` e referenciar em
`.screen-lede`'s parent ou `#content`'s background em `style.css` (não
está referenciado ainda — é puramente opcional).

## 3. Screenshots reais do Athena e do Zeus (não é imagem gerada)

As telas do thero já usam a arte real (`thero-mark.png` +
`thero-system.jpg`, copiados de `~/.myscripts/thero/landing/src/assets/`).
Athena e Zeus ainda não têm um equivalente de `-system.jpg` nos
respectivos `landing/`, então as telas deles usam um fundo gerado em CSS
(malha de gradientes na cor de cada marca) em vez de screenshot real.

Quando esses dois landing pages tiverem uma captura de tela real da
ferramenta em uso, copie pro mesmo padrão:
- `gui/wizard/assets/athena-system.jpg`
- `gui/wizard/assets/zeus-system.jpg`

E em `gui/wizard/app.js`, troque `bg: { type: 'mesh' }` por
`bg: { type: 'image', src: 'assets/athena-system.jpg' }` (idem pro Zeus)
dentro de `SUITE_CONTENT`. Isso não é um prompt de geração — é uma
screenshot real do produto, pra manter a mesma honestidade visual que o
thero já tem.
