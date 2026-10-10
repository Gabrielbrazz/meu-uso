# Codex

Acompanha os limites da sua assinatura do ChatGPT/Codex usando o login da CLI do Codex.

## O que mostra

| Métrica | O que significa |
|---|---|
| Sessão | Uso na janela móvel de 5 horas |
| Semanal | Uso na janela de 7 dias |
| Spark / Spark semanal | Limites do modelo GPT-5.3-Codex-Spark: uma janela de 5 horas e uma semanal. Só aparecem quando a sua conta tem esse limite (senão, "Sem dados") e, por padrão, ficam escondidos atrás da seta "Mostrar mais" |
| Renovações de limite | Renovações sob demanda do limite de uso, mostradas como contagem (ex.: `2 disponíveis`), com um ponto colorido para a que expira primeiro. Passe o mouse sobre o valor para ver uma linha do tempo com a validade de cada uma |
| Uso extra | Créditos flex, em dólares e em créditos (ex.: `US$ 31,84 · 796 créditos`; cada crédito vale US$ 0,04) |
| Tendência de uso | Gráfico diário de tokens dos últimos 30 dias, da mesma fonte das linhas de gasto |
| Hoje / Ontem / Últimos 30 dias | Gasto local, em custo, tokens ou ambos (veja abaixo) |

Quando o Codex informa o nome do seu plano, o Meu Uso mostra o plano ao lado do nome do provedor. Os planos Pro usam os nomes atuais **Pro 100**, **Pro 200** e **Pro 500**, no lugar dos antigos multiplicadores de uso.

| Plano na API de uso | Nome exibido |
|---|---|
| `prolite` | Pro 100 |
| `pro` | Pro 200 |
| `promax` | Pro 500 |
| `self_serve_business_prolite` | Business Premium |

