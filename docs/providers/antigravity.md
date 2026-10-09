# Antigravity

Acompanha as cotas do Antigravity (a IDE de IA do Google) com as credenciais que o app ou a CLI `agy` já guardaram no seu Mac.

## O que mostra

O Antigravity tem duas cotas compartilhadas, e cada uma tem duas janelas: uma janela móvel de 5 horas e uma janela semanal.

| Métrica | O que significa |
|---|---|
| Sessão | A cota compartilhada do Gemini (Pro e Flash usam a mesma cota), na janela móvel de 5 horas |
| Semanal | A janela semanal dessa mesma cota do Gemini |
| Claude | A cota compartilhada dos modelos que não são Gemini (Claude, GPT-OSS, …), na janela móvel de 5 horas |
| Claude semanal | A janela semanal dessa mesma cota |
| Tendência de uso | Uso diário de tokens nas conversas locais do Antigravity |
| Hoje / Ontem / Últimos 30 dias | Uso local de tokens e gasto estimado, equivalente ao da API |

Quando o Antigravity informa o seu plano (como `Pro` ou `Ultra`), o Meu Uso mostra o plano ao lado do nome do provedor.

O Gemini Pro e o Gemini Flash formam uma cota só: usar qualquer um dos dois consome a mesma cota. Por isso o Meu Uso mostra um medidor por janela, e não medidores separados para Pro e Flash. Esse par se chama Sessão e Semanal, como nas linhas dos outros provedores. Todos os modelos que não são Gemini dividem a segunda cota, que aparece com o nome Claude (como o par Spark do Codex). A API de cotas informa frações. O uso de tokens e o gasto estimado vêm à parte, dos bancos de dados locais das conversas.

Enquanto a janela de 5 horas de uma cota ainda não tem uso, o medidor mostra **Não iniciada** no lugar da contagem até a renovação. Ao passar o mouse, uma dica explica que a sessão começa quando você envia a primeira mensagem. Os medidores semanais sempre mostram a contagem normal até a renovação.

## De onde vêm as credenciais

O Meu Uso nunca pede um token. Ele lê o que o Antigravity já tem:

- **Antigravity aberto:** o Meu Uso conversa com o servidor de linguagem local do app. É a fonte mais completa, e é de onde vem o nome do plano.
- **App fechado:** ele usa o token OAuth que o Antigravity e o `agy` guardam nas chaves do macOS (Keychain) e consulta a API Cloud Code do Google. Um token expirado é renovado automaticamente (o Meu Uso nunca grava no item das chaves do próprio Antigravity). O cache de curta duração desse token só é reaproveitado enquanto o mesmo login continuar presente e legível nas chaves do macOS.

Se nenhum dos dois estiver disponível, você verá *Abra o Antigravity ou rode `agy` e tente de novo.*

## Gasto e histórico de uso

O Meu Uso lê a contagem de tokens de cada geração, incluindo o prompt de sistema fixo, em todas as pastas `~/.gemini/antigravity*/conversations` (da CLI `agy`, da IDE Antigravity, do app Antigravity 2.0 e das sessões ACP). Com esses números, ele estima o custo equivalente ao da API usando os [preços dos modelos](../pricing.md) compartilhados. Hoje, Ontem e Últimos 30 dias entram no card Gasto total, junto com os outros provedores. São estimativas, não cobranças da sua assinatura do Antigravity, e os dados das conversas nunca saem do seu Mac. Conversas já lidas são reaproveitadas a cada atualização, então só os registros de geração novos precisam ser lidos.

Quando o seletor de modelo está no padrão, o Antigravity registra um ID genérico (`gemini-default`, `gemini-pro-default`) e grava o modelo que de fato respondeu como um nome de exibição, por exemplo "Gemini 3.1 Pro (High)". O Meu Uso calcula o preço dessas respostas pelo nome de exibição. Se esse nome não tiver preço conhecido, ele usa o ID genérico (`gemini-pro-default` tem o preço do Gemini 3.1 Pro). O que mesmo assim ficar sem preço continua visível no aviso de modelo desconhecido.

