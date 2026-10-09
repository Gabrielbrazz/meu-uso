# API HTTP local

O Meu Uso expõe uma API HTTP somente leitura na interface de loopback, para outros apps do seu Mac usarem os mesmos dados de uso que aparecem na barra de menus.

**URL base:** `http://127.0.0.1:6737`

O servidor sobe junto com o app. Se a porta já estiver em uso, a API fica desligada naquela sessão, sem aviso.

## Rotas

### `GET /v1/limits`

Devolve um envelope feito para máquinas, com todos os provedores **ativados**. Provedores e recursos usam IDs estáveis como chave, e os valores são números brutos com unidade explícita. É a rota recomendada para integrações novas e o formato exato que a CLI `meu-uso` imprime.

### `GET /v1/limits/:id`

Devolve o mesmo envelope com todos os provedores que o ID nomeia. Funciona também para provedores desativados. A correspondência é uma comparação simples de texto: um ID exato nomeia aquele provedor, e um ID de família (`claude`, `codex`) nomeia todos os cards de conta da família. Com uma conta só, é exatamente aquele card. Não há apelidos nem lógica para "escolher a conta certa": a mesma requisição sempre nomeia os mesmos provedores.

- **200 OK**: envelope de limites com cada provedor encontrado que tenha dados. Uma entrada em `errors` aparece quando uma atualização falhou; um provedor encontrado que ainda não tem dados simplesmente fica sem entrada.
- **404 Not Found**: o ID não nomeia nenhum provedor nem família conhecidos.

### `GET /v1/usage`

Devolve os snapshots legados, pensados para a interface, de todos os provedores **ativados**, na ordem do seu painel. A rota continua funcionando para quem já usa, mas está obsoleta: integrações novas devem usar `/v1/limits`.

As duas rotas leem os mesmos snapshots já renderizados. Com a Sincronização com o iCloud ligada, as duas veem o mesmo uso combinado do iCloud que o painel mostra. Muda só o formato: `/v1/usage` devolve o formato antigo, pensado para a interface, e `/v1/limits` projeta os dados em IDs de recurso estáveis e valores numéricos brutos.

- **200 OK**: array JSON (pode vir vazio, `[]`, se nada foi buscado ainda).

### `GET /v1/usage/:id`

Devolve os snapshots mais recentes de todos os provedores que o ID nomeia (mesma correspondência de `/v1/limits/:id`). Funciona também para provedores desativados.

- **200 OK**: array JSON, com um snapshot para cada provedor encontrado que tenha um (`[]` quando nenhum tem ainda).
- **404 Not Found**: o ID não nomeia nenhum provedor nem família conhecidos.

> **Mudança em relação ao app original:** no OpenUsage, esta rota devolvia um único objeto JSON e `204` quando o provedor não tinha snapshot. Aqui ela sempre devolve um array, então o formato é o mesmo quando o ID nomeia um provedor ou uma família inteira de contas.

### Todo o resto

Métodos diferentes de `GET`/`OPTIONS` recebem **405**, e rotas desconhecidas recebem **404**. Quando o servidor já está atendendo o máximo de 16 conexões simultâneas, a requisição recebe **503**: espere um pouco e tente de novo.

## Formato da resposta de limites

```jsonc
{
  "schema": "meuuso.limits.v1",
  "generatedAt": "2026-07-13T01:40:00.000Z",
  "providers": {
    "codex": {
      "displayName": "Codex",
      "plan": "Pro 200",
      "fetchedAt": "2026-07-13T01:39:30.000Z",
      "expiresAt": "2026-07-13T01:44:30.000Z",
      "stale": false,
      "resources": {
        "session": {
          "kind": "consumption",
          "unit": "percent",
          "used": 42,
          "limit": 100,
          "remaining": 58,
          "utilization": 0.42,
          "resetsAt": "2026-07-13T06:00:00.000Z",
          "windowSeconds": 18000
        },
        "credits": {
          "kind": "balance",
          "unit": "credits",
          "available": 821
        }
      }
    }
  },
  "errors": []
}
```

`kind` é `consumption` (`used`) ou `balance` (`available`). Um consumo com teto também traz `limit`, `remaining` e `utilization`, de 0 a 1. Os campos de renovação, de janela, de lista de expirações e `estimated` só aparecem quando o provedor fornece esse dado. Um provedor ou recurso sem valor atual fica de fora, em vez de aparecer como um zero inventado.

`expiresAt` é sempre `fetchedAt` mais o mesmo intervalo de cinco minutos que o app e a CLI usam para considerar um dado recente; `stale` diz se esse instante já passou. Falhas de atualização aparecem em `errors` como `{"providerId":"…","message":"…"}`, enquanto o último snapshot bom do provedor continua disponível.

Nos recursos de progresso com teto, `unit` segue o formato que a métrica do provedor tem no momento. Por exemplo:

- `totalUsage` do Cursor é `percent` nos planos por porcentagem, `requests` nos planos Enterprise por requisição e `usd` quando o Cursor informa uma cota em dólar.
- `premiumCredits` do Copilot é `percent` nos planos pagos e uma contagem `credits` em assentos gerenciados pela organização, que só informam o `credits_used` pessoal.
- `session`, `weekly` e `monthly` do OpenCode são `percent`. Uma `session` do OpenCode ainda não usada não traz `resetsAt`. O campo aparece, com o instante de renovação já fixado, depois que a primeira chamada de modelo inicia a janela móvel, mesmo com `used` ainda em 0, porque o OpenCode informa porcentagens inteiras.

### Recursos públicos