Os nomes Pro seguem os [nomes de plano publicados pela OpenAI](https://learn.chatgpt.com/docs/dots#access). O mapeamento dos identificadores Pro foi conferido no app ChatGPT para desktop da OpenAI, versão 26.928.21956 (build 12404). Os outros planos Business e de equipe mantêm os nomes que já tinham. Identificadores de plano desconhecidos ganham um nome legível. Se o Codex informar só uma janela de 7 dias, ela vira Semanal, sem inventar um medidor de Sessão de 5 horas.

## De onde vêm as credenciais

Entre uma vez pela CLI do Codex (`codex`). O Meu Uso lê os mesmos arquivos de login (respeitando `$CODEX_HOME`) e, como reserva, as chaves do macOS (Keychain). Os tokens são renovados automaticamente e gravados de volta no mesmo arquivo de login ou item das chaves de onde vieram.

Nas chaves do macOS, o Meu Uso escolhe o item da CLI do Codex para `$CODEX_HOME` (ou `~/.codex`, se a variável não estiver definida), inclusive quando essa pasta é um link simbólico. Outras pastas do Codex podem ter logins próprios nas chaves. O Meu Uso não pega um item sem relação só porque ele tem o mesmo nome de serviço.

### Contas do Codex Swap

O Meu Uso mostra as contas salvas pelo [Codex Swap (`xswap`)](https://github.com/maddada/codex-swap). Cada conta e espaço de trabalho ganha um card próprio, com o apelido e o e-mail. Cards e estrelas da barra de menus continuam com a mesma conta quando você troca o login padrão. Reinicie o Meu Uso depois de adicionar, remover ou renomear uma conta. Locais personalizados definidos com `XSWAP_HOME` ou `XDG_DATA_HOME` funcionam. Na primeira abertura depois de atualizar de uma versão sem suporte ao Swap, o app renova os ajustes de shell salvos antes de procurar as contas.

- Logins correspondentes em arquivo, nas chaves do macOS e no Swap dividem um card. Se um expirar, o Meu Uso tenta outro login da mesma conta. Contas que só existem nas chaves do macOS e pastas principais personalizadas do Swap também entram, mesmo sem um slot salvo no Swap. As leituras das chaves rodam em segundo plano.
- O Meu Uso só lê as credenciais do Swap; quem as renova é o Codex. Se um card precisar de login, rode `xswap run <conta>` ou `xswap login <conta>` e atualize o Meu Uso.
- Sessões simultâneas de `xswap run` funcionam. Feche as sessões do Codex antes de usar `xswap switch` para trocar o login global, como o Swap exige.

### Outras pastas do Codex e logins do pi

O Meu Uso também encontra contas conectadas em `CODEX_HOME`, `~/.codex`, `~/.config/codex`, nas pastas irmãs `~/.codex-*` e `~/.config/codex-*` e no `auth.json` do pi (`openai-codex`, `openai-codex-2`, …). Os logins são agrupados por espaço de trabalho do ChatGPT e e-mail. Assim, dois usuários no mesmo espaço de trabalho continuam em cards separados, e a mesma conta conectada em várias pastas e no pi divide um card só. O nome do card é o apelido no xswap; se não houver, o rótulo no pi; e, por último, o espaço de trabalho e o e-mail. Um login guardado só nas chaves do macOS também conta como conta. Com uma única conta, fica o card Codex normal. Ele ainda usa um login encontrado só numa pasta irmã ou no pi e soma os logs de sessão dessa pasta nas linhas de gasto. Reinicie o Meu Uso depois de adicionar ou remover um login.

Um card renova o token nas próprias pastas do Codex do mesmo jeito que o card Codex normal. Assim, uma conta que você só usa por uma segunda pasta continua funcionando entre as sessões. O card normal faz o mesmo quando há uma pasta irmã sozinha. Logins do xswap, do pi ou das chaves do macOS são lidos como estão: o Meu Uso nunca troca esses tokens, mesmo quando `CODEX_HOME` é um link para uma pasta que o xswap gerencia ou aponta para um slot do xswap que não indica conta. Cada fonte é relida a cada atualização. Um login que outra ferramenta mudou no meio da atualização não é tocado (um token renovado que não pôde ser salvo ainda serve para aquela atualização), e cada card tenta todos os logins correspondentes. Se um login só de leitura expirou, use essa conta uma vez no xswap ou no pi para a ferramenta renovar o próprio token e atualize o Meu Uso.

### Qual gasto vai para qual card

Os logs de sessão do Codex não dizem qual conta os gerou, então o Meu Uso se guia pela pasta: o gasto de cada pasta do Codex vai para a conta conectada nela agora.

- O gasto da pasta de uma conta aberta com `xswap run` vai para essa mesma conta.
- O gasto da pasta principal (`~/.codex` ou `$CODEX_HOME`) vai para quem estiver conectado nela agora. Depois de um `xswap switch`, todo o histórico dessa pasta passa para a nova conta, e o card da conta antiga deixa de mostrá-lo na próxima atualização.
- A opção **share history** do Swap faz uma pasta de conta reaproveitar a pasta de sessões da pasta principal, em vez de ter a sua. Essas sessões ficam num lugar só e contam uma vez, para a conta da pasta principal. O share history não tem suporte completo: depois de um `xswap switch`, o card da conta antiga pode continuar mostrando o gasto de antes da troca, e o mesmo gasto aparece em dois cards.
- Quando o login de uma pasta não indica conta, o gasto dela vai para a conta que o xswap registrou ali ou, se não houver, para o login das chaves do macOS na pasta principal. Sem nenhum dos dois, ele não vai para nenhum card.
- O gasto do pi vai para a conta do login `openai-codex` do pi. Depois de trocar esse login, reinicie o Meu Uso. O gasto do OpenCode vai para a conta conectada na pasta principal.

Com uma conta só, tudo isso cai no único card. Os limites em tempo real e as ações de renovação funcionam em todos os cards de qualquer forma.

## As linhas de gasto

Sessões copiadas contam uma vez por card; uma sessão copiada para as pastas de duas contas conta nas duas. O histórico sincronizado pelo iCloud precisa ser da mesma conta e do mesmo espaço de trabalho do card.

**Personalizar → Codex → Estimativas de custo → Modelo de referência** estima, se você quiser, o uso que não tem preço conhecido. O padrão é **Nenhum**. Escolha um modelo público para usar os preços dele nessas estimativas; preços de modelos conhecidos e custos registrados não mudam. O aviso de modelo desconhecido e a dica dele continuam visíveis quando há um modelo de referência. Trocar a opção recalcula o histórico local, sem mudar o modelo que o Codex usa. Veja os detalhes em [preços dos modelos](../pricing.md).

Hoje, Ontem e Últimos 30 dias são calculados **localmente**: o Meu Uso lê sozinho os rollouts de sessão da CLI do Codex em `~/.codex/sessions/` e `archived_sessions/` (ou em `$CODEX_HOME`), sem ferramentas externas. Links simbólicos são seguidos, então uma pasta do Codex ligada a um local sincronizado (uma pasta do Dropbox, por exemplo) é lida do mesmo jeito.

Outras fontes também contam:

- **pi:** o uso do Codex pelo agente de programação [pi](https://github.com/earendil-works/pi) também entra. O Meu Uso lê os logs de sessão do pi em `~/.pi/agent/sessions/` (ou em `$PI_CODING_AGENT_SESSION_DIR`) e soma o uso do Codex encontrado ali às mesmas linhas e à tendência.
- **OpenCode:** o mesmo vale quando o OpenCode usa o login OAuth do ChatGPT Pro/Plus que vem nele. O Meu Uso lê as linhas `openai` do banco de dados local do OpenCode, incluindo os logs mais novos do OpenCode 2, e as atribui ao Codex. Os logs novos do OpenCode 2 só contam a partir desse login no ChatGPT; os logs antigos do OpenCode continuam contando como antes. O OpenCode tem um banco de dados e um login por canal de lançamento (estável e prévia), e cada um é avaliado pelo próprio login. Assim, um canal de prévia no ChatGPT continua contando quando o canal estável usa chave de API, e vice-versa. O tráfego do OpenCode com chave de API não entra.

Os dias seguem o fuso horário local do seu Mac, então batem com o seu calendário. Cada período é uma linha que mostra custo e tokens juntos (`US$ 4,08 · 1,2 mi tokens`). Um dia sem uso mostra **Sem dados**, e não um enganoso `US$ 0,00 · 0 tokens`, como em todos os outros provedores com gasto. Os medidores de Sessão e Semanal em tempo real não são afetados.

Os dólares são estimados a partir da contagem de tokens, com preços de API, usando os [preços dos modelos](../pricing.md) compartilhados (ao passar o mouse sobre o valor, o app avisa que é uma estimativa). Sessões que rodaram no nível de serviço fast/priority ou Ultrafast, conforme o log da própria sessão, usam os preços correspondentes exatamente nesses turnos. Logs antigos sem esse dado, e todo o resto, usam o preço padrão. A configuração atual do `config.toml` não é consultada, então mudar o nível nunca muda o preço de dias passados. O uso de revisão automática mantém o nome `codex-auto-review` no detalhamento por modelo, e o custo dele usa o modelo datado disponível como reserva para aquele evento. O uso do Luna Reserve também mantém o nome, `gpt-reserve`, com preço do GPT-5.6 Luna. Já a contagem de tokens é medida. Sessões de subagentes e sessões bifurcadas copiam o histórico de tokens da sessão pai para o próprio log; o Meu Uso reconhece essas cópias e conta cada token uma vez, não importa quantos subagentes uma sessão crie. Nenhum dado dos logs sai do seu Mac.

Arquivos de sessão grandes são lidos em pedaços pequenos, sem carregar tudo na memória. Registros individuais grandes demais são pulados e anotados no log. Por isso, o gasto local pode ficar incompleto se um registro pulado tinha uso.

Nos modelos GPT-5.4, GPT-5.5, GPT-5.6 e GPT-6 suportados, pedidos acima de 272 mil tokens de entrada usam o preço de contexto longo da OpenAI no pedido inteiro. Essas regras específicas do Codex valem igualmente para os logs nativos do Codex e para o uso do OAuth do Codex com custo zero importado do pi ou do OpenCode. O uso do Daybreak Blue tem o preço do GPT-5.6 Sol, conforme o alias e o preço do Daybreak publicados pela OpenAI. A entrada em cache usa o desconto de leitura de cache publicado, quando a fonte de preços tem esse dado; senão, é estimada pelo preço cheio de entrada. As estimativas fast/priority usam o multiplicador do Codex publicado para cada modelo (por exemplo, 2,5× no GPT-5.5). O Ultrafast é 6× no GPT-6 Astra e, nos outros modelos, usa o multiplicador do Fast. Nomes de modelo terminados em `-fast` são normalizados para o preço base, sem escala, antes de o multiplicador ser aplicado uma única vez.

## Solução de problemas

- **"Nenhum login encontrado"**: rode `codex`, entre e atualize.
- **Uma conta do Codex Swap precisa de login** (o card mostra "Nenhum login válido para esta conta do Codex…"): rode `xswap login <conta>` para a conta indicada e atualize.
- **Uma conta que só existe no pi precisa de login** (mesma mensagem): use essa conta no pi para renovar o token e atualize o Meu Uso.
- **Configurações só com chave de API** ("Uso indisponível para chave de API.") não leem o uso da assinatura. Entre com a sua conta do ChatGPT.
- **As linhas de gasto mostram "Sem dados"**: o Meu Uso não achou uso do Codex que conte nos logs do Codex, do pi ou do OpenCode dos últimos 30 dias. Se a sua pasta do Codex fica num lugar diferente, defina `CODEX_HOME` para a CLI do Codex e o Meu Uso olharem no mesmo lugar.
- **O uso do OpenCode não aparece**: o OpenCode precisa ter, agora, uma credencial OAuth `openai` no `auth.json` ou, no OpenCode 2, na tabela `credential` daquele canal. Uma chave de API da OpenAI fica de fora dos totais da assinatura do Codex de propósito. Sair do OpenCode 2 interrompe a atribuição daquele canal, mesmo que a entrada antiga no `auth.json` continue no disco.

## Por dentro

`GET https://chatgpt.com/backend-api/wham/usage` com o token OAuth do Codex; a renovação passa por `auth.openai.com`. Um 401/403 provoca uma renovação de token e uma nova tentativa. Sessão e Semanal são classificadas pela duração de cada janela de uso, e não pela posição primary/secondary. Isso importa quando o Codex tira um limite temporariamente e passa a janela semanal que sobrou para a posição primary. Respostas sem uma duração reconhecida mantêm a regra antiga de compatibilidade (primary como Sessão, secondary como Semanal). Os headers da resposta preenchem as porcentagens que faltarem na janela correspondente.

Nos cards do Codex Swap, um 401/403 tenta o próximo token de acesso correspondente, sem renovar tokens. Se as credenciais mudarem enquanto um pedido está em andamento, o resultado é descartado e o pedido é refeito com os logins correspondentes atuais. A ação de usar uma renovação também fica presa à conta do card, inclusive depois de uma troca do login padrão.

Spark e Spark semanal vêm da lista `additional_rate_limits` da mesma resposta: limites por modelo que reaproveitam a classificação de Sessão e Semanal pela duração. O Meu Uso mostra nesses dois medidores a entrada cujo nome identifica o GPT-5.3-Codex-Spark. Contas sem esse limite simplesmente não têm a entrada, e as linhas mostram "Sem dados". Os outros limites por modelo dessa lista não aparecem.

O Meu Uso preserva o `used_percent` informado pelo Codex sem mudança. Se a API informar 1% usado numa janela intocada, o app mostra 99% restante; se informar 0%, mostra 100% restante. As linhas do Codex usam o rótulo normal de renovação, sem deduzir um estado especial de "Não iniciada". A projeção de ritmo ainda espera passar uma parte suficiente da janela, e haver algum uso de fato, para fazer uma projeção útil.

A linha "Renovações de limite" mostra quantas renovações sob demanda você tem, por exemplo `2 disponíveis`, com um ponto colorido para a que expira primeiro: verde se o prazo passa de 7 dias, amarelo se é de até 7 dias e vermelho se é de até 48 horas. O Meu Uso também tenta chamar `GET https://chatgpt.com/backend-api/wham/rate-limit-reset-credits`, o endpoint próprio que lista a validade de cada renovação. Ao passar o mouse sobre o valor, essas datas aparecem numa janela do Meu Uso: uma linha do tempo das renovações, da mais próxima para a mais distante, cada uma com um ponto colorido numerado, o horário exato da expiração (`em 12 de jul. às 17:30`) e, à direita, a contagem até lá (`12d 18h`). Sem renovações, a linha mostra `0 disponíveis` e a janela diz `Você não tem renovações de limite`. Se a chamada própria falhar, a linha usa a contagem que vem no corpo da resposta de uso (`rate_limit_reset_credits.available_count`). Como esse corpo não traz a validade de cada renovação, a janela mostra a contagem (`N disponíveis`) e avisa `Horários de expiração indisponíveis`, em vez de dar a entender que não existe nenhuma.

### Usar uma renovação pela linha do tempo

Você também pode usar uma renovação direto nessa janela. É o mesmo resgate que o seletor "Usage limit resets" da CLI do Codex faz. Passe o mouse sobre uma renovação na linha do tempo e aparece o botão **Usar**. Ao clicar, ela se abre numa confirmação ali mesmo ("Renova seus limites de uso imediatamente. Esta ação não pode ser desfeita."), com **Renovar** e **Cancelar**. Confirmar resgata exatamente aquela renovação e renova na hora as suas janelas de 5 horas e semanal. Depois, o app atualiza o Codex para os medidores e a contagem restante refletirem a mudança, e só então aparece a mensagem de sucesso ("Limites renovados. Aproveite!").

Proteções, porque um resgate não tem volta:

- O resgate é sempre um fluxo deliberado de dois cliques, dentro da janela que abre ao passar o mouse. Nada é resgatado automaticamente.
- Cada resgate mira uma renovação específica (conferida de novo numa lista atualizada na hora do resgate) e leva uma chave de idempotência. Assim, uma nova tentativa depois de um erro de rede nunca gasta uma segunda renovação.
- Se a renovação já foi usada em outro lugar (na CLI ou na web), a janela avisa que ela não está mais disponível e atualiza. Se o seu uso ainda não precisa ser renovado, o Codex recusa sem gastar a renovação, e a janela avisa. Depois que um resgate renova o uso, os outros botões Usar ficam desativados ("Nada para renovar agora") até você abrir a janela de novo.

### Histórico local lento

As atualizações das cotas em tempo real esperam no máximo cinco segundos pelo processamento do histórico local de tokens. Se um histórico grande demorar mais, a cota é atualizada mesmo assim, e o card mostra o aviso "O histórico local de tokens ainda está sendo atualizado." Uma varredura por provedor continua em segundo plano, e uma atualização seguinte pega o resultado. O histórico já carregado é mantido durante a espera. Um histórico pendente não mostra um "Sem dados de uso" antes da hora. Logo depois de abrir o app, a cota pode aparecer antes do histórico. Falhas de rede e de autenticação continuam com o tratamento normal de dados desatualizados.
