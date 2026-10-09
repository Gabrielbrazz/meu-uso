# Claude

Acompanha os limites da sua assinatura do Claude usando o login que você já tem no Claude Code ou no Claude Desktop.

Cada conta e organização ganha um card próprio do Claude, com limites e gastos separados. Entrar na mesma conta e organização pelo Claude Code e pelo Claude Desktop continua gerando um card só.

## O que mostra

| Métrica | O que significa |
|---|---|
| Sessão | Uso na janela móvel de 5 horas |
| Semanal | Uso na janela de 7 dias |
| Fable | Limite semanal separado do Fable (janela por modelo, vinda da lista `limits`) |
| Sonnet | Limite semanal separado do Sonnet (depende do plano) |
| Uso extra | Créditos de uso extra gastos dentro do seu teto mensal |
| Renovações de limite | Renovações avulsas do limite de uso que a Anthropic concede (por exemplo, uma renovação no lançamento de um modelo, para Pro e Max), mostradas como contagem (ex.: `1 disponível`). Passe o mouse sobre o valor para ver uma linha do tempo com o prazo de cada uma |
| Tendência de uso | Gráfico diário de tokens dos últimos 30 dias, da mesma fonte das linhas de gasto |
| Hoje / Ontem / Últimos 30 dias | Gasto local, em custo, tokens ou ambos (veja abaixo) |

Por padrão, o Fable vem ativado e sempre visível, logo abaixo de Semanal. O Sonnet fica desligado até você ativá-lo em Personalizar. A linha Renovações de limite vem ativada, mas fica escondida atrás da seta do card. Quando o Claude informa o nome do seu plano, o Meu Uso mostra o plano ao lado do nome do provedor. O plano vem do perfil da conta na Anthropic, em tempo real. Assim, um upgrade (de Max 5x para Max 20x, por exemplo) aparece na próxima atualização, sem precisar entrar de novo no Claude Code. Se o perfil não puder ser lido, volta a aparecer o plano salvo com o seu login.

## Renovações de limite

De vez em quando, a Anthropic concede renovações gratuitas do limite de uso. Por exemplo, uma renovação para assinantes Pro e Max quando sai um modelo novo. Usar uma renovação zera na hora o uso dos seus limites de sessão e semanal.

A linha Renovações de limite conta quantas renovações você ainda tem, com um ponto colorido para o prazo mais próximo: azul se o prazo passa de 7 dias, amarelo se é de até 7 dias e vermelho se é de até 48 horas. Ao passar o mouse sobre o valor, abre a mesma linha do tempo que o Codex usa. Uma renovação concedida sem prazo também conta, mas não tem data para mostrar. Contas fora do programa mostram `0 disponíveis`. Se a Anthropic nem informar o programa para o seu plano, a linha mostra **Sem dados**.

Por enquanto, o Meu Uso só mostra as suas renovações. Para usar uma, rode `/rate-limit-options` no Claude Code ou aceite quando o Claude Code oferecer, ao chegar num limite de uso.

## De onde vêm as credenciais

Entre pelo Claude Code ou pelo Claude Desktop, e o Meu Uso lê o login que já existe. Ele confere estas fontes e prefere uma que consiga ler o uso da sua assinatura:

1. O item que o Claude Code mantém nas chaves do macOS (Keychain), que é a fonte oficial dele no macOS
2. `~/.claude/.credentials.json` (ou `$CLAUDE_CONFIG_DIR/.credentials.json`)
3. O cache criptografado de login do Claude Desktop
4. A variável de ambiente `CLAUDE_CODE_OAUTH_TOKEN`

Quando há várias contas, um login do Claude Desktop da organização do card tem prioridade, se for preciso. O Meu Uso confere se cada credencial pertence à conta e à organização certas.

O suporte ao Claude Desktop é só de leitura. O Meu Uso descriptografa o token de acesso válido no momento usando o item `Claude Safe Storage` das chaves do macOS. Ele nunca lê nem usa o token de renovação do Desktop, e nunca altera a configuração, os cookies ou o item das chaves do Desktop. Assim, o Meu Uso não invalida a sessão do Claude Desktop.

