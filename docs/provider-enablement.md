# Quais provedores ficam ativados

Como o Meu Uso decide quais provedores começam ativados, o que acontece quando uma atualização traz um provedor novo e a regra que vale para tudo: **as escolhas que você faz sempre valem e nunca são desfeitas pelo app.**

## Primeira instalação

Uma instalação nova não ativa todos os provedores que o Meu Uso conhece. Ela começa com Claude, Codex e Cursor e logo confere quais provedores têm credenciais no seu Mac (um login local, uma chave de API salva ou uma variável de ambiente suportada; nada é enviado para lugar nenhum). Depois passa a usar exatamente esse conjunto. Todos os provedores são conferidos ao mesmo tempo, então a detecção leva o tempo da conferência mais lenta, não a soma de todas. Se nada for encontrado, ficam Claude, Codex e Cursor. Os provedores ativados pela conferência são buscados na hora, então já aparecem com dados, sem esperar a próxima atualização agendada. Veja [Painel § Primeira abertura](dashboard.md#primeira-abertura) para saber como o painel mostra isso.

## Quando uma atualização traz um provedor novo

A mesma detecção roda para provedores que chegam depois. Na primeira abertura depois de uma atualização, o Meu Uso compara os provedores que a versão nova traz com os que esta instalação já viu. Para cada provedor inédito, ele faz a mesma conferência de credenciais, só no seu Mac:

- **Há credenciais no Mac** → o provedor é ativado e aparece no painel.
- **Não há credenciais** → ele continua desativado. Você sempre pode ativá-lo depois, em **Personalizar**.

Essa conferência acontece **uma vez por provedor**. Depois disso, quem decide é você: se você desativar o provedor, nenhuma atualização vai ativá-lo de novo, e instalar a ferramenta mais tarde também não vai ativá-lo sem você saber. Quando quiser, ative em Personalizar.

## Suas escolhas sempre valem

Tudo o que você define em Personalizar (provedores ativados ou desativados, arrumação das métricas, estrelas da barra de menus) continua intacto depois das atualizações. A única coisa que uma atualização pode mudar é **ativar** um provedor que você nunca viu, e só se você tiver mesmo a ferramenta instalada.

A única exceção é de propósito: o botão **Redefinir toda a personalização**, no topo da lista de provedores de Personalizar. Como você pediu para começar do zero, ele roda de novo a mesma detecção local de credenciais da primeira abertura e volta o conjunto ativado para exatamente os provedores com credenciais no seu Mac (Claude, Codex e Cursor, se nada for encontrado). Por isso ele pode desativar um provedor que você tinha ativado, ou ativar um que você tinha desativado. Ele também pede confirmação antes. Veja [Painel](dashboard.md) para o que essa redefinição faz com as métricas.

## Como funciona (para curiosos)

O app guarda duas listas pequenas nos ajustes, e cada provedor sabe conferir as próprias credenciais:

- **Provedores ativados**: os provedores ligados agora. É a fonte que o painel e a barra de menus leem.
- **Provedores conhecidos**: todo provedor que esta instalação já viu. É isso que separa "novo nesta atualização" de "você desativou": um provedor que não está na lista de ativados, mas está na de conhecidos, foi desativado de propósito e fica como está. Só os provedores que faltam nas *duas* listas passam pela conferência de credenciais, e cada um vira conhecido na hora, para a conferência nunca se repetir.
- Cada provedor tem uma conferência de credenciais rápida e só local (`hasLocalCredentials()`). Ela olha os mesmos arquivos, itens das chaves do macOS, chaves salvas e variáveis de ambiente que a atualização normal do provedor lê, e nunca usa a rede.

Instalações mais antigas, de antes de existir a detecção na primeira abertura, começavam com todos os provedores ativados e guardavam só os que estavam *desativados*. Uma migração única dos ajustes converte esses dados para as listas acima, com exatamente os mesmos provedores ativados e desativados de antes. Nada muda na tela na abertura em que a migração acontece; a partir daí, essas instalações entram na mesma detecção de provedores novos.
