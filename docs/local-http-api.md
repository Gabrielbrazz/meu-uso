# Local HTTP API

Meu Uso exposes a read-only HTTP API on the loopback interface so other local apps can consume the same usage data shown in the menu bar.

**Base URL:** `http://127.0.0.1:6737`

The server starts automatically with the app. If the port is already in use, the feature is silently disabled for that session.

## Routes

### `GET /v1/limits`

Returns a machine-facing envelope for all **enabled** providers. Providers and resources are keyed by
stable IDs; values are raw scalars with explicit units. This is the preferred route for new integrations
and the exact format printed by the `meu-uso` CLI.

### `GET /v1/limits/:id`

Returns the same envelope containing every provider the ID names. It works for disabled providers too.
Matching is plain string comparison: an exact provider ID names that provider, and a family ID
(`claude`, `codex`) names every account card of that family — with one account that's exactly the one
card. There is no aliasing or "pick the right account" logic; the same request always names the same
providers.

- **200 OK** — limits envelope with every matched provider that has data (an `errors` entry appears
  when a refresh failed; a matched provider with no data yet simply has no entry).
- **404 Not Found** — the ID names no known provider and no family.

### `GET /v1/usage`

Returns the legacy UI-oriented snapshots for all **enabled** providers, in your dashboard order. Existing
consumers remain supported while this route is deprecated; new consumers should use `/v1/limits`.

Both routes read the same rendered provider snapshots. When iCloud Sync is on, that means they both see
the same iCloud-combined usage as the dashboard; `/v1/usage` returns the old UI-oriented shape, while
`/v1/limits` projects the data into stable resource IDs and raw scalar values.

- **200 OK** — JSON array (may be empty `[]` if nothing has been fetched yet).

### `GET /v1/usage/:id`

Returns the latest snapshots for every provider the ID names (same matching as `/v1/limits/:id`).
Works for disabled providers too.

- **200 OK** — JSON array, one snapshot per matched provider that has one (`[]` when none do yet).
- **404 Not Found** — the ID names no known provider and no family.

> **Breaking change:** this route previously returned a single JSON object and `204` when the
> provider had no snapshot. It now always returns an array, so the shape stays identical whether an
> ID names one provider or a whole account family.

### Everything else

Methods other than `GET` return **405**; unknown routes return **404**. When the server is already handling its maximum of 16 concurrent connections, requests get **503** — back off and retry.

