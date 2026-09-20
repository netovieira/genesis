# "run dev" da wizard: abre index.html direto no navegador padrao.
# Sem servidor, sem build - o arquivo detecta sozinho que nao esta dentro
# do WebView2 e cai em modo preview (dados de exemplo, instalacao
# simulada, nada de real acontece no sistema).
Start-Process (Join-Path $PSScriptRoot 'index.html')
