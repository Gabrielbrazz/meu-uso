# Painel

A tela principal da janela que abre pelo ícone do Meu Uso na barra de menus. Cada provedor é uma seção, e cada seção mostra as métricas que você ativou.

## Primeira abertura

Uma instalação nova não ativa todos os provedores que o Meu Uso conhece. Ela começa com Claude, Codex e Cursor e logo confere quais provedores têm credenciais no seu Mac (logins locais, chaves de API salvas ou variáveis de ambiente suportadas; nada é enviado para lugar nenhum). Depois passa a usar exatamente esse conjunto. Se não encontrar nada, ficam Claude, Codex e Cursor. Um card no topo do painel, **Boas-vindas ao Meu Uso**, explica isso e leva a **Personalizar** pelo botão **Abrir Personalizar**. Lá você ativa ou desativa qualquer provedor. O card fica até você fechá-lo no ✕.

Essa detecção completa só acontece numa instalação nova. Atualizações nunca mudam os provedores que você já ativou ou desativou. Mas, quando uma atualização traz um provedor que você nunca viu, a mesma verificação local roda uma vez, só para ele, e ele só é ativado se você tiver mesmo a ferramenta. Veja [Quais provedores ficam ativados](provider-enablement.md) para o ciclo completo.

Cada card de provedor começa pelas métricas de **Sempre visível**. As métricas que você colocou em **Sob demanda** ficam guardadas atrás da seta do card: clique nela para mostrá-las logo abaixo e clique de novo para recolher. Cards abertos continuam abertos quando você fecha a janela ou reinicia o app. Um provedor sem métricas sob demanda e sem botões de atalho não mostra a seta.

Ao abrir um card, as métricas guardadas aparecem abaixo da seta numa coluna só, e cada linha de detalhe ocupa a largura toda do card.

Um card de provedor também pode ter **botões de atalho** no fim da parte expandida, como **Status**, **Painel** e **Uso**, que abrem as páginas do próprio provedor no seu navegador padrão. Eles fazem parte da área expandida, então recolher a seta esconde os botões junto com as métricas guardadas. Cabem até três botões por linha; se houver mais, eles passam para uma segunda linha.

## Gasto total

Quando algum provedor ativado acompanha o gasto diário (Antigravity, Claude, Codex, Cursor, Grok ou OpenCode), aparece um card acima das seções dos provedores. O título é um menu para escolher **Custo**, **Custo/MTok** ou **Tokens** (o padrão é Custo, e a escolha continua valendo depois de reiniciar o app). Um seletor em cápsula troca o período entre **Hoje**, **Ontem** e **30 dias**. O anel, o total no centro e a legenda em ordem seguem a métrica escolhida:

- **Custo**: cada fatia é a parte daquele provedor no total em dólares (quem gastou mais vem primeiro).
- **Custo/MTok**: o tamanho de cada fatia é o valor por milhão de tokens daquele provedor. O centro mostra a média combinada dos provedores que têm gasto e tokens, e a legenda mostra o valor de cada um.
- **Tokens**: cada fatia é a parte daquele provedor no total de tokens.

O centro do anel sempre tem duas linhas curtas: um número compacto em cima e a unidade embaixo, mais discreta (`US$ 533` / `dólares`, `12,4` / `milhões` ou `US$ 1,37` / `MTok`). Assim Custo/MTok e totais grandes cabem no meio do anel. Nos modos de custo, o `US$` fica junto do número. Passe o mouse no centro para ver o valor exato numa linha só. Em Custo e Custo/MTok, ele vem com o aviso "Estimativa local, pode não ser exata" quando os dólares de algum provedor são estimados no Mac. Cada provedor tem uma cor fixa, tirada da marca dele (o terracota do Claude, o verde da OpenAI e assim por diante), e mesmo uma parte mínima continua visível no anel. Provedores sem nada na métrica escolhida simplesmente não aparecem; eles nunca contam como zero. (Um provedor ativado conta mesmo que você tenha ocultado as linhas de gasto dele em Personalizar. Outras linhas em dólar, como o gasto de API do OpenRouter, nunca entram na soma.)

O botão de copiar no cabeçalho (ou **Compartilhar captura de tela**, no clique com o botão direito no card) copia para a área de transferência um PNG do anel com a marca do app, igual ao compartilhamento de um card de provedor. O cabeçalho também tem um pequeno ⓘ com os provedores que entram no total (por exemplo, "Inclui apenas Claude, Codex e Cursor."). Um período sem nada para mostrar na métrica escolhida exibe uma mensagem discreta, como "Sem dados de custo neste período", em vez de esconder o card. Não quer o card? Desative **Mostrar gasto total** no topo dos [Ajustes](settings.md).

