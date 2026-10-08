# Glossário e guia de tradução

O Meu Uso é um app só em português do Brasil. Este guia define os termos e o jeito de escrever. Ele também explica como colocar um texto novo na tela sem que ele apareça em inglês.

## Como o texto chega na tela

- O código continua escrito em inglês. Cada texto de interface em inglês funciona como **chave** da tabela [`assets/Localization/pt-BR.lproj/Localizable.strings`](../assets/Localization/pt-BR.lproj/Localizable.strings), que traz a tradução.
- Os scripts de build copiam essa tabela para dentro do app.
- O `swift test` e o `swift run` rodam sem tabela, então os testes continuam vendo o texto em inglês.
- Se faltar tradução, o app mostra o inglês. O CI acusa a falta antes do merge com `script/check_localization.py`.

Regras para quem escreve código:

1. **Literal de SwiftUI já é chave.** `Text("Settings")`, `Button("Copy")`, `Label("About Meu Uso", systemImage: …)`, `Toggle("…")`, `.help("…")` e `.accessibilityLabel("…")` só precisam da entrada na tabela.
2. **Fora disso, use `L10n`** (`Sources/MeuUso/Support/L10n.swift`). Isso vale para AppKit, notificações, mensagens de erro e frases montadas no modelo.
   - `L10n.tr("Refresh failed")` para texto fixo.
   - `L10n.format("Resets in %@", duration)` para texto com valores. Use `%@` para texto, `%lld` para inteiro e `%%` para o sinal de porcentagem.
   - `L10n.plural(count, "%lld day", "%lld days")` quando a palavra muda com a quantidade.
3. **Frase inteira, nunca pedaço.** Não concatene palavras traduzidas (`"\(valor) " + L10n.tr("left")`). Monte a frase com placeholder (`"%@ left"`), porque a ordem das palavras muda em português ("limite de US$ 100").
4. **Interpolação em literal de SwiftUI:** prefira `Text(L10n.format("Meu Uso %@", versão))`. `Text("Meu Uso \(versão)")` também funciona, mas a chave vira `"Meu Uso %@"`, e inteiros viram `%lld`.
5. **Rótulos que também são chave interna ficam em inglês nos dados** e só são traduzidos na exibição. São eles:
   - os nomes de métrica (`MetricLine.label`, `metricLabel`, por exemplo "Session" e "Weekly");
   - os períodos do Gasto total ("Today", "Yesterday", "Last 30 Days");
   - o marcador "Error";
   - as unidades comparadas no código ("tokens", "credits", "available");
   - "Unattributed" e "Other".

   O título de cada linha é traduzido uma vez, em `WidgetDataStore.data(for:)`. As unidades passam por `MetricFormatter.unitWord`, que usa a chave `<unidade>#one` para o singular ("credits#one" = "crédito").
6. **Nunca use `bundle: .module` nem `#bundle`.** O `Bundle.module` derruba o app empacotado; veja `Support/ResourceBundle.swift`.
7. **Logs, nomes de evento, chaves JSON da API local, comandos e identificadores ficam em inglês.**

## Números, moeda e datas

O app formata tudo no padrão brasileiro, por `AppLocale.current` (`pt_BR`), seja qual for a região do Mac.

| O quê | Exemplo |
|---|---|
| Dólar | US$ 1.234,56 · US$ 2,1 mil · US$ 130 na barra de menus |
| Números grandes | 12,9 mil · 3,4 mi · 1,2 bi |
| Porcentagem | 45% |
| Data curta | 7 de out. |
| Hora | 17:30 (24 h) |
| Prazo | Renova em 2d 6h · Renova hoje às 17:30 · Renova em 15 de fev. às 15:45 · Renova em breve |
| Duração | 4d 0h · 2h 5min · 7min |

Os valores dos provedores são cobrados em dólar, por isso aparecem como US$.

## Estilo

- **Trate a pessoa por "você".** Escreva frases curtas e diretas, como na interface do macOS.
- **Maiúscula só no começo** de título, botão e item de menu ("Ocultar ao compartilhar a tela"), nunca em toda palavra. Nome próprio segue a grafia oficial (Claude Code, Codex, iCloud).
- **Reticências ("…") só em ação que abre outra tela ou pede mais informação** ("Relatar um problema…").
- **O nome do app é "Meu Uso", com artigo masculino:** "o Meu Uso", "Sobre o Meu Uso", "Encerrar o Meu Uso".
- **Mensagem de erro diz o que aconteceu e o que fazer,** sem culpar quem usa: "Sessão do Claude Desktop expirada. Abra o Claude Desktop e atualize o Meu Uso."

