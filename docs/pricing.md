# Preços dos modelos

Como o Meu Uso transforma contagens de tokens nos valores estimados em dólar das linhas de gasto do Claude, do Codex, do Cursor, do Grok e do Antigravity. O Grok usa o custo gravado nos próprios logs de sessão quando ele existe e só estima os turnos antigos que não têm esse dado. O OpenRouter e o OpenCode não usam essas estimativas, porque as fontes deles já informam o custo.

## De onde vêm os preços

Os preços vêm de três fontes, em camadas. Quando o mesmo modelo aparece em mais de uma, vale a que vem primeiro na lista:

1. **Suplemento de preços do Meu Uso**: um JSON pequeno mantido neste repositório, que os apps instalados leem direto do `main`. Ele cobre modelos que nenhum catálogo público traz (modelos próprios do Cursor, como `auto` e `composer-*`), multiplicadores das variantes Fast e regras de alias, que ligam os slugs dos logs e CSVs dos provedores às chaves dos catálogos.
2. **LiteLLM**: o `model_prices_and_context_window.json` mantido pela comunidade, que cobre a grande maioria dos modelos com preço de API.
3. **models.dev**: cobre o que falta no LiteLLM (por exemplo, alguns modelos muito novos ou de nicho).

O app vem com cópias embutidas das três fontes, então os preços funcionam sem internet e já na primeira abertura. Com o app aberto, cada fonte é baixada de novo mais ou menos uma vez por hora (com revalidação por ETag) e guardada em `~/Library/Application Support/MeuUso/pricing/`. Essa atualização nunca trava a leitura de uso: a leitura sempre usa os preços mais recentes que já estão no Mac.

Como os apps leem o suplemento direto do `main` (`https://raw.githubusercontent.com/Gabrielbrazz/meu-uso/main/Sources/MeuUso/Resources/pricing_supplement.json`), uma correção de preço chega aos apps instalados cerca de uma hora depois do merge, sem atualizar o app.

Atualizar o app também funciona. O suplemento traz um `updated_at` em ISO 8601, e o app usa a mais nova entre a cópia do cache e a cópia embutida. Assim, um build com preços mais novos aplica esses preços na hora, sem esperar o cache vencer. A precisão do horário importa porque pode haver mais de uma mudança de preço no mesmo dia. Valores antigos, só com a data, continuam aceitos. Isso faz mais diferença sem internet: sem essa regra, um cache antigo esconderia os preços do build enquanto a fonte estivesse fora de alcance.

## Como o nome de um modelo é resolvido

Os nomes de modelo nos logs e CSVs raramente batem exatamente com uma chave de catálogo. Por isso a resolução tenta, nesta ordem:

1. as regras de alias do suplemento;
2. a chave exata;
3. o tratamento das variantes Fast (o sufixo `-fast` resolve o modelo base e aplica o multiplicador Fast dele);
4. uma correspondência aproximada: prefixos de provedor (`anthropic/`, `xai/`, …), sufixos de data (`claude-sonnet-4` ↔ `claude-sonnet-4-20250514`) e separadores diferentes (`grok-4-3` ↔ `grok-4.3`).

Variantes Fast sem preço próprio nem multiplicador específico ficam sem preço, em vez de usar em silêncio a taxa da velocidade padrão.