Funcionam tanto os caches de login antigos do Desktop quanto os novos, específicos por conta. Um token específico de conta precisa corresponder à conta conectada no Desktop e à organização do card. Uma entrada de cache mais nova, ou uma marca de exclusão, vale mais que uma cópia antiga do mesmo login.

O macOS pede permissão uma vez antes de o Meu Uso acessar esse item das chaves. As atualizações em segundo plano nunca abrem o pedido de senha: primeiro o Meu Uso pede que você atualize manualmente, e escolher **Sempre Permitir** deixa as próximas atualizações silenciosas. Se o token de curta duração do Desktop expirar, abra o Claude Desktop para ele renovar o login e atualize o Meu Uso.

Um `CLAUDE_CODE_OAUTH_TOKEN`, que costuma ser um `claude setup-token` de longa duração, consegue rodar o modelo, mas não lê os seus limites de Sessão e Semanal. E ele muitas vezes fica esquecido no ambiente do shell. Por isso, quando existe um login de verdade nas chaves do macOS ou em arquivo, o Meu Uso usa esse login nos medidores em tempo real e guarda o token do ambiente só como reserva. Os medidores de Sessão e Semanal não ficam mais em branco só porque esse token está definido. Se o token do ambiente for a sua *única* credencial (numa configuração sem interface gráfica), ele é usado sozinho, e as linhas de gasto continuam carregando pelos logs locais.

Se uma fonte tiver um token expirado ou "bloqueado", o Meu Uso recorre às outras. Então, entrar de novo com `claude` fora do app é percebido na próxima atualização, sem reiniciar o Meu Uso. Os tokens do Claude Code são renovados automaticamente. Um token trocado só é gravado de volta se a lista ordenada de logins ainda for a mesma do início da atualização. Assim, um login de prioridade maior que acabou de aparecer prevalece. O Meu Uso nunca renova nem grava tokens do Claude Desktop.

Ao salvar um token renovado do Claude Code, o Meu Uso atualiza só o token de acesso, o token de renovação e a validade no documento de credenciais mais recente. Logins de MCP e outros campos do Claude Code são preservados, inclusive mudanças feitas enquanto o Meu Uso atualizava.

## Contas do Claude Swap

Ao abrir, o Meu Uso encontra as contas salvas no `~/.claude-swap-backup/sequence.json` do Claude Swap. Cada conta ganha um card com o nome da organização seguido do e-mail. Um login que já aparece pelo Claude Code ou pelo Desktop divide o mesmo card quando a conta e a organização são as mesmas. Reinicie o Meu Uso depois de adicionar ou remover uma conta salva.

Se o login padrão identificar uma conta, mas não tiver ID de organização, ele continua disponível como um card padrão separado, ao lado das contas salvas do Swap. O Meu Uso não tenta adivinhar a qual organização salva ele pertence. Enquanto houver várias contas conhecidas, o gasto desse card cobre só as sessões de terminal que não registram conta (veja abaixo), até o login identificar a organização.

As contas salvas usam o login padrão ativo quando ele é exatamente daquela conta. Depois, usam o item das chaves do macOS e o arquivo de credenciais do perfil de sessão no próprio Claude Swap. Elas nunca recorrem ao login padrão do Claude de outra conta nem a um token de ambiente. O cofre salvo do Swap é a última opção, só de leitura. O Meu Uso não troca os tokens do cofre nem altera a lista de contas do Claude Swap. Se um login do cofre estiver expirado, abra essa conta com `cswap run <email>` e atualize o Meu Uso.

Credenciais do Desktop que correspondem continuam disponíveis no card unido, inclusive quando o Swap foi a fonte original. Se um login preferido expirar ou for recusado, o card tenta as outras fontes correspondentes. Toda credencial em uso precisa identificar a mesma conta e organização antes de fornecer limites. Logins que conseguem ler o uso em tempo real são tentados antes dos logins com permissões limitadas. Assim, um login padrão sem `user:profile` não esconde os limites de Sessão e Semanal que uma sessão salva correspondente consegue ler. As credenciais do perfil de sessão podem ser renovadas normalmente, e as atualizações são salvas de volta nesse mesmo perfil.