## O que não se traduz

- **Nomes de provedor, produto e modelo:** Claude, Claude Code, Claude Desktop, Codex, Cursor, Copilot, Grok, Ollama, OpenRouter, OpenCode, Devin, Z.ai, Antigravity, Sonnet, Opus, GPT-5, etc.
- **Nomes de plano que vêm do provedor:** Pro, Max, Plus, Team, Business, Enterprise, "Business Premium".
- **Comandos e variáveis:** `claude`, `codex`, `gh auth login`, `ollama signin`, `cswap run`, `OPENROUTER_API_KEY`, caminhos de arquivo.
- **Unidades técnicas:** tokens, MTok, API.

## Termos

| Inglês | Português |
|---|---|
| About | Sobre |
| Account | Conta |
| Always Show Pacing | Sempre mostrar o ritmo |
| API key | Chave de API |
| Appearance (Light / Dark / System) | Aparência (Claro / Escuro / Sistema) |
| Auto | Automático |
| available | disponível / disponíveis |
| Balance | Saldo |
| Billing cycle | Ciclo de cobrança |
| Cache read / write | Leitura de cache / Escrita de cache |
| Check for Updates | Buscar atualizações |
| Copy / Copied | Copiar / Copiado |
| Cost | Custo |
| Credits | Créditos |
| Customize | Personalizar |
| Dashboard | Painel |
| Density (Compact / Comfortable) | Densidade (Compacta / Confortável) |
| Early Access (beta) | Acesso antecipado |
| Error | Erro |
| Estimated locally | Estimativa local |
| Extra Usage | Uso extra |
| Global Shortcut | Atalho global |
| Hide From Screen Share | Ocultar ao compartilhar a tela |
| iCloud Sync | Sincronização com o iCloud |
| Increase Transparency | Aumentar transparência |
| Input / Output tokens | Tokens de entrada / Tokens de saída |
| Launch at Login | Abrir ao iniciar sessão |
| Last 30 Days | Últimos 30 dias |
| Last updated 3h ago | Atualizado há 3h |
| Left (mode) / "95% left" | Restante / "95% restante" |
| Limit / Limit reached | Limite / Limite atingido |
| "Limit in 2d" (projeção) | Esgota em 2d |
| "$100 limit" | limite de US$ 100 |
| Log / Log Level | Log / Nível de log |
| Menu bar | Barra de menus |
| Model | Modelo |
| Monthly | Mensal |
| No data | Sem dados |
| No usage in this period | Sem uso neste período |
| Not started (sessão) | Não iniciada |
| Notifications | Notificações |
| On-demand | Sob demanda |
| Outdated | Desatualizado |
| Pace / pacing | Ritmo |
| "~35% left at reset" | ~35% restante na renovação |
| "~92% used at reset" | ~92% usado na renovação |
| "~12% over limit at reset" | ~12% acima do limite na renovação |
| "~3% spare" | ~3% de folga |
| Plan | Plano |
| Premium requests | Requisições premium |
| Provider | Provedor |
| Quit | Encerrar |
| Reduce Animations | Reduzir animações |
| Refresh / Refreshing… | Atualizar / Atualizando… |
| Refresh failed | Falha ao atualizar |
| Report an Issue… | Relatar um problema… |
| requests | requisições |
| Reset (verbo, "Resets in 2h") | Renova ("Renova em 2h") |
| Reset expires | Expira |
| Reset All Settings | Redefinir todos os ajustes |
| searches | buscas |
| Session | Sessão |
| Settings | Ajustes |
| Share / Share Card | Compartilhar / Card de compartilhamento |
| Sign in / Log in | Entrar |
| soon | em breve |
| spent ("$12 spent") | gastos ("US$ 12 gastos") |
| Spend / Total Spend | Gasto / Gasto total |
| Time Format (12-hour / 24-hour) | Formato de hora (12 horas / 24 horas) |
| Today / Yesterday | Hoje / Ontem |
| Unknown model | Modelo desconhecido |
| Usage | Uso |
| Used (mode) / "5% used" | Usado / "5% usado" |
| Weekly | Semanal |
| Welcome to Meu Uso | Boas-vindas ao Meu Uso |
