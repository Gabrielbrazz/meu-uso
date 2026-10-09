# OpenCode

Acompanha o seu uso hospedado pelo OpenCode: a assinatura **Go** e o gateway pago por uso **Zen**. As janelas do plano Go vêm da API de uso oficial do OpenCode. As linhas de gasto e a tendência de uso continuam vindo dos logs do OpenCode que já estão no seu Mac.

## O que mostra

| Métrica | O que significa |
|---|---|
| Sessão | Uso do Go na janela móvel de 5 horas, em porcentagem, com a contagem até a renovação |
| Semanal | Uso do Go nesta semana, em porcentagem (renova na segunda-feira, em UTC) |
| Mensal | Uso do Go neste ciclo de cobrança, em porcentagem |
| Hoje / Ontem / Últimos 30 dias | Custo e tokens locais de todo o seu uso hospedado pelo OpenCode (Go + Zen) |
| Tendência de uso | Um gráfico dia a dia dos tokens do último mês |

Quando você tem a assinatura Go, o Meu Uso mostra "Go" ao lado do nome do provedor.

Os medidores de Sessão, Semanal e Mensal valem para a **conta inteira**: são as mesmas porcentagens que o painel do OpenCode mostra, incluindo o uso em outras máquinas. Se você só usa o gateway pago por uso Zen (sem assinatura Go), esses medidores mostram "Sem dados" e só as linhas de gasto trazem números.

## De onde vêm as credenciais

Use o OpenCode normalmente. O Meu Uso lê a chave de API `opencode-go` na pasta de dados local do OpenCode (`~/.local/share/opencode`, ou `$OPENCODE_DATA_DIR` / `$XDG_DATA_HOME`, se você definiu essas variáveis) e a envia como token Bearer para a API de uso. O OpenCode 2 guarda essa chave nos bancos de dados locais; o OpenCode 1, no `auth.json`. O OpenCode 2 deixa para trás uma cópia antiga do `auth.json` depois da atualização. Por isso, quando os bancos de dados já têm credenciais, o Meu Uso ignora esse arquivo, e sair do Go no OpenCode 2 é respeitado. Não há pedido de login nem token para colar. As linhas de gasto continuam lendo os logs SQLite locais nessa mesma pasta.

Quando o OpenCode usa o login OAuth do ChatGPT Pro/Plus que vem nele, esse uso pertence à assinatura do Codex. Ele aparece nas linhas de gasto e na tendência do **Codex** no Meu Uso, incluindo os logs locais do OpenCode 2, e não se mistura aos totais de Go + Zen hospedados pelo OpenCode. Os tokens de cada pedido, separados por tipo, são estimados com as mesmas regras de cache, contexto longo e fast/priority do uso nativo do Codex. Cada canal de lançamento (estável, `opencode.db`; prévia, `opencode-next.db`) é avaliado pelo próprio login, então um canal com chave de API nunca esconde o uso do ChatGPT de outro canal. O tráfego comum com chave de API da OpenAI não é atribuído ao Codex.

## Medidores e linhas de gasto

Os medidores do Go são porcentagens de `GET https://opencode.ai/zen/go/v1/usage`, a contabilidade do próprio OpenCode, e não uma estimativa. Cada linha de gasto mostra custo e tokens juntos (`US$ 4,08 · 1,2 mi tokens`), como no Claude, no Codex e no Cursor. Esses dólares vêm direto do custo por mensagem que o OpenCode registra neste Mac para os gateways hospedados, então podem ser menores que o uso do Go na conta inteira. Um período sem uso local registrado mostra "Sem dados", e não um enganoso `US$ 0,00`. Nenhum dado dos logs sai do seu Mac.

Enquanto a janela móvel de 5 horas não tem uso, a linha Sessão mostra **Não iniciada** no lugar da contagem. Ao passar o mouse, uma dica explica que a sessão começa quando você envia a primeira mensagem. Quando a janela está correndo, a linha mostra a contagem até a renovação, inclusive quando os números inteiros do OpenCode ainda mostram 0% porque menos de 1% foi usado.

## Solução de problemas

- **Sessão, Semanal e Mensal mostram "Sem dados"**: são janelas do plano Go. Os números aparecem quando você está conectado no OpenCode Go e a chave tem uma assinatura ativa. Quem usa só o Zen vê os números nas linhas de gasto.
- **"A chave do OpenCode Go foi recusada"**: a chave local não foi aceita. Entre no OpenCode Go de novo. Se você tem uso local, as linhas de gasto continuam aparecendo, sem essa mensagem, e só os medidores do Go ficam em "Sem dados". O mesmo vale quando a API de uso não responde.
- **"Nenhuma assinatura do OpenCode Go nesta chave"**: a chave é válida, mas esta conta não está no Go. As linhas de gasto continuam funcionando se você usa o Zen neste Mac.
- **"Não foi possível ler o auth.json do OpenCode"**: o arquivo existe, mas não pode ser lido ou não é um JSON válido. Confira as permissões ou entre no OpenCode Go de novo para regravá-lo.
- **As linhas de gasto mostram "Sem dados"**: o Meu Uso precisa do banco de dados local do OpenCode em `~/.local/share/opencode/opencode*.db`. Use o OpenCode numa sessão e atualize.
- **"Não foi possível ler o banco de dados local do OpenCode"**: o banco de dados (ou a pasta de dados) existe, mas não pôde ser lido nesta atualização. Se você está no Go, os medidores de porcentagem continuam atualizando. Encerre o OpenCode e atualize para as linhas de gasto voltarem. Se o problema continuar, confira as permissões de `~/.local/share/opencode`.

## Por dentro

Janelas do Go: `GET https://opencode.ai/zen/go/v1/usage` com a chave `opencode-go` como `Authorization: Bearer …`. A resposta é `{ usage: { rolling, weekly, monthly } }`, cada um com `percent` e `resetsAt`. Um 401 é uma chave recusada; um 403 `EntitlementError` quer dizer que não há assinatura Go.

Linhas de gasto e tendência: os campos `cost` e de tokens das mensagens do assistente em todo `opencode*.db` da pasta de dados. O OpenCode separa o banco de dados por canal de lançamento (o estável é `opencode.db` e a linha de prévia é `opencode-next.db`), então todos os canais são somados. Contam tanto `opencode-go` (Go) quanto `opencode` (Zen). O OpenCode 1 grava na tabela `message` e o OpenCode 2 na `session_message`. As duas são lidas, e compactações de contexto concluídas também contam. O OpenCode 2 copia as mensagens antigas para a tabela nova com o mesmo ID, então cada mensagem conta uma vez. Tudo só leitura.
