# Grok

Acompanha o uso de créditos do Grok Build usando o login da CLI do Grok.

## O que mostra

| Métrica | O que significa |
|---|---|
| Semanal | Porcentagem usada da cota semanal compartilhada (o limite que a cobrança unificada do Grok aplica), com a contagem até a renovação semanal |
| Uso extra | Limite do modo pago por uso, em forma de status (ex.: `limite de 2.500` ou `Desativado`) |
| Tendência de uso | Gráfico diário de tokens dos últimos 30 dias, dos mesmos logs das linhas de gasto |
| Hoje / Ontem / Últimos 30 dias | Custo e tokens locais das sessões concluídas da CLI do Grok |

Quando o Grok informa o seu plano, o Meu Uso mostra o plano ao lado do nome do provedor.

A cota semanal compartilhada é o limite que o Grok aplica às contas com cobrança unificada (o antigo medidor de créditos mensais é legado e não aparece mais). Contas que ainda não migraram para a cobrança unificada não têm cota semanal, então a linha Semanal mostra "Sem dados".

## De onde vêm as credenciais

Entre uma vez pela CLI do Grok (`grok login`); o Meu Uso lê o mesmo `~/.grok/auth.json`. Os tokens de acesso são renovados automaticamente antes de expirar, e os tokens trocados são gravados de volta no arquivo.

## As linhas de gasto

Hoje, Ontem e Últimos 30 dias são calculados **localmente** a partir das sessões concluídas da CLI do Grok em `~/.grok/sessions/` (ou `$GROK_HOME/sessions/`). Isso inclui sessões de subagentes, retomadas e bifurcadas, porque o trabalho delas nem sempre entra no uso da sessão pai. Cópias do mesmo evento concluído contam uma vez por modelo, mesmo que apareçam em vários logs de sessão. O Meu Uso usa o custo que o Grok registrou em cada turno concluído, quando existe. Turnos antigos sem custo registrado são estimados com os [preços dos modelos](../pricing.md) compartilhados. Os dias seguem o fuso horário local do seu Mac, e cada período mostra custo e tokens juntos (`US$ 4,08 · 1,2 mi tokens`). Esses valores são separados dos créditos informados pela API de faturamento do Grok, e nenhum dado das sessões sai do seu Mac. Um período sem uso concluído mostra "Sem dados", e não `US$ 0,00 · 0 tokens`.

## Solução de problemas

- **"Login do Grok expirado" ou "Login do Grok inválido"**: rode `grok login` de novo e atualize.
- **Semanal mostra "Sem dados"**: a sua conta ainda informa um período mensal (não semanal), ou seja, ainda não migrou para a cobrança semanal unificada do Grok.
- **Semanal e Uso extra ficam em branco num login de equipe ou empresa**: o endpoint de créditos do Grok só funciona com uma equipe pessoal (`HTTP 412` / "No personal team"). É uma característica da conta, e não um login com falha. O Meu Uso mantém o card do Grok, mostra o nome do plano quando o endpoint de ajustes (`settings`) o informa e continua preenchendo Hoje, Ontem e Últimos 30 dias pelos logs de sessão locais. Um aviso no cabeçalho ("Contas de equipe não têm cota pessoal…") explica as linhas de cota em branco.
- **As linhas de gasto mostram "Sem dados"**: elas precisam de turnos concluídos da CLI do Grok em `~/.grok/sessions/`. Um turno ainda em andamento não foi registrado. Termine uma sessão da CLI do Grok e atualize.

## Por dentro

`GET https://cli-chat-proxy.grok.com/v1/billing?format=credits` para a cota semanal e o limite do modo pago por uso (a mesma chamada que a própria CLI do Grok faz) e `…/v1/settings` para o nome do plano. A renovação de token passa por `auth.x.ai`. Um 401/403 provoca uma renovação de token e uma nova tentativa.
