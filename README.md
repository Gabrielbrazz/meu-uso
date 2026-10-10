# Meu Uso

Acompanhe o uso das suas assinaturas de IA direto da barra de menus do Mac, em português.

O Meu Uso mostra quanto você já usou dos seus planos de IA para programar: limites de sessão e semanais, créditos e gasto, tudo num painel só. Você também pode fixar as métricas mais importantes direto na barra de menus.

> O Meu Uso é um fork não oficial do [OpenUsage](https://github.com/robinebers/openusage), de Robin Ebers. Veja [Créditos](#créditos-e-marca).

## Provedores

- **[Antigravity](docs/providers/antigravity.md):** cotas compartilhadas de Gemini e Claude, janelas de 5 horas e semanal, e gasto diário local.
- **[Claude](docs/providers/claude.md):** sessão, semanal, limites por modelo, uso extra e gasto diário local.
- **[Codex](docs/providers/codex.md):** sessão, semanal, créditos e gasto diário local.
- **[Copilot](docs/providers/copilot.md):** créditos de IA, uso extra, cobrança da organização, chat e autocompletar.
- **[Cursor](docs/providers/cursor.md):** créditos, uso total, Grok Bot, modelos do Cursor e de terceiros, requisições, sob demanda e gasto por dia.
- **[Devin](docs/providers/devin.md):** cota semanal e diária, saldo de uso extra.
- **[Grok](docs/providers/grok.md):** cota semanal compartilhada, pagamento por uso e gasto diário local.
- **[Ollama](docs/providers/ollama.md):** limites de sessão e semanal do Ollama Cloud e gasto recente.
- **[OpenCode](docs/providers/opencode.md):** limites de sessão, semanal e mensal do Go, gasto no Zen e gasto diário local.
- **[OpenRouter](docs/providers/openrouter.md):** saldo de créditos e gasto diário, semanal e mensal (chave de API).
- **[Z.ai](docs/providers/zai.md):** cotas de sessão, semanal e de busca na web (GLM Coding Plan, chave de API).

A maioria dos provedores usa as credenciais que já estão no seu Mac (nas chaves do macOS, em arquivos de login e no estado dos apps), sem login extra. As exceções são OpenRouter e Z.ai: eles não deixam credencial local para reaproveitar, então você informa uma chave de API.

## Instalação

No Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/Gabrielbrazz/meu-uso/main/script/install.sh | bash
```

O script baixa a versão mais recente das [releases do GitHub](https://github.com/Gabrielbrazz/meu-uso/releases), confere o checksum, instala o app em Aplicativos e abre. Precisa do macOS 15 (Sequoia) ou mais novo.

Para atualizar, rode `meu-uso update`. Quando sai uma versão nova, o app avisa no topo da janela e copia o comando para você.

O Meu Uso ainda não tem assinatura da Apple. O macOS bloqueia apps assim quando eles vêm do navegador, mas não quando vêm do Terminal, por isso a instalação é por comando. Nessa versão a sincronização pelo iCloud fica indisponível, e o macOS pode pedir de novo o acesso às chaves depois de uma atualização. Veja [Atualizações](docs/updates.md).

### Compilar do código

```bash
git clone https://github.com/Gabrielbrazz/meu-uso.git && cd meu-uso && ./script/build_and_run.sh
```

O script compila e abre o app de desenvolvimento a partir de `dist/`, sem instalar nada em Aplicativos. Precisa do Xcode 26.

Cada PR também gera no CI um build de desenvolvimento, o artefato `MeuUso-dev`. Veja como usar em [Testar sem Xcode local](docs/debugging.md#testar-sem-xcode-local).

## Recursos

- **Barra de menus:** fixe até duas métricas por provedor, como texto compacto ou minibarras.
- **Painel:** medidores agrupados por provedor, com contagem regressiva da renovação e indicador de ritmo. Clique num valor para alternar entre usado e restante, ou entre prazo relativo e horário.
- **Atalho global:** abra o painel de qualquer lugar.
- **Personalização:** ligue e desligue provedores e métricas e reordene arrastando.
- **Atualização em segundo plano:** os últimos valores aparecem na hora, e a atualização roda a cada 5 minutos.
- **[CLI](docs/cli.md):** agentes e scripts leem os limites em JSON com `meu-uso`, sem o app precisar estar aberto.
- **[API local](docs/local-http-api.md):** outros apps leem os limites em `127.0.0.1:6737/v1/limits`. Ela só escuta conexões locais.
- **[Proxy](docs/proxy.md):** requisições aos provedores podem passar por SOCKS5 ou HTTP(S), configurado em `~/.meu-uso/config.json`.

## Privacidade

- **Sem telemetria:** o Meu Uso não envia dados de uso nem relatórios de falha para serviço nenhum.
- **Credenciais:** servem só para as chamadas ao provedor correspondente e não saem do seu Mac por nenhum outro caminho.
- **Tabelas de preço:** para estimar gastos, o app baixa tabelas públicas de preço de modelos do [LiteLLM](https://github.com/BerriAI/litellm), do [models.dev](https://models.dev) e deste repositório. Detalhes em [Preços](docs/pricing.md).
- **Sincronização com o iCloud:** é opcional, vem desligada e usa a sua conta do iCloud. Ainda não funciona nos builds de desenvolvimento.

Mais em [Privacidade](docs/privacy.md).

## Documentação

O comportamento do app está descrito em [docs/](docs/README.md): [painel](docs/dashboard.md), [barra de menus](docs/menu-bar.md), [ajustes](docs/settings.md), [atualização e cache](docs/refreshing.md), [CLI](docs/cli.md), [API local](docs/local-http-api.md), [proxy](docs/proxy.md) e uma página por provedor.

Para mexer no código, veja:
- [arquitetura](docs/architecture.md);
- [como adicionar um provedor](docs/adding-a-provider.md);
- [depuração e logs](docs/debugging.md);
- o [glossário e guia de tradução](docs/glossario.md).

## Desenvolvimento

```bash
swift build && swift test
```

É um pacote SwiftPM, sem projeto do Xcode, em Swift 6 com concorrência estrita. O conteúdo é SwiftUI dentro de um `NSStatusItem` e um `NSPanel` do AppKit. O app e a CLI compartilham um módulo: cada provedor implementa o protocolo `ProviderRuntime` (credenciais → cliente → mapeamento → `ProviderSnapshot`).

As convenções de engenharia estão em [AGENTS.md](AGENTS.md). O texto da interface sai de uma tabela pt-BR; as regras estão no [glossário](docs/glossario.md).

## Contribuindo

Issues e PRs são bem-vindos. Leia o [CONTRIBUTING.md](CONTRIBUTING.md) antes de abrir um PR. Falhas de segurança devem ser relatadas em particular, como explica o [SECURITY.md](SECURITY.md).

## Créditos e marca

O Meu Uso é um fork não oficial do [OpenUsage](https://github.com/robinebers/openusage), criado por Robin Ebers e distribuído sob a licença MIT. "OpenUsage" e o logo do OpenUsage são marcas de Robin Ebers. Este projeto não é afiliado a ele nem endossado por ele.

O código herdado mantém o aviso de copyright original no [LICENSE](LICENSE). A marca e o ícone do Meu Uso são próprios, gerados por [`script/brand/mark.py`](script/brand/mark.py).

O visual segue o design system Braz. As fontes [Hanken Grotesk](https://github.com/marcologous/hanken-grotesk) e [Geist Mono](https://github.com/vercel/geist-font) vão dentro do app sob a SIL Open Font License 1.1, com as licenças em [`Sources/MeuUso/Resources/Fonts`](Sources/MeuUso/Resources/Fonts).

## Licença

[MIT](LICENSE).
