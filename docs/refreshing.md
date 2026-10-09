# Atualização e cache

## Quando os dados atualizam

- Todos os provedores ativados atualizam juntos: uma vez quando o app abre e depois a cada 5 minutos (intervalo fixo, sem ajuste para mudar). Abrir a janela não dispara uma segunda rodada automática. Os provedores buscam os dados em paralelo, então os cards rápidos atualizam sem esperar um lento. A rodada em si só termina quando todos os provedores respondem; as notificações, a sincronização do histórico e a próxima espera de cinco minutos começam a partir daí.
- Ativar um provedor (você mesmo, em Personalizar, ou a detecção automática na primeira abertura ou de um provedor novo) busca os dados dele logo, sem esperar o intervalo, mesmo que a mudança aconteça no meio de uma atualização em andamento.
- O rodapé do painel e dos Ajustes mostra `Próxima atualização em Nmin`. **Clicar nele (ou apertar ⌘R com esse rodapé na tela)** atualiza na hora, sem usar o cache.
- O comando `meu-uso`, que roda uma vez e termina, reaproveita esse mesmo cache quando ele tem menos de cinco minutos, atualiza o que estiver faltando ou velho sem abrir o app e encerra. `meu-uso --force` faz a mesma atualização forçada do ⌘R, seja qual for a idade do cache.
- Enquanto um provedor busca dados, aparece um pequeno indicador de carregamento ao lado do nome dele (e o rodapé mostra "Atualizando…"). Assim você sabe que há uma atualização em andamento e não fica na dúvida se os números estão velhos.
- Com a [Sincronização com o iCloud](icloud-sync.md) ativada, cada rodada de atualização grava um arquivo de histórico deste Mac depois que a rodada inteira termina. Atualizações manuais de um provedor gravam depois que aquele provedor termina, e mudanças muito próximas viram uma gravação só.

## Cache

Os últimos dados de cada provedor ficam guardados em disco e carregam na hora quando o app abre. Assim você vê os últimos valores conhecidos logo de cara, em vez de espaços vazios, antes mesmo de a primeira busca terminar.

O cache do Claude e do Codex também lembra qual conta gerou cada valor. Se você trocar a conta conectada na pasta padrão do provedor entre uma abertura e outra, os valores da conta anterior são descartados na abertura seguinte (o card começa vazio e é preenchido na primeira busca). Assim o app não mostra, nem por um instante, os limites e o plano da conta antiga com o login novo.

Um valor em cache só conta como *recente* (a ponto de pular uma atualização) quando foi buscado **durante a sessão atual do app**. Então um valor guardado numa sessão anterior sempre é buscado de novo na primeira rodada depois de abrir o app: você ainda o vê na hora, mas o app nunca espera o intervalo antigo acabar para buscar os números atuais. Isso importa depois de uma atualização do app: a versão nova atualiza os dados na hora, em vez de mostrar os da versão anterior até o intervalo vencer. Dentro de uma sessão, um valor recém-buscado vale como recente por um intervalo de atualização, até a próxima rodada buscá-lo de novo.

O histórico de gasto do Claude, do Codex, do Grok e do pi tem um cache separado, com a leitura dos logs locais, em `~/Library/Application Support/MeuUso/log-scan-cache/`. Ele guarda os eventos de uso já lidos antes de o Meu Uso aplicar as estimativas de preço por modelo, então mudanças de preço passam a valer sem reler arquivos JSONL que não mudaram. Quando o app abre de novo, uma entrada só é reaproveitada se o caminho, o tamanho, a data de modificação e a versão do leitor ainda baterem. Cards que leem a mesma pasta compartilham os dados lidos, e mudar um arquivo de origem regrava só o registro daquele arquivo. Arquivos antigos saem do cache à medida que a janela do histórico avança, e identidades sem uso há 35 dias são removidas. O app deixa as gravações para depois da atualização; o comando `meu-uso` grava o que estiver pendente antes de terminar.

## Quando uma atualização falha

Uma atualização que falha **nunca apaga seus dados**: os últimos valores bons continuam na tela, e um pequeno triângulo de aviso aparece ao lado do nome do provedor. Passe o mouse nele para ver a mensagem de erro (por exemplo, "Nenhum login encontrado. Rode `claude` para entrar."). O erro some na próxima atualização que der certo.

Um provedor que para de responder de vez é deixado de lado depois de dois minutos. O indicador de carregamento para, o triângulo de aviso mostra "Tempo esgotado ao atualizar (120s)" e o provedor é tentado de novo numa rodada seguinte. Assim, um provedor travado não deixa um indicador girando pelo resto da sessão. A espera é longa de propósito: um provedor que funciona bem, numa rede lenta, pode mesmo levar mais de um minuto, e isso deve aparecer como lentidão, não como defeito.

O último histórico normalizado bom também fica guardado. Então uma falha temporária de um provedor (ou uma atualização de limites que dá certo, mas cuja leitura dos logs locais está indisponível no momento) não tira a contribuição anterior deste Mac de um gasto total somado pelo iCloud.

Linhas que nunca tiveram dados mostram "Sem dados", em vez de números inventados.

## Dados desatualizados

Como uma atualização que falha mantém os últimos valores bons na tela, esses valores podem ficar lá se as falhas continuarem. Sem aviso, um plano ou limite que mudou no provedor poderia mostrar os números antigos por tempo indeterminado. Para deixar isso claro, uma pequena etiqueta **Desatualizado** aparece ao lado do nome do provedor quando os dados chegam a uns dez minutos de idade, o equivalente a duas rodadas de atualização. Passe o mouse nela para ver a idade exata ("Atualizado há 3h"). A etiqueta é curta para nunca espremer um nome de plano comprido. Quando ela aparece, os números abaixo são daquele momento, não atuais. Em geral, é porque o provedor está falhando ao atualizar (confira o triângulo de aviso) ou porque o Mac estava em repouso. Uma atualização que dá certo tira a etiqueta.
