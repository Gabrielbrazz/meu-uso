# Cursor

Acompanha o uso do seu plano do Cursor usando o login do app Cursor.

## O que mostra

| Métrica | O que significa |
|---|---|
| Uso total | Uso do plano no ciclo de cobrança (porcentagem ou dólares; em contas Enterprise por requisição, as requisições incluídas usadas em relação ao teto) |
| Modelos do Cursor | Porcentagem de uso dos modelos do próprio Cursor, incluindo Cursor Grok e Composer |
| Outros modelos | Porcentagem de uso dos outros modelos |
| Grok Bot | Porcentagem de uso semanal do Grok Bot e contagem até a renovação; ativado por padrão |
| Uso extra | Gasto sob demanda: o do próprio usuário quando disponível, senão o total da equipe. Vira medidor quando o Cursor informa um limite |
| Requisições | Cópia opcional das requisições incluídas usadas em relação ao teto, para layouts personalizados |
| Créditos | Saldo de créditos restante, somando concessões de crédito e o saldo pré-pago da conta |
| Tendência de uso | Gráfico diário de tokens dos últimos 30 dias, da exportação de uso do Cursor |
| Hoje / Ontem / Últimos 30 dias | Custo estimado e tokens, da exportação de uso do Cursor (veja abaixo) |

Em licenças Teams que trazem as duas porcentagens por grupo de modelos, essas porcentagens substituem o antigo teto em dólares incluído no plano. Uso total usa a porcentagem total estruturada do Cursor quando ela vem, e fica indisponível quando o Cursor manda só os dois grupos. Contas de equipe antigas, sem dados de grupo utilizáveis, mantêm o medidor em dólar. Isso inclui as contas que mandam zeros de preenchimento ao lado de um gasto positivo.

Quando o Cursor informa o nome do seu plano, o Meu Uso mostra o plano ao lado do nome do provedor.

O Grok Bot tem uma franquia de uso própria, separada do medidor normal do ciclo de cobrança do Cursor. A linha dele vem ativada por padrão na seção Sob demanda do Cursor. Ela usa o seu login atual do Cursor, então não é preciso entrar na CLI do Grok.

## De onde vêm as credenciais

Basta estar conectado no app Cursor (ou na CLI do Cursor, com `agent login`). O Meu Uso lê o banco de dados de estado local do Cursor e os itens dele nas chaves do macOS (Keychain) para obter os tokens de sessão. Tokens renovados são gravados de volta. Não há nada extra para instalar ou configurar.

## Histórico de gasto

Hoje, Ontem, Últimos 30 dias e Tendência de uso vêm da exportação de uso do Cursor. O Meu Uso usa a contagem de tokens exportada e os preços dos modelos compartilhados para estimar o custo localmente. A exportação do Cursor às vezes chega atrasada, então os números mais recentes podem ficar para trás da atividade atual. O Meu Uso deixa de fora linhas da exportação com problema, em vez de contar valores quebrados como zero sem avisar. Se o download falhar, se a exportação levar mais de 20 segundos, se o formato dela for inválido ou se a estrutura do CSV estiver quebrada, o histórico de gasto fica indisponível naquela atualização. O uso do plano em tempo real continua atualizando. Cada falha fica registrada no log de diagnóstico, sem incluir os dados de uso exportados.

## Solução de problemas

- **"Nenhum login encontrado", "Sessão expirada" ou "Token expirado"**: abra o Cursor, confira se você está conectado (ou rode `agent login`) e atualize.
- **Algumas métricas não aparecem**: o Cursor omite campos conforme o tipo de plano. Métricas ausentes simplesmente mostram "Sem dados".
- **Uma consulta opcional falhou**: falhas do Grok Bot, do plano, das concessões de crédito, do saldo pré-pago e da consulta alternativa por requisições não derrubam o provedor quando o uso principal está disponível. O Meu Uso registra no log de diagnóstico motivos fixos, sem credenciais.

## Por dentro

Connect RPC em `api2.cursor.sh` (o uso do painel do Cursor e `DashboardService/GetSandUsageStatus` para o Grok Bot); alternativa REST combinada em `cursor.com/api/usage` e `cursor.com/api/usage-summary` para contas Enterprise e de equipe; saldo do Stripe em `cursor.com/api/auth/stripe`; e a exportação CSV de eventos de uso em `cursor.com/api/dashboard/export-usage-events-csv`. A alternativa combina a franquia de requisições incluídas com as porcentagens estruturadas e o gasto sob demanda do usuário. Nenhuma das respostas REST é tratada sozinha como o retrato completo da conta. O pedido principal de uso renova o token e tenta de novo uma vez depois de um 401/403. Falhas de endpoints opcionais não derrubam o provedor quando a outra resposta da alternativa pode ser usada, e ficam registradas no log de diagnóstico. O gasto por dia usa a contagem de tokens exportada, com preço pelos [preços dos modelos](../pricing.md) compartilhados. Os modelos próprios do Cursor (`auto`, `composer-*`, …) vêm da camada suplementar, que os mantenedores sincronizam a partir de [Cursor models & pricing](https://cursor.com/docs/models-and-pricing.md).