Pedido que pode ter saído de uma página da web, com `Origin` ou com `Host` diferente de `127.0.0.1:6737` e `localhost:6737`, recebe **403** antes de qualquer rota. Veja [CORS e privacidade](#cors-e-privacidade).

## Limits response shape

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

`kind` is `consumption` (`used`) or `balance` (`available`). Bounded consumption also carries `limit`,
`remaining`, and a 0–1 `utilization`. Reset, window, expiry-list, and `estimated` fields appear only when
the provider supplies that meaning. A provider or resource with no current value is omitted rather than
invented as zero. `expiresAt` is always `fetchedAt` plus the same five-minute freshness interval used by
the app and CLI; `stale` says whether that instant has passed. Refresh failures appear in `errors` as
`{"providerId":"…","message":"…"}` while a last-good provider snapshot remains available.
For bounded progress resources, `unit` follows the provider's live metric format. For example, Cursor
`totalUsage` is `percent` on percentage-based plans, `requests` on request-based Enterprise plans, and
`usd` when Cursor reports a dollar pool. Copilot `premiumCredits` is `percent` on paid plans and a
`credits` count on org-managed seats that only report personal `credits_used`. OpenCode `session`,
`weekly`, and `monthly` are `percent`. An untouched OpenCode `session` omits `resetsAt`; the field appears
with the anchored reset instant after the first model call starts the rolling window, even while `used`
is still 0 because OpenCode reports whole percentages.

### Public resources

| Provider | Resource keys |
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

Charts, colors, subtitles, formatted badges, layout state, and historical spend periods stay out of this
contract. Codex's combined Credits UI row becomes two scalar resources: `credits` and `creditValue`.

## Legacy usage response shape

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
      "format": { "kind": "percent" },          // or "dollars", or "count" (+ "suffix")
      "resetsAt": "2026-03-26T13:00:00.161Z",   // optional
      "periodDurationMs": 18000000,             // optional
      "color": null
    },
    {
      "type": "text",
      "label": "Today",
      "value": "$5.17 · 9.2M tokens",
      "color": null,
      "subtitle": null
    },
    {
      "type": "badge",
      "label": "Pay as you go",
      "text": "2500 cap",
      "color": "#22c55e",
      "subtitle": null
    },
    {
      "type": "barChart",
      "label": "Usage Trend",
      "points": [
        { "label": "Mar 25", "value": 1200000.0, "valueLabel": "1.2M tokens" },
        { "label": "Mar 26", "value": 2400000.0, "valueLabel": "2.4M tokens" }
      ],
      "note": "Estimated from local Claude logs at API rates.",
      "color": null
    }
  ],
  "fetchedAt": "2026-03-26T11:16:29.000Z"
}
```

Line types are `progress`, `text`, `badge`, and `barChart`. A `barChart` line carries a `points` array — one `{ label, value, valueLabel? }` per day, oldest first — plus an optional `note`; `value` is the day's token count, `valueLabel` its pre-formatted readout, and `label` a localized month/day (e.g. "Mar 25"). `fetchedAt` is when the snapshot was last fetched successfully (ISO 8601).

The in-app model breakdown shown when hovering spend rows is not included in this API yet. Spend rows continue to serialize as the same `text` lines so existing local integrations keep their current shape.

## Errors

```json
{ "error": "provider_not_found" }
```

Codes: `provider_not_found`, `not_found`, `method_not_allowed`, `host_not_allowed`, `origin_not_allowed`, `server_busy`.

## CORS e privacidade

A API só escuta na interface de loopback (`127.0.0.1`), então nenhuma outra máquina da rede chega até ela. E ela serve programas do seu Mac, não páginas da web: `curl`, scripts e apps nativos leem os dados, mas um site aberto no navegador não lê.

Como isso funciona:

- **Sem CORS.** Nenhuma resposta traz cabeçalho `Access-Control-*`, e não existe preflight: `OPTIONS` recebe **405**, como qualquer método diferente de `GET`. Sem esses cabeçalhos, o navegador não entrega a resposta a uma página de outra origem.
- **Pedido com `Origin` recebe 403** (`origin_not_allowed`), sem dado nenhum. O navegador manda `Origin` em todo `fetch` para outra origem e em todo preflight; `curl` e apps nativos não mandam.
- **Só dois `Host` valem: `127.0.0.1:6737` e `localhost:6737`.** Outro valor, `Host` repetido ou a falta dele recebe **403** (`host_not_allowed`). É o que barra o DNS rebinding, em que o site faz o próprio domínio apontar para `127.0.0.1` e, para o navegador, a API vira da mesma origem que ele.
- **`<script>` e `<img>` de outro site também ficam sem o JSON.** Esses pedidos não levam `Origin`, mas as respostas trazem `Cross-Origin-Resource-Policy: same-origin` e `X-Content-Type-Options: nosniff`, e com isso o navegador não repassa o conteúdo.

Abrir o endereço na barra do navegador continua funcionando: aí quem lê é você, não uma página.

O motivo: as respostas trazem uso, gasto, nomes de plano e, nos provedores com mais de uma conta, nomes de exibição que podem conter o e-mail da conta. O OpenUsage, de onde o Meu Uso veio, responde com `Access-Control-Allow-Origin: *`, e assim qualquer página aberta no navegador lê esses dados enquanto o app está aberto. Credenciais e tokens nunca saem pela API.

Integração que roda dentro de um navegador ou de uma WebView, como uma extensão ou um widget em HTML, não consegue ler a API. Ela precisa de um intermediário nativo, como o `curl` ou o comando [`meu-uso`](cli.md). O `meu-uso` não passa pelo HTTP (lê o cache do app), então nada muda para ele.

## Caching behavior

The API serves whatever the app is showing: only successful fetches replace data, so a failed refresh never blanks the API — you keep getting the last good snapshot. See [Refreshing & caching](refreshing.md).
