# Ajustes

Os Ajustes ficam dentro da janela do Meu Uso; não existe uma janela separada. Abra pelo menu **Opções** do rodapé, pelo atalho **⌘,** (com a janela aberta) ou clicando com o botão direito no ícone da barra de menus e escolhendo **Ajustes**. O painel desliza para a tela de Ajustes, que tem um botão de voltar no canto superior esquerdo. Volte por esse botão, pelo atalho **⌘,** ou com Esc (o Esc sempre volta primeiro para o painel; apertar de novo fecha a janela).

## Geral

| Ajuste | Opções | O que faz |
|---|---|---|
| Mostrar gasto total | Ativado / Desativado | Mostra ou não, no topo do painel, o card de [Gasto total](dashboard.md#gasto-total), que soma os provedores. Vem ativado. O card aparece sempre que pelo menos um provedor ativado acompanha gasto (Antigravity, Claude, Codex, Cursor, Grok, OpenCode). |
| Abrir ao iniciar sessão | Ativado / Desativado | Registra o app como item de início do macOS (vale o que está registrado no sistema). Se o macOS recusar a mudança, aparece um aviso para conferir em Ajustes do Sistema → Itens de Início. |
| Atalho global | gravar um atalho | Atalho que abre e fecha a janela de qualquer lugar. Clique no campo (**Gravar atalho**) e aperte a combinação; o ⓧ (**Limpar atalho**) apaga a combinação e desativa o atalho. |

## Sincronização com o iCloud

**Sincronizar entre Macs** vem desativado. Ao ativar, o Meu Uso compartilha o histórico de uso normalizado pelo container privado do app no iCloud e soma os tokens e gastos que ficam em cada Mac, entre os Macs com a mesma conta do iCloud. A seção lista cada Mac e quando ele atualizou o histórico pela última vez (por exemplo, "Atualizado há 5min"), com a etiqueta **Este Mac** no Mac que você está usando. Ela também avisa quando o iCloud está indisponível, quando ainda está esperando a primeira gravação, quando uma gravação falha e quando algum arquivo está com defeito. A sincronização só funciona num build assinado com o perfil do iCloud, e nenhum build atual tem esse perfil. Veja [Sincronização com o iCloud](icloud-sync.md) para saber o que entra, quais telas usam os valores somados e quando a opção fica indisponível.

## Aparência

| Ajuste | Opções | O que faz |
|---|---|---|
| Estilo do ícone | Texto / Barras | Como as métricas com estrela aparecem na barra de menus. Veja [Barra de menus](menu-bar.md). |
| Tema | Sistema / Claro / Escuro | Escolhe a aparência da janela do app ou segue a do sistema. |
| Densidade | Padrão / Compacta | Padrão é mais arejada. Compacta é um modo realmente denso: o texto desce um tamanho, as linhas e as seções de provedor ficam mais juntas, e as linhas de Personalizar e dos Ajustes apertam junto. Nas duas, métricas de uma linha em sequência (Hoje, Ontem, …) ficam mais próximas; na Compacta, ainda mais. |
| Reduzir animações | Desativado / Ativado | Vem desativado. Ativado, tira as transições, os efeitos de movimento e as animações decorativas contínuas da janela. O app também respeita o ajuste de acessibilidade **Reduzir movimento** do macOS. |
| Formato de hora | Automático / 12 horas / 24 horas | Como aparecem os horários exatos (por exemplo, "Renova hoje às 18:38" ou "Renova hoje às 6:38 PM"). Automático segue o ajuste de 12 ou 24 horas do Mac. |
| Aumentar transparência | Desativado / Ativado | Desativado (padrão), a janela fica sólida. Ativado, ela fica translúcida e deixa ver a mesa por trás, com superfícies que se adaptam para manter os números e o botão Opções legíveis. Fica em pausa sozinho quando **Reduzir transparência** ou **Aumentar contraste** estão ativados nos ajustes de acessibilidade do macOS (um aviso explica o motivo), para nunca contrariar essas preferências. |

## Exibição do uso

| Ajuste | Opções | O que faz |
|---|---|---|
| Mostrar uso como | Usado / Restante | Se as métricas com limite mostram "48% usado" ou "52% restante" (o padrão é Restante). É a mesma troca de clicar no título de uma linha. |
| Prazos de renovação | Contagem regressiva / Horário exato | "Renova em 3h 25min" ou "Renova hoje às 18:38" (o padrão é Contagem regressiva). É a mesma troca de clicar num texto de renovação. |
| Sempre mostrar o ritmo | Desativado / Ativado | Desativado (padrão), o ritmo só aparece quando uma métrica está perto do limite ou a caminho de passar dele. Ativado, aparece em toda métrica com período de renovação: as linhas no rumo certo ganham a projeção ("~33% restante na renovação") e uma marca de ritmo constante, que mostra onde o uso estaria agora num consumo regular. Métricas sem período de renovação não têm ritmo para mostrar, e uma métrica ainda sem uso fica sem esses extras até algo ser gasto. |

## Notificações

O Meu Uso pode avisar você com uma notificação do macOS quando uma métrica estiver acabando ou o ritmo piorar. Assim você não precisa deixar a janela aberta para ver uma cota chegando perto do limite. Os alertas funcionam enquanto o app roda na barra de menus, mesmo com a janela fechada.

| Ajuste | Opções | O que faz |
|---|---|---|
| Quase esgotado | Ativado / Desativado | Avisa quando uma métrica passa a ter menos de 10% restante, inclusive saldos sem período de renovação. |
| Margem apertada | Ativado / Desativado | Avisa quando, no ritmo atual, uma métrica vai terminar o período com pouca folga, perto do limite. |
| Vai esgotar | Ativado / Desativado | Avisa quando, no ritmo atual, uma métrica vai esgotar antes de renovar. |

Os alertas disparam quando um limite é cruzado ou o ritmo piora e não se repetem enquanto a situação continuar igual, então você não recebe o mesmo aviso a cada atualização. Uma cota que já está ruim quando o Meu Uso abre vira o ponto de partida, sem alerta. Se ela melhorar e depois piorar de novo, o alerta volta a valer; um novo período de renovação também zera o histórico ligado à renovação. **Quase esgotado** olha só a parte restante, então também funciona para saldos com limite e sem período de renovação. **Margem apertada** e **Vai esgotar** precisam do ritmo dentro de um período de renovação. Métricas cujos dados não podem ser lidos nunca geram alerta. Desative os três para silenciar tudo. Quando vários alertas disparam juntos, eles se agrupam numa notificação só.

Os três alertas vêm desativados. Na primeira vez que você ativa um deles, o Meu Uso pede permissão para enviar notificações. Se você recusar (ou desativar depois as notificações do Meu Uso nos Ajustes do Sistema), aparece um sinal de aviso no título Notificações e o botão **Abrir Ajustes do Sistema** embaixo das chaves, para você reativá-las. Se você ainda não respondeu ao pedido, o botão é **Permitir notificações**. O título da notificação é o nome do alerta, o subtítulo traz o provedor e a métrica (por exemplo, "Claude · Sessão") e o texto explica a situação em linguagem simples. Clicar num alerta abre a janela no painel.

## Privacidade

| Ajuste | Opções | O que faz |
|---|---|---|
| Ocultar ao compartilhar a tela | Ativado / Desativado | Desativado (padrão). Ativado, troca os números da barra de menus pelo ícone e pelo nome do Meu Uso enquanto sua tela é compartilhada ou gravada, e devolve as métricas com estrela assim que a captura termina. Veja [Barra de menus](menu-bar.md#ocultar-o-uso-ao-compartilhar-a-tela). |

O Meu Uso não tem telemetria, então não há ajuste para isso. Veja [Privacidade](privacy.md) para saber com quem o app fala pela rede e o que ele guarda no seu Mac.

## Linha de comando

| Ajuste | Opções | O que faz |
|---|---|---|
| Utilitário de terminal | botão (**Instalar…** / **Desinstalar**) | Instala o comando global `meu-uso`, que agentes e scripts podem usar para acompanhar limites. Pede a senha de administrador do macOS e cria em `/usr/local/bin/meu-uso` um link para o utilitário que vem dentro do app. Mostra **Indisponível** quando já existe um `/usr/local/bin/meu-uso` que não foi instalado pelo Meu Uso. |

Veja [Interface de linha de comando](cli.md) para saber como usar o comando.

## Avançado

| Ajuste | Opções | O que faz |
|---|---|---|
| Nível de log | Erro / Aviso / Informação / Depuração | Quanto detalhe o app grava no arquivo de log. O padrão é Informação, e a escolha fica salva para as próximas aberturas. Suba para Depuração enquanto reproduz um problema. A mudança vale na hora. |
| Copiar caminho do log | botão | Copia para a área de transferência o caminho do arquivo de log (`~/Library/Logs/MeuUso/MeuUso.log`). |
| Mostrar no Finder | botão | Abre uma janela do Finder com o arquivo de log selecionado. |
| Redefinir todos os ajustes… | botão | Volta todos os ajustes ao padrão, depois de um alerta de confirmação. |

Veja [Logs](logging.md) para o comportamento completo: as etiquetas por subsistema, o limite de tamanho do arquivo e a garantia de que segredos nunca são gravados.

**Redefinir todos os ajustes…** volta ao padrão todos os ajustes desta tela: aparência, exibição do uso, notificações, privacidade, nível de log, o atalho global (apagado), Abrir ao iniciar sessão (desativado), a sincronização com o iCloud (desativada) e as preferências de atualização (canal estável e busca automática ativada). Também redefine toda a personalização, igual a **Redefinir toda a personalização** em Personalizar: o layout, a ordem e as estrelas da barra de menus voltam ao padrão, e os provedores são ativados de novo conforme as ferramentas que você tem instaladas. Não dá para desfazer.

Ficam como estão: os logins dos provedores, as chaves de API e os dados de uso em cache. Desativar a sincronização com o iCloud como parte da redefinição funciona igual a desligar a chave dela: o histórico sincronizado deste Mac sai dos dados compartilhados no iCloud, e seus outros Macs ficam com o histórico deles.

## Atualizações

A seção Atualizações só aparece em builds de release, que trazem o feed de atualização assinado. Ainda não existe nenhum: os builds de desenvolvimento (feitos no seu Mac ou pelo CI) não mostram essa seção.

| Ajuste | Opções | O que faz |
|---|---|---|
| Buscar automaticamente | Ativado / Desativado | Se o Sparkle busca atualizações em segundo plano, a cada hora. Vem ativado. Mesmo desativado, você pode buscar manualmente. |
| Acesso antecipado | Ativado / Desativado | Inclui versões prévias (beta) entre as atualizações que você pode receber. As versões estáveis continuam chegando de qualquer jeito. |
| Buscar atualizações… | botão | Faz uma busca manual e abre a janela de atualização do Sparkle. |

Veja [Atualizações](updates.md) para o aviso no painel, os canais e a verificação de assinatura.

## Versão

A versão do app aparece no rodapé da janela.

Seus ajustes continuam depois das atualizações: layout, estrelas, preferências e o atalho global ficam como estão. Quando uma atualização muda o jeito de guardar um ajuste, o app converte o ajuste ao abrir, passando por todas as versões intermediárias se você pulou algumas. Nada é redefinido.

Os provedores que você ativou também continuam depois das atualizações; suas escolhas nunca são substituídas. Uma instalação nova escolhe o conjunto inicial detectando as ferramentas de IA do seu Mac (veja [Painel § Primeira abertura](dashboard.md#primeira-abertura)). Quando uma atualização traz um provedor que você nunca viu, a mesma detecção local roda uma vez, só para ele, e ele só é ativado se você tiver mesmo a ferramenta. Tudo o que você já decidiu fica exatamente como você deixou. Veja [Quais provedores ficam ativados](provider-enablement.md).