| Provedor | Chaves de recurso |
| --- | --- |
| Claude | `session`, `weekly`, `sonnet`, `fable`, `extraUsage`, `rateLimitResets` |
| Codex | `session`, `weekly`, `spark`, `sparkWeekly`, `credits`, `creditValue`, `rateLimitResets` |
| Cursor | `totalUsage`, `grokBot`, `autoUsage`, `apiUsage`, `onDemand`, `requests`, `credits` |
| Antigravity | `geminiSession`, `geminiWeekly`, `nonGeminiSession`, `nonGeminiWeekly` |
| Copilot | `premiumCredits`, `extraUsage`, `orgCredits`, `orgSpend`, `chat`, `completions` |
| Devin | `daily`, `weekly`, `extraUsageBalance` |
| Grok | `weekly` |
| Ollama | `session`, `weekly`, `monthly` |
| OpenCode | `session`, `weekly`, `monthly` |
| OpenRouter | `credits`, `balance`, `keyLimit` |
| Z.ai | `session`, `weekly`, `webSearches` |

Gráficos, cores, subtítulos, badges formatados, estado de layout e os períodos do histórico de gasto ficam fora deste contrato. A linha combinada **Créditos** do Codex vira dois recursos numéricos: `credits` e `creditValue`.

## Formato legado da resposta de uso

```jsonc
{
  "providerId": "claude",
  "displayName": "Claude",
  "plan": "Team 5x",
  "lines": [
    {
      "type": "progress",
      "label": "Session",
      "used": 42.0,
      "limit": 100.0,
      "format": { "kind": "percent" },          // ou "dollars", ou "count" (+ "suffix")
      "resetsAt": "2026-03-26T13:00:00.161Z",   // opcional
      "periodDurationMs": 18000000,             // opcional
      "color": null
    },
    {
      "type": "text",
      "label": "Today",
      "value": "US$ 5,17 · 9,2 mi tokens",
      "color": null,
      "subtitle": null
    },
    {
      "type": "badge",
      "label": "Pay as you go",
      "text": "limite de 2.500",
      "color": "#22c55e",
      "subtitle": null
    },
    {
      "type": "barChart",
      "label": "Usage Trend",
      "points": [
        { "label": "25 de mar.", "value": 1200000.0, "valueLabel": "1,2 mi tokens" },
        { "label": "26 de mar.", "value": 2400000.0, "valueLabel": "2,4 mi tokens" }
      ],
      "note": "Do seu histórico de uso do Claude (estimativa)",
      "color": null
    }
  ],
  "fetchedAt": "2026-03-26T11:16:29.000Z"
}
```

Os tipos de linha são `progress`, `text`, `badge` e `barChart`. Uma linha `barChart` traz um array `points`, com um `{ label, value, valueLabel? }` por dia, do mais antigo para o mais novo, e uma `note` opcional. `value` é a contagem de tokens do dia, `valueLabel` é esse número já formatado para leitura, e `label` é o dia no formato curto do app (por exemplo, "25 de mar."). `fetchedAt` é quando o snapshot foi buscado com sucesso pela última vez (ISO 8601).

O detalhamento por modelo que o app mostra ao passar o mouse nas linhas de gasto ainda não faz parte desta API. As linhas de gasto continuam saindo como as mesmas linhas `text`, para as integrações locais existentes manterem o formato atual.

## Idioma e valores formatados

As chaves JSON, os IDs, os tipos (`type`, `kind`), as unidades e os rótulos de métrica (`label`, como `"Session"` e `"Today"`) ficam em inglês: são identificadores estáveis, não texto de tela. Os números puros (`used`, `limit`, `available`, o `value` dos pontos) continuam números JSON.

Os textos que já chegam prontos para exibir seguem o app: português e o padrão brasileiro de números, moeda e datas (veja [Números, moeda e datas](glossario.md#números-moeda-e-datas) no glossário).

- **No formato legado:** o `value` das linhas `text` ("US$ 5,17 · 9,2 mi tokens"), o `text` dos badges ("limite de 2.500") e o `label`, o `valueLabel` e a `note` do gráfico.
- **Nos dois formatos:** o `plan` quando o nome vem do app e não do provedor (por exemplo, "Pago por uso" no OpenRouter) e o `displayName` dos cards quando há mais de uma conta (por exemplo, "Claude — Pessoal").
- **Em `/v1/limits`:** as mensagens de `errors`, que são as mesmas que o app mostra (por exemplo, "Nenhum login encontrado. Rode `codex` para entrar.").

Nesses textos, o espaço depois de `US$` e antes de `mil`, `mi` e `bi` é um espaço não separável (U+00A0). Para fazer contas, use os números de `/v1/limits` em vez de interpretar esses textos.

## Erros

```json
{ "error": "provider_not_found" }
```

Códigos: `provider_not_found`, `not_found`, `method_not_allowed`, `server_busy`.

## CORS e privacidade

Todas as respostas trazem cabeçalhos CORS abertos (`Access-Control-Allow-Origin: *`, métodos `GET, OPTIONS`). Requisições `OPTIONS` recebem **204** para o preflight.

O servidor só escuta na interface de loopback (`127.0.0.1`), então não dá para acessá-lo de outras máquinas da sua rede. Mas, como o cabeçalho CORS é aberto, uma página aberta no seu navegador consegue ler seus snapshots de uso por esta API enquanto o app estiver aberto. Os dados expostos são os mesmos números de uso da barra de menus; credenciais e tokens nunca são servidos. É o mesmo comportamento do OpenUsage original.

## Comportamento do cache

A API serve o que o app está mostrando. Só buscas bem-sucedidas substituem os dados, então uma atualização que falha nunca esvazia a API: você continua recebendo o último snapshot bom. Veja [Atualização e cache](refreshing.md).
