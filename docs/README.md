# Documentação do Meu Uso

O que o app faz e como ele se comporta. Estas páginas descrevem **comportamento, não visual**, e são atualizadas junto com qualquer mudança nesse comportamento. Se o app e uma página daqui discordarem, é bug.

## O app

- [Painel](dashboard.md): a tela principal, com as linhas, os cliques que trocam a exibição, a reordenação e os atalhos de teclado
- [Barra de menus](menu-bar.md): como colocar métricas na barra de menus
- [Ajustes](settings.md): cada opção e o que ela muda
- [Atualização e cache](refreshing.md): quando os dados atualizam e o que acontece quando uma busca falha
- [Sincronização com o iCloud](icloud-sync.md): como o histórico de gasto é somado entre Macs (exige um build assinado)
- [Preços dos modelos](pricing.md): como as linhas de gasto calculam o preço dos tokens e de onde vêm os valores
- [Atualizações](updates.md): como instalar e atualizar o app hoje e como as atualizações automáticas funcionam nas releases
- [Privacidade](privacy.md): com quem o app fala pela rede e o que ele guarda no seu Mac (não há telemetria)

## Integrações

- [Interface de linha de comando](cli.md): leituras únicas do uso, do cache ou forçadas, para agentes e scripts
- [API HTTP local](local-http-api.md): leia seu uso em outros apps por `127.0.0.1:6737`
- [Proxy](proxy.md): passe as requisições aos provedores por SOCKS5 ou HTTP(S)

## Provedores

O que cada provedor acompanha, de onde vêm as credenciais e o que fazer quando aparece um erro.

- [Antigravity](providers/antigravity.md)
- [Claude](providers/claude.md)
- [Codex](providers/codex.md)
- [Copilot](providers/copilot.md)
- [Cursor](providers/cursor.md)
- [Devin](providers/devin.md)
- [Grok](providers/grok.md)
- [Ollama](providers/ollama.md)
- [OpenCode](providers/opencode.md)
- [OpenRouter](providers/openrouter.md)
- [Z.ai](providers/zai.md)

## Para desenvolvedores

Como o app é construído e como estendê-lo.

- [Arquitetura](architecture.md): a raiz de composição, os stores, o fluxo de um provedor e a ponte com o AppKit
- [Como adicionar um provedor](adding-a-provider.md): o contrato das métricas e os passos para registrar, testar e documentar
- [Depuração e captura de logs](debugging.md): como rodar um build local e acompanhar os logs
- [Logs](logging.md): o arquivo de log, os níveis, as etiquetas por subsistema e o que nunca vai para o log
- [Glossário e guia de tradução](glossario.md): termos, estilo e como colocar um texto novo na tela em português