## Linhas

**Métricas com limite** (sessão, semanal, créditos com teto) mostram uma barra de progresso com:

- Um preenchimento cuja cor é um veredito sobre o período inteiro, com base no seu ritmo de consumo atual. Fica azul enquanto você está a caminho de terminar com pelo menos 10% de folga. Fica amarelo quando a projeção cai nos últimos 10%, ainda com um pouco de margem. Fica vermelho quando a projeção indica que o limite vai esgotar antes da renovação, ou que você vai terminar exatamente no limite, sem folga nenhuma. Então uma barra pela metade, mas consumida rápido demais, já fica vermelha, e uma barra quase esgotada, mas que chega com calma à renovação, continua azul. Barras sem período de renovação (como um saldo de créditos) e períodos novos demais para projetar usam o próprio nível: amarelo a partir de 80% usado, vermelho quando resta 10% ou menos. As cores vêm da paleta do sistema, então se adaptam ao modo claro ou escuro e aos ajustes de acessibilidade. Elas nunca mudam quando você alterna entre Usado e Restante.
- Um título como `52% restante` ou `48% usado`. **Clique nele** para alternar entre Usado e Restante em todo o app. Passar o mouse mostra a leitura oposta.
- Um texto de renovação como `Renova em 3h 25min` ou `Renova hoje às 18:38`. **Clique nele** para alternar entre contagem regressiva e horário exato em todo o app. Passar o mouse mostra o outro formato.
- Por padrão, uma barra azul não mostra nada a mais. Com **Sempre mostrar o ritmo** ativado (em Ajustes), ela também ganha a marca de ritmo constante na barra e uma nota discreta, `~35% restante na renovação`, ao lado do nome da métrica. Mesmo assim, uma métrica ainda sem uso fica sem esses extras: não há ritmo para projetar enquanto nada foi gasto.
- Uma barra amarela ganha a nota `~3% de folga`, alinhada à direita, ao lado do nome da métrica, e a marca de ritmo constante na barra (onde o uso estaria se você consumisse por igual ao longo do período). Essa folga é sempre de pelo menos 1%. Se a projeção é terminar sem folga nenhuma, a barra fica vermelha (por isso uma barra amarela nunca mostra `~0% de folga`).
- Uma barra vermelha troca a nota por uma chama vermelha ao lado do nome da métrica, com a hora prevista para o limite esgotar: `Esgota em 3h 5min` ou `Esgota hoje às 23:49`, no mesmo formato (contagem regressiva ou horário exato) do texto de renovação. A marca de ritmo constante continua na barra. **Clique no horário** para trocar o formato em todo o app, como no texto de renovação. Quando a projeção é terminar exatamente no limite (sem esgotar antes da renovação, mas sem folga), a chama aparece sozinha, sem horário.
- Quando o saldo acaba (vazio de fato, ou tão perto disso que arredonda para `0`, como `0% restante` ou `US$ 0,00`), a barra fica vermelha e a chama mostra `Limite atingido`, por mais calmo que o ritmo parecesse. Uma barra visivelmente vazia nunca mostra uma cor mais tranquila.
- **Passe o mouse na barra**, na nota de folga ou na chama para ver a projeção do ritmo na renovação, o único número que ainda não está na linha. Numa barra azul, é a folga com que você deve terminar (`~35% restante na renovação`). Numa amarela, é o uso que completa a nota de folga (`~92% usado na renovação`). Numa vermelha, é quanto a projeção passa do limite (`~12% acima do limite na renovação`, ou `~100% usado na renovação` quando a projeção é terminar exatamente no limite). Quando o saldo acaba, mostra `Limite atingido`.

**Métricas sem limite** (gasto diário, saldos) aparecem numa linha só, como `US$ 4,08 gastos` ou `1,2 mi tokens`. As linhas Hoje, Ontem e Últimos 30 dias juntam custo e tokens (`US$ 4,08 · 1,2 mi tokens`) e podem ser ativadas ou desativadas em Personalizar. Um dia sem uso mostra "Sem dados" em vez de um enganoso `US$ 0,00 · 0 tokens`, como acontece quando a fonte nem pode ser lida. Números grandes aparecem abreviados para as linhas ficarem limpas (`US$ 2,1 mil`, `1,5 bi`). Passe o mouse no valor para ver os números exatos e a nota sobre a fonte, como uma estimativa local.

