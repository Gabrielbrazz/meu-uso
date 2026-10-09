# Devin

Acompanha a sua cota do Devin usando o login da CLI do Devin ou do app Devin.

## O que mostra

| Métrica | O que significa |
|---|---|
| Semanal | Cota semanal usada (quando o Devin oculta a cota diária e não informa nem a porcentagem nem a renovação semanal, mostra o número diário) |
| Diário | Cota diária usada (fica oculta quando o Devin oculta a cota diária) |
| Saldo extra | Saldo de uso extra (excedente), em dólares |

Se o Devin informa a renovação semanal, mas omite a porcentagem semanal, a cota semanal está esgotada (100% usada).

Quando o Devin informa o nome do seu plano, o Meu Uso mostra o plano ao lado do nome do provedor.

## De onde vêm as credenciais

Conferidas nesta ordem; vale a primeira que funcionar:

1. Credenciais da CLI do Devin: `~/.local/share/devin/credentials.toml` (usa `windsurf_api_key` e, quando existe, `api_server_url`)
2. O banco de dados de estado local do app Devin

Se as credenciais da CLI falharem e o app estiver conectado com outra conta, o login do app é usado no lugar.

## Solução de problemas

- **"Rode devin auth login ou entre no Devin…"**: rode `devin auth login` ou entre no app Devin e atualize.
- **Semanal mostra o número diário**: quando o Devin oculta a cota diária e não informa nem a porcentagem nem a renovação semanal, a cota diária aparece na linha Semanal, para ela continuar fazendo sentido.

## Por dentro

Connect RPC `GetUserStatus` no servidor de API configurado (padrão `server.codeium.com`). As porcentagens de cota chegam como "restante" e são invertidas para "usado". Não há renovação de token: um 401/403 passa para a próxima fonte de login.
