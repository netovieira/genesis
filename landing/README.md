# Zeus — landing page

Site estático (TanStack Start, SSG) publicado em `https://theroverse.github.io/zeus/`.

## Rodando localmente

```bash
npm install
npm run dev
```

## Build de produção

```bash
npm run build
```

Emite o site totalmente pré-renderizado em `dist/client`, pronto para GitHub Pages
sob o sub-caminho `/zeus/` (ver `BASE_PATH` em `vite.config.ts`).

Construído com TanStack Start, TypeScript, React e Tailwind CSS — mesma base do
`thero/landing`, para manter as três landing pages da suíte (Thero, Athena, Zeus)
consistentes.