Nas linhas de gasto do Antigravity, Claude, Codex, Cursor, Grok e OpenCode, o valor ganha um leve destaque quando você passa o mouse sobre ele, sinal de que dá para interagir. Com o mouse parado ali um instante, abre um pequeno detalhamento por modelo naquele período. É uma lista em ordem: cada modelo mostra o nome e o gasto numa linha, a porcentagem e os tokens na linha de baixo, e uma barrinha com a parte dele. O Cursor agrupa os nomes exportados por nível de raciocínio (como `claude-opus-4-8-thinking-max`) sob o modelo base. A cauda longa vai para **Outros**: tudo o que passa dos principais modelos listados ou fica abaixo de 5% do período. Modelos sem preço conhecido em nenhuma fonte não aparecem aqui (nem nos totais da linha); o triângulo de aviso da linha lista esses modelos (veja [Preços dos modelos](pricing.md)).

**Tendência de uso** (Antigravity, Claude, Codex, Cursor, Grok e OpenCode) é um pequeno gráfico de barras com os tokens dos últimos 30 dias, uma barra por dia. Os dados vêm da mesma fonte das linhas de gasto do provedor: os logs locais no Claude, Codex, Grok e OpenCode, as conversas locais no Antigravity e a exportação de uso no Cursor. **Passe o mouse** para ver o dia de pico, o intervalo de datas e a fonte. Vem ativada por padrão; desative ou mude de lugar em Personalizar, como qualquer outra métrica. Ela não pode ganhar estrela para a barra de menus, porque a barra mostra valores únicos, não gráficos.

Com a [Sincronização com o iCloud](icloud-sync.md) ativada, as linhas de gasto, as tendências, os avisos e os detalhamentos por modelo dos provedores cujos dados ficam em cada Mac são refeitos com os dados de todos os Macs sincronizados. O Cursor não muda, porque a exportação dele já vale para a conta inteira. Cotas, planos, saldos e erros dos provedores sempre refletem a atualização feita neste Mac.

Linhas com data de renovação se atualizam a cada 30 segundos, para a contagem regressiva e o ritmo continuarem em dia entre uma atualização e outra.

## Clique com o botão direito

Em qualquer linha: **Ocultar · Adicionar à barra de menus / Remover da barra de menus · Atualizar \<provedor\> · Personalizar…** (Personalizar abre direto nas métricas daquele provedor.)

No cabeçalho de um provedor: **Ocultar \<provedor\> · Atualizar \<provedor\> · Personalizar…** e **Compartilhar captura de tela** (veja abaixo). Ocultar desativa o provedor inteiro; para trazê-lo de volta, ative-o em Personalizar. Personalizar abre direto nas métricas daquele provedor.

## Compartilhar

Copie para a área de transferência um PNG limpo, com a marca do app, do uso de um provedor, pronto para colar numa conversa, num post ou num documento. Há três caminhos:

- Passe o mouse no cabeçalho de um provedor e clique no botão de copiar que aparece à direita.
- Clique com o botão direito no cabeçalho de um provedor e escolha **Compartilhar captura de tela**.
- Abra o menu **Opções** do rodapé e escolha **Compartilhar captura de tela** ▸ *\<provedor\>*. O submenu lista todos os provedores que aparecem no painel naquele momento.

A imagem é um PNG de altura variável, com o visual do app: a marca e o nome do provedor no topo, as linhas de métricas que você vê para ele e uma pequena marca do Meu Uso centralizada embaixo. Ela segue a aparência clara ou escura e mostra tudo o que está no card, do jeito que está (nada fica oculto ou borrado).

## Rodapé

A barra fixa na parte de baixo da janela. À esquerda ficam a versão do app e a contagem "Próxima atualização em …", que você pode clicar (ou apertar **⌘R**) para atualizar na hora. À direita fica o botão do menu **Opções**, que reúne tudo num lugar só: **Personalizar**, **Ajustes**, **Compartilhar captura de tela** (submenu com os provedores), **Buscar atualizações…**, **Relatar um problema…**, **Sobre o Meu Uso** e **Encerrar o Meu Uso**. **Relatar um problema…** abre no navegador a página do GitHub em que você escolhe o tipo de relato. **Buscar atualizações…** fica desativado em builds sem feed de atualização, como os de desenvolvimento (veja [Atualizações](updates.md)).

## Personalizar

Abra Personalizar pelo menu **Opções** do rodapé (ou aperte **Return**). É uma tela em dois níveis: a lista de provedores e, depois, o detalhe de cada provedor.