As requisições roteadas pelo [Cursor Router](https://cursor.com/docs/cursor-router.md) são um caso à parte. Em vez de um slug, a exportação do Cursor escreve por extenso o modelo escolhido, como `Opus 5 (Auto Balanced)`. As regras de alias ligam esses rótulos às taxas do próprio modelo, então uma requisição roteada custa o mesmo que custaria com o modelo escolhido à mão. O rótulo aparece como está no detalhamento por modelo, para você ainda saber quais requisições passaram pelo roteador.

O Antigravity faz algo parecido com a escolha de modelo padrão: turnos registrados com um ID genérico trazem o modelo usado num rótulo como `Gemini 3.1 Pro (High)`, e as regras de alias cobram a taxa desse modelo. Diferente do Cursor, o detalhamento do Antigravity agrupa essas linhas pela família do modelo (`gemini-3.1-pro`), porque os logs dele também separam o uso por nível de esforço.

O Gemini 3.8 Flash inclui variantes de esforço do Cursor, como `gemini-3.8-flash-high`, variantes de preview e rótulos `Gemini 3.8 Flash (Auto…)`. Todas usam as taxas de API embutidas, mesmo antes da primeira atualização de preços: US$ 0,75 de entrada, US$ 0,75 de escrita de cache, US$ 0,075 de leitura de cache e US$ 3,75 de saída, por milhão de tokens. Como no Gemini 3.7, a taxa de saída segue os [preços da API do Google](https://ai.google.dev/gemini-api/docs/pricing), embora a tabela do Cursor mostre US$ 3,50. Segundo o Google, essas taxas de lançamento valem até 31 de dezembro de 2026.

O Muse Spark 1.3 usa as mesmas taxas em todos os níveis de esforço do Cursor: Minimal, Low, Medium, High, Extra High (`xhigh` ou `extra-high`) e Max. As taxas embutidas seguem os [preços do Cursor](https://cursor.com/docs/models-and-pricing.md): US$ 1,25 de entrada e de escrita de cache, US$ 0,15 de leitura de cache e US$ 4,25 de saída por milhão de tokens, sem adicional de contexto longo. Todos os esforços contam no gasto e aparecem juntos como `muse-spark-1.3` no detalhamento por modelo, mesmo antes da primeira atualização de preços. As variantes Contributor têm preço próprio e ficam fora desses aliases.

Um modelo que nenhuma fonte consegue precificar fica fora dos valores de gasto, a menos que a sessão já registre o custo real. Sem esse custo, os tokens dele não entram na linha do dia, na **Tendência de uso** nem no detalhamento por modelo: mostrar uma contagem de tokens ao lado de um valor em dólar que ignora parte dela seria enganoso. Um triângulo de aviso nas linhas afetadas lista os modelos sem preço, e um dia em que nada pôde ser precificado mostra **Sem dados**.

O Codex tem um **Modelo de referência** opcional em **Personalizar → Codex → Estimativas de custo**. O padrão é **Nenhum**, que mantém o comportamento acima. Ao escolher um modelo, o uso local sem preço passa a ser estimado com as taxas dele, incluindo entrada em cache, requisições de contexto longo e o nível de velocidade da sessão. Preços conhecidos continuam valendo.

O triângulo de aviso de modelo desconhecido e a dica dele continuam visíveis: o modelo de referência estima o custo, mas não define o preço do modelo em si. Trocar a escolha recalcula o histórico local, inclusive dias anteriores, e não muda o modelo que o Codex usa. Escolher **Nenhum** volta a deixar o uso sem preço de fora.

O detalhamento por modelo e a nota de origem da **Tendência de uso** só indicam estimativas por referência nos dias mostrados, por exemplo: "Dos seus logs do Codex (estimativa) · Preço estimado com base em: GPT 5.5". Estimativas fora da janela de histórico não afetam essas notas. O histórico sincronizado guarda as estimativas feitas em cada Mac de origem; essa preferência não recalcula o histórico de outro Mac.

O seletor mostra os modelos públicos de texto e código da lista `fallback_models.codex` do suplemento, e só os que têm preço exato utilizável. Ele nunca lê listas de modelos específicas da conta. A lista embutida funciona sem internet, e as mudanças nela chegam pela atualização normal do suplemento. Abrir essa seção recalcula a escolha salva. Se a disponibilidade dela mudar depois de uma atualização da lista, os totais locais são recalculados de novo. Se a escolha salva ficar indisponível, o seletor mostra **Modelo indisponível** com o aviso "O preço deste modelo não está disponível. Escolha outro modelo ou Nenhum.", e as estimativas por referência saem. Se o preço voltar, as estimativas voltam. Nos dois casos, os avisos de modelo desconhecido continuam.

Os modos do Grok Bot no Cursor usam aliases separados: `grok-bot-default` usa as taxas do Grok 4.6 Fast, e `grok-bot-automation` usa as taxas base do Grok 4.6. Isso segue a comparação de preço de tabela por evento em [robinebers/openusage#1229](https://github.com/robinebers/openusage/issues/1229); as taxas em si vêm da [tabela de preços do Cursor](https://cursor.com/docs/models-and-pricing.md). O `grok-bot-cua` usa as taxas base do Grok 4.7, por decisão do mantenedor.

O Grok 4.7 do Cursor tem preço no suplemento, tirado da mesma tabela: US$ 2 de entrada, US$ 0,50 de leitura de cache e US$ 6 de saída por milhão de tokens (o Fast custa o dobro). O Cursor lista à parte uma faixa de contexto longo, de 500 mil tokens, que custa 2x a taxa padrão (3x no Fast). Os slugs de CSV e de log seguem os mesmos padrões do Grok 4.5 e 4.6 (prefixo `cursor-`, esforço, Fast e versão com hífen), além das variantes `-500k` / `[500k]`. O slug `-slow` usa a taxa padrão do Grok 4.7; um sufixo de esforço ou `-fast` no fim escolhe a mesma variante dos outros slugs do 4.7.

O Claude Opus 5.5 usa as [taxas publicadas pela Anthropic](https://platform.claude.com/docs/en/about-claude/pricing): US$ 4 de entrada, US$ 5 de escrita de cache de cinco minutos, US$ 0,20 de leitura de cache e US$ 20 de saída por milhão de tokens. O modo Fast custa o dobro em todos esses tipos de token. O suplemento liga os IDs dos logs do Claude, os slugs dos CSVs do Cursor e os rótulos do Router a essas taxas, até que os catálogos públicos incluam o modelo.

GPT-6 Sol, GPT-6.1 Sol e GPT-6 Luna usam as taxas da [página de preços da OpenAI](https://developers.openai.com/api/docs/pricing), e o Fast custa o dobro. O GPT-5.6 Sol usa as taxas promocionais da OpenAI, válidas pelo menos até 21 de novembro de 2026. O Ultrafast do Codex custa 6x só no GPT-6 Astra; nos outros modelos, o Ultrafast usa o multiplicador Fast.

## O que a estimativa inclui

O custo é calculado por evento de uso, a partir de quatro grupos de tokens (entrada simples, escrita de cache, leitura de cache e saída), com as taxas por milhão de tokens do modelo. Entram também o preço de escrita de cache de 1 hora, as faixas de contexto longo e os multiplicadores das variantes Fast.

A maioria das faixas dos catálogos começa acima de 200 mil tokens de prompt. Nos modelos GPT-5.4, GPT-5.5, GPT-5.6 e GPT-6 do Codex que têm essa faixa, a troca acontece acima de 272 mil tokens de entrada. Nos dois casos, a taxa mais alta vale para a requisição inteira. A exportação do Cursor junta várias requisições em cada linha, então ali o Meu Uso usa a taxa normal, em vez de adivinhar que uma requisição passou do limite.

Quando a fonte publica um desconto de cache, ele é usado; a entrada em cache do Codex usa a taxa cheia de entrada quando a fonte não publica desconto. Quando uma sessão do Claude ou do Grok registra o próprio custo, esse valor é usado como está. O uso aninhado do advisor do Claude não traz custo próprio, então é precificado à parte, pelos tokens, com o modelo do advisor.

As estimativas representam o valor pelas taxas de API, não uma fatura de assinatura.

## Privacidade

A atualização de preços baixa três listas públicas: a do LiteLLM e a deste repositório (o suplemento), as duas de `raw.githubusercontent.com`, e a do `models.dev`. Essas requisições não levam dados de uso nem de log: nada sobre o seu uso sai do Mac.

## Notas para mantenedores

- **Mudanças no suplemento** (modelo novo do Cursor, correção de preço, alias novo): edite `Sources/MeuUso/Resources/pricing_supplement.json`, sincronize as entradas com a página [Cursor models & pricing](https://cursor.com/docs/models-and-pricing.md) e troque o `updated_at` pelo horário UTC atual. O job "Pricing supplement" do CI (`.github/workflows/ci.yml`) valida o JSON em todo PR e push para o `main`. O merge no `main` já publica a mudança, porque os apps instalados leem o arquivo direto de lá e pegam a novidade em cerca de uma hora. A cópia embutida vai na próxima release, para a primeira abertura. A **skill pricing-update** (`.agents/skills/pricing-update/`) guia um agente pela sincronização inteira: baixar a página do Cursor, comparar, editar, validar e abrir um PR.
- **Cópias embutidas** (`pricing_litellm_snapshot.json`, `pricing_models_dev_snapshot.json`): gere de novo de vez em quando (por exemplo, antes de uma release) com `script/update_pricing_snapshots.sh`. Cópias velhas não fazem mal, porque o que é baixado com o app aberto tem prioridade.
