# Logs

O Meu Uso mantém um arquivo de log para você registrar o que o app estava fazendo e mandar ao suporte quando algo der errado. As linhas no nível escolhido ou acima também vão para o log unificado do macOS, então subir o nível para **Depuração** mostra o detalhe extra nos dois lugares (veja [Depuração](debugging.md) para o `log stream`).

O texto do log fica em inglês, como no projeto original, para facilitar a busca e a comparação. A exceção são as mensagens de erro que entram numa linha, como a que aparece no card de um provedor: elas ficam como o app mostra, em português.

## Onde fica o arquivo de log

```
~/Library/Logs/MeuUso/MeuUso.log
```

O jeito mais fácil de pegar o arquivo: abra **Ajustes → Avançado** e use **Copiar caminho do log** (copia o caminho para a área de transferência) ou **Mostrar no Finder** (seleciona o arquivo numa janela do Finder). Não precisa do Terminal.

## Como mudar o nível de log (Ajustes → Avançado)

O seletor **Nível de log** controla quanto detalhe é gravado. A escolha continua valendo nas próximas aberturas e tem efeito na hora, sem reiniciar.

| Nível | O que registra |
|---|---|
| Erro | Só falhas. |
| Aviso | Falhas e coisas que parecem erradas, mas se recuperaram. |
| Informação | O dia a dia: início e fim de cada atualização, resultado por provedor, marcos de cache e de autenticação. |
| Depuração | Tudo, inclusive o detalhe de cada requisição e de cada consulta ao cache. |

O padrão é **Informação**: discreto, mas útil. **Depuração** é opcional. Ligue só enquanto reproduz um problema, porque ele gera muito mais linhas.

Se um log de uso local existe mas não pode ser lido, o Meu Uso grava um aviso e pula o arquivo naquela atualização. O aviso não se repete a cada cinco minutos: só volta se o arquivo voltar a ser lido e, depois, ficar ilegível de novo.

Toda atualização de provedor que leva 10 segundos ou mais grava uma linha `[WARN] [refresh]` com o ID do provedor, o tempo gasto em milissegundos e o limite, por exemplo `cursor slow refresh (12034ms, threshold=10000ms)`. Ela aparece no nível padrão (Informação), então dá para achar uma leitura lenta de log local ou uma chamada de rede lenta num log comum de suporte, sem reproduzir o problema com Depuração ligada. O aviso serve só para diagnóstico: os cards dos outros provedores continuam atualizando por conta própria, e o provedor lento pode terminar.

## Tags de subsistema

Cada linha traz a data (ISO 8601), o nível e uma tag entre colchetes, para facilitar o `grep`:

```
2026-10-08T14:03:12.481Z [INFO] [refresh] codex ok (842ms)
```

As tags são `[refresh]` `[cache]` `[http]` `[auth]` `[keychain]` `[menubar]` `[statusitem]` `[updates]` `[config]` `[pricing]` `[notifications]` `[lifecycle]` `[subprocess]` `[localapi]`, além das tags por provedor, como `[plugin:claude]` e `[auth:claude]`.

Por exemplo, para acompanhar só o ciclo de atualização:

```sh
grep '\[refresh\]' ~/Library/Logs/MeuUso/MeuUso.log
```

## O que nunca vai para o log

Segredos nunca chegam ao log. Tokens de acesso e de renovação, cookies, tokens de sessão e chaves de API são mascarados antes de qualquer linha ser gravada: um valor sensível vira `first4...last4`, ou `[REDACTED]` quando é curto demais para mascarar com segurança. Caminhos de arquivo, como os da sua pasta pessoal, viram `[PATH]`.

Corpos de resposta nunca vão inteiros para o log. Num erro HTTP, o app pode gravar no nível Depuração uma prévia cortada (até 500 bytes) para ajudar no diagnóstico, que passa antes pelo mesmo mascaramento. As regras de mascaramento são as mesmas do app original, e uma bateria de testes garante que continuem assim.

## Limite de tamanho

O log tem um limite de cerca de 10 MB. Quando enche, o arquivo atual vira `MeuUso.1.log` e um `MeuUso.log` novo começa. Assim, uma sessão longa nunca enche o disco (são no máximo uns 20 MB, somando o arquivo atual e o anterior). Um arquivo grande demais que sobrou de uma sessão anterior é rotacionado uma vez na abertura.

> Observação: o build de desenvolvimento e o build de release gravam no mesmo `MeuUso.log`. Rodar os dois ao mesmo tempo mistura as linhas. Não atrapalha o uso normal, mas vale saber se você depura os dois juntos.