O gasto local inclui os históricos de sessão do Claude Swap, além do histórico padrão do Claude. O histórico compartilhado é deduplicado e filtrado pela conta e pela organização registradas. Entradas sem dono nos históricos de sessão do Swap ficam de fora quando há várias contas conhecidas. A atribuição mais ampla do histórico de SDK e do Conductor ainda não é feita.

## As linhas de gasto

Hoje, Ontem e Últimos 30 dias são calculados **localmente**: o Meu Uso lê sozinho os logs de sessão do Claude Code em `~/.claude/projects/` e `~/.config/claude/projects/` (ou em `$CLAUDE_CONFIG_DIR`), sem ferramentas externas. Links simbólicos são seguidos, então uma pasta de projetos ligada a um local sincronizado (uma pasta do Dropbox, por exemplo) é lida do mesmo jeito.

Outras fontes também contam:

- **pi:** com uma única conta conhecida, o uso do Claude feito pelo agente de programação [pi](https://github.com/earendil-works/pi) também entra. O Meu Uso lê os logs de sessão do pi em `~/.pi/agent/sessions/` (ou em `$PI_CODING_AGENT_SESSION_DIR`) e soma o uso do Claude encontrado ali às mesmas linhas e à tendência. Assim, uma assinatura do Claude usada pelo pi também aparece aqui. O pi registra o próprio custo por mensagem, então esses dólares vêm direto do pi, sem nova estimativa.
- **Cowork** (o modo agente do app Claude Desktop): ele grava os mesmos logs em pastas por sessão dentro de `~/Library/Application Support/Claude/local-agent-mode-sessions/`, e o Meu Uso lê essas pastas também. Assim, as sessões de agente do app aparecem nas linhas junto com as do terminal.
- **`claude -p`:** execuções persistidas contam. Execuções com `--no-session-persistence` não aparecem, porque nesse caso o Claude não grava nenhum log de sessão, de propósito.

O uso do advisor registrado dentro de uma mensagem conta uma vez, no modelo do próprio advisor. Os totais do modelo principal ficam separados, e os detalhes comuns de iteração não são contados de novo. A velocidade registrada no log (rápida ou padrão) define o preço; o Meu Uso não deduz a velocidade pela data do evento.

Os dias seguem o fuso horário local do seu Mac, então batem com o seu calendário. Cada período é uma linha que mostra custo e tokens juntos (`US$ 4,08 · 1,2 mi tokens`). Um dia sem uso mostra **Sem dados**, e não um enganoso `US$ 0,00 · 0 tokens`, como em todos os outros provedores com gasto. Os medidores de Sessão e Semanal em tempo real não são afetados. Os dólares são estimados a partir da contagem de tokens, com preços de API, usando os [preços dos modelos](../pricing.md) compartilhados (ao passar o mouse sobre o valor, o app avisa que é uma estimativa). Já a contagem de tokens é medida. Nenhum dado dos logs sai do seu Mac.

Sessões que não identificam a conta, incluindo o uso do pi e de ferramentas de terceiros como o Conductor, contam enquanto o Meu Uso nunca tiver visto mais de uma conta do Claude. Depois que várias contas aparecem, a maior parte do uso sem atribuição fica de fora, em vez de ir para o card errado.

A exceção são as sessões comuns de terminal. O Claude Code só registra a conta em sessões rodadas pelo Claude Desktop ou pelo Remote Control, então as sessões normais de `claude` na pasta padrão do Claude (`~/.claude` ou `$CLAUDE_CONFIG_DIR`) não registram nenhuma. Elas contam no card da conta em que o Claude Code está conectado no momento, conferida de novo a cada atualização. Sessões que o Claude Desktop lista como suas ficam com os cards do Desktop. Se você trocou o Claude Code para outra conta nos últimos 30 dias, as sessões de antes da troca também contam no card da conta atual.

Logs de subagentes herdam o dono da sessão pai, mesmo quando essa sessão é mais antiga que a janela de gasto. Sessões com registros conflitantes de conta ou de organização ficam de fora. O Meu Uso confere cada sessão pai uma vez por atualização e, entre atualizações, reaproveita os resultados que não mudaram, inclusive os conflitos. Leituras que falham são tentadas de novo na próxima atualização, e varreduras grandes de dono param quando a atualização é cancelada.

Subagentes do Claude, incluindo agentes dentro de workflows, herdam a conta da sessão pai. O uso deles aparece enquanto rodam e entra nas mesmas linhas de gasto. Logs de workflows que já existem são lidos na próxima atualização. Não é preciso rodar o workflow de novo nem limpar o cache de uso.

O gasto local não exige um login OAuth do Claude. Se o Claude Code usa um gateway com chave de API, as linhas de gasto e a tendência de uso continuam carregando pelos logs de sessão. O cabeçalho do Claude mostra **Nenhum login encontrado** porque os medidores de Sessão e Semanal em tempo real ainda exigem um login de assinatura do Claude.

## Solução de problemas

- **"Nenhum login encontrado"**: rode `claude` e entre para ativar os limites da assinatura em tempo real; depois, atualize. Se você usa um gateway com chave de API, o gasto local continua aparecendo sempre que o Claude Code tiver gravado logs de sessão.
- **"Login do Claude Desktop encontrado"**: atualize manualmente e escolha **Sempre Permitir** quando o macOS pedir acesso a `Claude Safe Storage`.
- **"Sessão do Claude Desktop expirada"**: abra o Claude Desktop para ele renovar o login e atualize o Meu Uso.
- **"Entre de novo para ver o uso em tempo real"** (aviso âmbar no cabeçalho do Claude): o login salvo consegue autenticar para inferência, mas não lê os limites da assinatura, porque não tem o acesso `user:profile`. É o caso de um token só de inferência, gerado por `claude setup-token`. Rode `claude`, entre de novo com a sua conta do Claude e atualize. As linhas de gasto continuam funcionando enquanto isso.
- **"Atualizações bloqueadas pela Anthropic"** (aviso âmbar no cabeçalho do Claude): a API de uso está limitando o Meu Uso. Ele mantém os últimos valores do mesmo login, inclusive, logo depois de reabrir o app, os limites guardados em cache para a mesma conta verificada (janelas que já renovaram são descartadas). Ele também mostra quando vai tentar de novo e não insiste antes disso. Um login diferente começa do zero, com cache e tempo de espera próprios.
- **As linhas de gasto mostram "Sem dados"**: o Meu Uso não achou logs do Claude Code nos últimos 30 dias. Se os seus logs ficam num lugar diferente, defina `CLAUDE_CONFIG_DIR` para o Claude Code e o Meu Uso olharem no mesmo lugar.

## Por dentro

`GET https://api.anthropic.com/api/oauth/usage?cedar_ember=1` com o token OAuth escolhido. A flag `cedar_ember=1` pede as renovações concedidas (`cedar_ember` é o nome interno do programa na Anthropic), do mesmo jeito que o Claude Code faz. Os tokens do Claude Code são renovados por `platform.claude.com/v1/oauth/token`. Os tokens do Claude Desktop são só de leitura e precisam ser renovados pelo próprio Desktop. Se um token estiver expirado ou revogado, o Meu Uso tenta a próxima fonte de credencial antes de mostrar um erro.

O plano ao lado do nome vem de `GET https://api.anthropic.com/api/oauth/profile` (o `rate_limit_tier` da organização), porque o plano que o Claude Code salva ao entrar nunca é atualizado depois. Para não esbarrar nos limites da Anthropic, essa consulta roda no máximo uma vez por token de acesso, só depois de uma busca de uso dar certo. Cards ligados a uma conta específica reaproveitam o perfil que já buscaram para verificar a identidade, então não fazem nenhum pedido a mais. Tokens só de inferência pulam essa consulta.

Quando a janela de sessão de cinco horas ainda não começou (a API de uso não informa horário de renovação), a linha Sessão mostra **Não iniciada** no lugar da contagem. Ao passar o mouse, uma dica explica que a sessão começa quando você envia a primeira mensagem. Se a API informa um horário de renovação, a janela está correndo, e a linha sempre mostra a contagem. Isso vale mesmo quando os números inteiros da Anthropic ainda mostram 0% porque menos de 1% foi usado, igual ao que o próprio Claude Code mostra.