O detalhamento por modelo agrupa por família: variantes de esforço como `gemini-3.1-pro-low`, nomes de exibição e IDs genéricos entram todos na linha `gemini-3.1-pro`, porque têm o mesmo preço. Nomes que o Meu Uso não consegue mapear ficam com o texto original. Registros de contexto de prompt sem modelo e sem tokens gerados não são gerações e são ignorados.

Subagentes que o Antigravity abre com um nível de modelo (`flash_lite`, `flash`, `pro`) aparecem no log com um ID terminado em `-tiered`, como `gemini-3.7-flash-tiered`. É o mesmo modelo, com o mesmo preço, então o uso entra na linha do modelo base.

Os logs de transcrição não trazem a contagem de tokens, por isso não são usados. Modelos ausentes ou sem preço não recebem um preço inventado. Registros de geração grandes demais são pulados, com um aviso no log, para manter o uso de memória sob controle.

## Solução de problemas

- **"Abra o Antigravity ou rode `agy`…"**: entre no app Antigravity (ou rode `agy`) para que exista um token válido e atualize.
- **"Não foi possível ler as credenciais do Antigravity…"**: desbloqueie as chaves do macOS ou entre no Antigravity de novo. O Meu Uso não usa o token de acesso em cache enquanto não conseguir confirmar o login atual.
- **Os medidores semanais mostram "Sem dados"**: a sua versão do Antigravity ainda não tem o endpoint de resumo de cotas (só as versões mais novas têm). Os medidores de 5 horas continuam funcionando pelos endpoints antigos. Atualize o Antigravity para os medidores semanais voltarem.
- **Um medidor mostra "Sem dados"**: essa cota ou janela não veio na última resposta (alguns planos só informam certas janelas). Os outros medidores continuam atualizando.
- **O gasto ou o histórico de uso mostram "Sem dados"**: o Antigravity ainda não gravou bancos de dados de conversa que possam ser lidos. Use o Antigravity ou o `agy` numa sessão e atualize.
- **Onde foram parar os medidores do Gemini Pro e do Flash?** Eles foram unidos: os dois modelos usam a mesma cota compartilhada do Gemini, que agora é o medidor único de Sessão.
- **As cotas parecem esgotadas depois de muito uso**: as janelas de 5 horas renovam de forma contínua, e as semanais, uma vez por semana. Cada medidor mostra quando renova.

## Por dentro

A melhor fonte vem primeiro: o servidor de linguagem local, encontrado procurando o processo `language_server` / `agy` e lendo o token CSRF e as portas em que ele escuta. Depois vem o Google Cloud Code, com o token das chaves do macOS, renovado pelo OAuth do Google quando preciso. O Meu Uso vincula o cache do token renovado a um hash de mão única da credencial de renovação que está nas chaves do macOS. Assim, logout, troca de conta, caches antigos e entradas expiradas ou malformadas nunca reaproveitam o token de acesso de uma conta anterior.

Em cada fonte, o Meu Uso chama primeiro o endpoint de resumo de cotas (`RetrieveUserQuotaSummary` no servidor de linguagem, `v1internal:retrieveUserQuotaSummary` no Cloud Code). É o único endpoint que informa as cotas unidas e as janelas semanais. Versões sem ele caem nos endpoints antigos, por modelo (`GetUserStatus` / `GetCommandModelConfigs` localmente, `fetchAvailableModels` / `retrieveUserQuota` remotamente). As cotas por modelo são reunidas nas duas cotas compartilhadas, ficando com a menor fração restante de cada uma, e esses endpoints só conhecem as janelas de 5 horas. Para o nome do plano, o Meu Uso prefere o `userTier` do próprio Antigravity ao campo de plano herdado do Windsurf. O histórico de gasto vem dos registros protobuf de contabilização de geração em cada banco de dados local de conversa.

Agradecimentos a [FelixIsaac](https://github.com/FelixIsaac), que identificou o banco de dados das conversas como fonte e contribuiu com a primeira implementação em SQLite/protobuf na [issue robinebers/openusage#1120](https://github.com/robinebers/openusage/issues/1120) e no [pull request robinebers/openusage#1058](https://github.com/robinebers/openusage/pull/1058).

> Obtido por engenharia reversa do app e do binário do servidor de linguagem. Endpoints e armazenamento podem mudar sem aviso.