A **lista de provedores** mostra todos os provedores, cada um com uma chave para ativar ou desativar, a quantidade de métricas e uma seta para o detalhe. Um provedor desativado continua na lista, em cinza: as métricas dele somem do painel e da barra de menus, mas guardam a configuração para quando você ativá-lo de novo. Arraste os provedores ativados pela alça para mudar a ordem; clique numa linha para abrir o detalhe. Numa instalação nova, só os provedores encontrados no seu Mac começam ativados (veja "Primeira abertura", acima). É nesta lista que você adiciona os outros.

O **detalhe** de um provedor tem, na barra de cima, um botão de voltar e o botão de redefinir daquele provedor. Abaixo vêm duas seções de métricas: **Sempre visível** (aparece no card do painel) e **Sob demanda** (fica atrás da seta do card). Cada linha de métrica tem uma alça para arrastar, o nome, uma estrela sempre visível para a barra de menus e uma chave para ativar ou desativar. Arraste uma métrica para a outra seção (ou para cima de uma das linhas dela) para trocar entre Sempre visível e Sob demanda. Uma seção vazia mostra o alvo tracejado **Arraste métricas para cá**. Você pode marcar até duas estrelas por provedor. OpenRouter e Z.ai também mostram aqui a seção **Chave de API**, em que você adiciona, troca, revela ou apaga a chave daquele provedor. O Codex mostra ainda a seção **Estimativas de custo**, com o **Modelo de referência** usado para estimar o custo de modelos sem preço conhecido (veja [Preços dos modelos](pricing.md)).

Arrastar para reordenar também funciona direto no painel: arraste uma linha dentro do provedor, arraste-a por cima da divisão da seta com o card aberto ou arraste o cabeçalho de um provedor para mudar a ordem das seções. Num trackpad Force Touch, você sente um toque leve cada vez que o item arrastado se encaixa numa posição nova.

O layout padrão (o que volta ao redefinir) deixa sempre visíveis os medidores de cota principais e a Tendência de uso de cada provedor, e põe em Sob demanda os saldos, os detalhes de renovação e as linhas de histórico de gasto. Linhas opcionais de detalhe, como Sonnet no Claude e Requisições e Créditos no Cursor, vêm desativadas, mas entram em Sob demanda se você ativá-las.

Fez uma mudança sem querer? Aperte **⌘Z** para desfazer. Funciona em qualquer parte da janela (no painel e em Personalizar) e volta pelas mudanças recentes de personalização, uma de cada vez: ocultar ou mostrar uma métrica, reordenar métricas ou provedores inteiros, marcar ou desmarcar estrelas e mover uma métrica de seção. Cada passo restaura exatamente a arrumação anterior. O desfazer vale só para a sessão (começa do zero quando o app abre de novo), e redefinir apaga o histórico dele.

Quando o Meu Uso traz uma métrica padrão nova, os layouts existentes a recebem uma vez. Se você desativá-la, ela continua desativada. O botão **Redefinir** de um provedor (no canto superior direito do detalhe) restaura as métricas padrão daquele provedor, a ordem, as estrelas da barra de menus e quais métricas começam em Sob demanda, sem mexer nos outros provedores nem na ordem entre eles. O botão **Redefinir toda a personalização** (no canto superior direito da lista de provedores) faz o mesmo para todos os provedores de uma vez, restaura a ordem padrão dos provedores e detecta de novo as ferramentas instaladas. Ele ativa exatamente os provedores das ferramentas configuradas no seu Mac, como na primeira abertura (veja [Quais provedores ficam ativados](provider-enablement.md)). Ele pede confirmação antes, porque apaga o layout inteiro e detecta os provedores de novo, e não dá para desfazer.

## Teclado

| Tecla | Ação |
|---|---|
| Return | No painel, abre Personalizar. No detalhe de um provedor, volta para a lista de provedores. Na lista de provedores ou nos Ajustes, volta para o painel |
| Esc | No detalhe de um provedor, volta para a lista de provedores. Na lista de provedores ou nos Ajustes, volta para o painel. No painel, fecha a janela |
| ⌘Z | Desfaz a última mudança de personalização (vale na janela toda; repita para voltar mais) |
| ⌘R | Atualiza agora, no painel ou nos Ajustes (ignora o cache) |
| ⌘, | Abre ou fecha os Ajustes (dentro da janela) |

Um atalho global (gravado em Ajustes) abre e fecha a janela de qualquer lugar.

## Ao fechar

Fechar a janela zera a navegação: a rolagem volta para o topo, e Personalizar ou Ajustes se fecham. Os cards de provedor lembram se a seta estava aberta.
