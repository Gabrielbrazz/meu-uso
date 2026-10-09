# Renovações de limite do Codex: como funciona o resgate

Pesquisa e verificação ao vivo do fluxo de resgate de "reset credits" (renovações de limite) do Codex, feitas em 12 de julho de 2026. O Meu Uso já listava esses créditos (a linha **Renovações de limite** do Codex); esta nota documenta o que seria preciso para *resgatar* um deles pelo app. Na época ainda não havia implementação; a nota era a referência do protocolo.

> **Situação atual:** o resgate foi implementado depois, seguindo esta referência, em `CodexResetClaimService` (o serviço) e `RateLimitResetsDetail` (a interface). Ao passar o mouse no valor da linha **Renovações de limite**, abre uma lista das renovações, e cada uma mostra o botão **Usar** quando o mouse passa por ela. O app pede confirmação ("Usar esta renovação?", botão **Renovar**) antes de chamar o endpoint de consumo e mostra o resultado no topo da lista (por exemplo, "Limites renovados. Aproveite!" ou "Seus limites ainda não precisam ser renovados"). Veja as [notas de implementação](#notas-de-implementação-para-o-meu-uso).

Fontes: a CLI open source do Codex (`openai/codex`, `codex-rs/backend-client/src/client/rate_limit_resets.rs`, `codex-rs/tui/src/chatwidget/reset_credits.rs`, `codex-rs/tui/src/chatwidget/usage.rs`, `codex-rs/app-server/src/request_processors/account_processor/rate_limit_resets.rs`), mais um resgate de ponta a ponta, ao vivo, numa conta real (um crédito, horas antes de expirar).

## O que é uma renovação

A OpenAI dá aos usuários do Codex, de vez em quando, "rate limit resets" gratuitos. Resgatar um renova na hora as janelas de limite do Codex da conta: nos planos pagos, a janela de 5 horas **e** a semanal juntas (`windows_reset: 2`); nos planos Free e Go, a janela mensal. Os créditos expiram (em geral 30 dias depois de concedidos) e somem depois de resgatados ou expirados.

## Endpoints

Os dois ficam na URL base do backend do ChatGPT (`https://chatgpt.com/backend-api`). A CLI também tem a variante `PathStyle::CodexApi` (`/api/codex/...` em vez de `/wham/...`) para URLs base enterprise ou alternativas; o Meu Uso usa o estilo do ChatGPT.

Cabeçalhos em toda chamada (os mesmos que o cliente de uso do Codex no Meu Uso já manda):

- `Authorization: Bearer <access_token>` (o token de acesso OAuth do ChatGPT, de `~/.codex/auth.json`)
- `ChatGPT-Account-Id: <account_id>` (do mesmo arquivo)
- `Content-Type: application/json` no POST

### Listar (já implementado no Meu Uso)

`GET /wham/rate-limit-reset-credits`

```json
{
  "credits": [
    {
      "id": "RateLimitResetCredit_…",
      "reset_type": "codex_rate_limits",
      "status": "available",            // available | redeeming | redeemed
      "granted_at": "2026-06-12T03:57:42.677034Z",
      "expires_at": "2026-07-12T03:57:42.677034Z",   // pode ser null (nunca expira)
      "redeem_started_at": null,
      "redeemed_at": null,
      "profile_image_url": "https://…/codex-icon-200.png",
      "profile_user_id": "Codex Team",
      "title": "Full reset (Weekly + 5 hr)",
      "description": "Thanks for using Codex! You've been granted one free rate limit reset."
    }
  ],
  "available_count": 4
}
```

Observação: créditos resgatados ou expirados saem da lista de vez. Depois do resgate ao vivo, a lista tinha 3 itens, e não 4 com um deles `redeemed`.

### Consumir (o resgate)

`POST /wham/rate-limit-reset-credits/consume`

```json
{
  "redeem_request_id": "<UUID v4 gerado pelo cliente>",
  "credit_id": "RateLimitResetCredit_…"
}
```

- `redeem_request_id`: **chave de idempotência**, um UUID v4 simples criado pelo cliente (`Uuid::new_v4().to_string()` na TUI). A CLI gera uma chave para cada crédito mostrado no seletor e **reaproveita a mesma chave quando o usuário tenta de novo depois de um erro**. Assim, uma nova tentativa nunca gasta um segundo crédito: o servidor responde `already_redeemed`, que a CLI trata como sucesso.
- `credit_id`: opcional. Quando vem, o servidor resgata exatamente aquele crédito; quando falta, o servidor escolhe um. A CLI sempre manda: ela ordena os créditos disponíveis pelo `expires_at` mais próximo e deixa o usuário escolher. Só deixa o `credit_id` de fora num caminho alternativo, quando não conseguiu buscar a lista detalhada.

Resposta (HTTP 200 até para os códigos de "falha"; o resultado vem em `code`):

```json
{
  "code": "reset",
  "credit": {
    "id": "RateLimitResetCredit_…",
    "status": "redeemed",
    "redeem_started_at": "2026-07-12T01:47:04.448019Z",
    "redeemed_at": "2026-07-12T01:47:05.162045Z",
    …
  },
  "windows_reset": 2
}
```

Valores de `code` (de `ConsumeRateLimitResetCreditCode` na CLI):

| code | significado | gasta o crédito? |
|---|---|---|
| `reset` | sucesso; `windows_reset` = número de janelas renovadas (2 = 5h + semanal) | sim |
| `already_redeemed` | o mesmo `redeem_request_id` já foi processado; trate como sucesso | já tinha gastado |
| `nothing_to_reset` | o uso não precisa de renovação agora (a CLI mostra "Your usage does not need a reset right now.") | não |
| `no_credit` | o crédito pedido não está mais disponível (resgatado em outro lugar ou expirado), ou não há nenhum disponível | não |

O objeto `credit` da resposta de consumo traz mais campos do que a struct da própria CLI decodifica: `redeem_started_at`, `redeemed_at` e os `profile_*`, que a CLI ignora.

## Verificação ao vivo (12 de julho de 2026, plano Pro)

O log completo (cada requisição e resposta, com o token mascarado) ficou fora do repositório. A execução foi um script Python de uso único, com travas rígidas: resgatar no máximo um crédito, só o que expirava primeiro, só se ele expirasse em até 4 h e sempre com `credit_id` explícito.

- Antes: 4 créditos disponíveis; janela de 5h com 96% usado (renovação em ~25 min), semanal com 52% usado (renovação em ~6 dias). O crédito escolhido expiraria 2,18 h depois.
- `POST …/consume` com um UUID novo e `credit_id` explícito → HTTP 200, `code: "reset"`, `windows_reset: 2`, crédito com `status: "redeemed"`. Ida e volta em ~1,1 s (`redeem_started_at` → `redeemed_at` ≈ 0,7 s no servidor).
- Depois (lido ~1 s mais tarde): as janelas de 5h e semanal mostravam **0% usado**, com a duração cheia (`reset_after_seconds` = 18000 / 604800), `available_count` = 3, e o crédito resgatado não aparecia mais na lista. A renovação também zerou as janelas do item `additional_rate_limits` (o limite específico do modelo já estava em 0%, então isso é um indício, não uma prova).

## Notas de implementação para o Meu Uso

Escritas antes da implementação. O resgate atual (`CodexResetClaimService`) segue estas notas; as diferenças estão entre parênteses.

- O resgate é um único POST, num serviço com que o Meu Uso já conversa: autenticação, cabeçalhos e ID da conta são iguais aos das chamadas que o `CodexUsageClient` já faz.
- Gere o UUID do `redeem_request_id` **quando o usuário vê a opção de resgate** (um por crédito), guarde durante toda a interação e reaproveite nas novas tentativas. É a proteção da CLI contra gasto em dobro, e devemos copiá-la exatamente. (Na implementação, o UUID nasce quando o crédito entra na confirmação e vale para todas as novas tentativas enquanto a lista do app estiver aberta.)
- Mande sempre um `credit_id` explícito e deixe selecionado por padrão o crédito disponível que expira primeiro (a ordem da CLI). (Na implementação, a lista do app mostra primeiro a renovação que expira antes, e o app busca de novo a lista da API na hora do resgate para achar o ID pelo horário de expiração.)
- Trate `already_redeemed` como sucesso. Mostre `nothing_to_reset` como mensagem informativa (o crédito *não* se perde). Com `no_credit` e um `credit_id`, atualize a lista: o crédito foi resgatado em outro lugar.
- É um gasto irreversível e visível de um benefício escasso: a interface precisa exigir uma ação explícita e deliberada do usuário (a CLI usa seletor e confirmação), nunca automática.
- Depois de um resgate bem-sucedido, atualize na hora o uso e a lista de créditos: as duas janelas caem para 0% e a contagem diminui, e os widgets devem mostrar isso logo.
