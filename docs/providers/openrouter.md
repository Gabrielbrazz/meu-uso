# OpenRouter

Acompanha o saldo de créditos e o gasto do seu [OpenRouter](https://openrouter.ai) a partir da chave de API da sua conta.

## O que mostra

| Métrica | O que significa |
|---|---|
| Créditos | Gasto total em relação aos créditos que você já comprou (um medidor em dólares) |
| Saldo | Créditos pré-pagos restantes |
| Hoje | Gasto de hoje até agora |
| Esta semana | Gasto desta semana até agora |
| Este mês | Gasto deste mês até agora |
| Limite da chave | Gasto na janela de limite atual em relação ao teto desta chave. Só aparece quando a chave tem um teto configurado |

O Meu Uso mostra o tipo de conta informado (como "Pago por uso" ou "Gratuito") ao lado do nome do provedor.

## De onde vêm as credenciais

Ao contrário dos outros provedores, o OpenRouter não tem um app ou CLI que deixe uma credencial na sua máquina, então você fornece uma chave de API. Crie uma em [openrouter.ai/keys](https://openrouter.ai/keys) e adicione no app (recomendado): abra **Personalizar**, escolha o OpenRouter e, na seção **Chave de API**, clique em **Adicionar**, cole a chave e clique em **Salvar**. A chave fica em `~/.config/meu-uso/openrouter.json`. Se o OpenRouter estiver ativado, o app já atualiza os dados dele na hora; se estiver desligado, ative-o na lista de **Personalizar**.

Você também pode fornecer a chave diretamente. O app confere nesta ordem e usa a primeira chave que encontrar:

1. **Arquivo de configuração:** `~/.config/meu-uso/openrouter.json`, o arquivo que a seção Chave de API grava:

   ```json
   { "apiKey": "sk-or-v1-..." }
   ```

   O arquivo também pode ter só a chave, em texto puro. E `~/.config/openrouter/key.json` também funciona.

2. **Variável de ambiente:** defina `OPENROUTER_API_KEY` (ou `OPENROUTER_KEY`) no perfil do seu shell (por exemplo, `~/.zshrc` ou `~/.zprofile`). Ao abrir, o app lê o ambiente do seu shell de login, então uma chave exportada ali é encontrada mesmo quando o app é aberto pelo Finder ou pelo Dock, e não só quando roda a partir de um terminal. Quando a chave vem daqui, a seção Chave de API mostra a chave como somente leitura ("Da variável de ambiente"), com a opção "Substituir por uma chave personalizada" para trocá-la por uma chave salva.

Uma chave salva pelo app tem prioridade sobre a do ambiente (o arquivo de configuração é conferido primeiro). Apagar a chave salva remove também o `~/.config/openrouter/key.json`, se ele existir, e volta para a chave do ambiente, ou para nenhuma.

## Solução de problemas

- **"Nenhuma chave de API do OpenRouter"**: adicione a chave em Personalizar → OpenRouter → Chave de API (ou no arquivo de configuração ou na variável de ambiente) e atualize.
- **"Chave de API do OpenRouter inválida"**: as duas chamadas recusaram a chave (401/403). Confira a chave ou crie outra em openrouter.ai/keys.

## Por dentro

Duas chamadas REST com um token `Bearer` em `https://openrouter.ai/api/v1`, feitas de forma independente:

- `GET /credits`: `total_credits` e `total_usage` da conta inteira. O medidor de Créditos e o Saldo vêm daqui.
- `GET /key`: o tipo de conta, o gasto diário, semanal e mensal e um teto opcional por chave (`limit` menos `limit_remaining` na janela atual).

O app mostra o que cada chamada trouxe. Se uma falhar, as linhas da outra continuam aparecendo. A chave só é dada como inválida quando as duas chamadas a recusam (401/403), porque o OpenRouter libera alguns endpoints só para certos tipos de chave.

Um gasto de período de `US$ 0,00` aparece como um zero real e medido (a API informa esse valor diretamente), e não como "Sem dados". Os valores de crédito podem ter até ~60 segundos de atraso do lado do OpenRouter.
