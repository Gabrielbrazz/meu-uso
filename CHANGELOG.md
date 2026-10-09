# Changelog

Todas as mudanças relevantes do Meu Uso ficam registradas aqui. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), e as versões seguem o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não lançado]

Ponto de partida: fork do [OpenUsage](https://github.com/robinebers/openusage) v0.7.14 (commit `cb21465`), de Robin Ebers, sob licença MIT. O histórico anterior a este ponto está no repositório original.

### Alterado
- Nome: OpenUsage passa a ser Meu Uso. Bundle ID `io.github.gabrielbrazz.meuuso`, pastas `~/Library/Application Support/MeuUso` e `~/Library/Logs/MeuUso`, configuração em `~/.meu-uso` e `~/.config/meu-uso`, CLI `meu-uso`, API local em `127.0.0.1:6737`. Nada disso colide com uma instalação do OpenUsage no mesmo Mac.
- Versão reiniciada em 0.1.0.
- Marca e ícone provisórios: um anel de uso com uma abertura e um ponto, desenhado do zero (`script/brand/mark.py`). O ícone clássico (`.icns`) vai em todo build; o ícone Liquid Glass depende de um `actool` que compile `assets/AppIcon.icon`.
- Interface em português do Brasil, sempre, qualquer que seja o idioma do Mac. O texto sai de `assets/Localization/pt-BR.lproj`, e o CI acusa texto novo sem tradução.
- Números, moeda e datas no padrão brasileiro: "US$ 1.234,56", "12,9 mil", "7 de out.", "17:30".

### Removido
- Telemetria: o app não envia dados de uso nem relatórios de falha para serviço nenhum.
- Infraestrutura do projeto original: workflows de política de PR, Pullfrog e stale, publicação no GitHub Pages e a limpeza de agentes da antiga versão Tauri.

### Segurança
- A API local não atende mais páginas da web. Herdado do OpenUsage, o `Access-Control-Allow-Origin: *` deixava qualquer site aberto no navegador ler uso, gasto, planos e nomes de conta (que podem ser e-mails) enquanto o app rodava. Agora as respostas não trazem CORS, `OPTIONS` não responde mais ao preflight, e pedidos com `Origin` ou com `Host` diferente de `127.0.0.1:6737` e `localhost:6737` recebem 403. `curl`, scripts, apps nativos e o comando `meu-uso` seguem funcionando.
