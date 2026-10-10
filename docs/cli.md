# Interface de linha de comando

O Meu Uso traz o comando `meu-uso`, de execução única, para agentes e scripts. Ele imprime o JSON documentado de [`/v1/limits`](local-http-api.md#get-v1limits) e sai. Nunca abre o app da barra de menus nem o deixa rodando. A saída traz limites e saldos estáveis, em números, sem linhas da interface, cores, subtítulos, gráficos ou linhas de histórico de gasto.

```sh
meu-uso                 # todos os provedores ativados; atualiza o que estiver com cache vencido
meu-uso codex           # um provedor; atualiza se o cache dele estiver vencido
meu-uso codex --force   # atualiza pelo motor de provedores compartilhado, grava no cache, imprime e sai
```

O comando e o app usam os mesmos provedores, auth stores, preços, coordenador de atualização e cache de snapshots. Uma leitura normal reaproveita snapshots com menos de cinco minutos e atualiza os que faltam ou venceram. O `--force` equivale à atualização manual do app: ignora esse prazo e grava os resultados bem-sucedidos no mesmo cache. As credenciais são usadas só no Mac e nunca aparecem na saída.

O argumento de provedor escolhe provedores por comparação simples de texto, exatamente como a [API HTTP local](local-http-api.md): um ID exato nomeia aquele provedor, e um ID de família (`claude`, `codex`) nomeia todos os cards de conta da família. Com uma conta só, é exatamente aquele card, então scripts feitos para uma conta continuam funcionando quando aparecem outras. O JSON de saída traz todos os provedores encontrados; um ID que não nomeia nada termina com erro. Não há apelidos nem lógica para escolher a conta.

## Ajuda e mensagens

A CLI fala português. As opções, os códigos de saída e as chaves do JSON ficam como estão.

```text
$ meu-uso --help
Uso: meu-uso [provedor] [--force]
     meu-uso update [--force]

Lê os limites pelo cache compartilhado de cinco minutos do Meu Uso e sai. A saída é sempre JSON.

Comandos:
  update       Baixa e instala a versão mais nova do Meu Uso (com --force, reinstala a atual)

Opções:
  --force      Atualiza mesmo quando o cache compartilhado ainda está válido
  -v, --version
  -h, --help
```

`meu-uso --version` mostra a versão do app que contém o comando (por exemplo, `meu-uso 0.1.0`). Fora de um app, mostra `meu-uso (versão de desenvolvimento)`.

Erros e avisos vão para a saída de erro, com o prefixo `meu-uso:`.

```text
$ meu-uso nope
meu-uso: Provedor desconhecido: nope

$ meu-uso --json
meu-uso: Opção desconhecida: --json
Rode 'meu-uso --help' para ver como usar.

$ meu-uso claude codex
meu-uso: Só é possível pedir um provedor por vez.
Rode 'meu-uso --help' para ver como usar.
```

Quando a atualização de um provedor falha, o JSON sai normalmente na saída padrão, com a falha em `errors`. A mesma mensagem aparece como aviso na saída de erro, e o comando termina com o código `4`:

```text
meu-uso: aviso: codex: Nenhum login encontrado. Rode `codex` para entrar.
```

Os códigos de saída são `0` para sucesso, `2` para argumento inválido ou provedor desconhecido e `4` quando uma atualização ou leitura local falha.

## Atualizar o Meu Uso

`meu-uso update` instala a versão mais nova do Meu Uso por cima do app que contém o comando. Ele roda o mesmo script da instalação (`script/install.sh`, que vem dentro do app): descobre a versão mais recente no GitHub, baixa, confere o checksum, fecha o app, troca e abre de novo. Se a versão instalada já for a mais nova, só avisa e sai. `meu-uso update --force` reinstala a versão atual.

```text
$ meu-uso update
Baixando o Meu Uso 0.2.0…
Fechando o Meu Uso…
Meu Uso 0.2.0 instalado em /Applications/MeuUso.app.
```

O comando só atualiza a versão instalada pelo Terminal. Num build de desenvolvimento ele explica como atualizar e termina com o código `3`; o mesmo vale para uma futura versão assinada, que se atualiza pelo próprio app. Quando o script falha (sem internet, checksum que não confere, pasta sem permissão), a versão anterior continua instalada e o comando termina com o código `1`. Veja [Atualizações](updates.md).

## Instalar no `PATH`

No Meu Uso, abra **Ajustes → Linha de comando** e clique em **Instalar…**, na linha **Utilitário de terminal**. Depois do pedido de senha de administrador padrão do macOS, o `meu-uso` fica disponível em qualquer sessão nova do Terminal. O link fica em `/usr/local/bin/meu-uso` e aponta para o utilitário que vem dentro do Meu Uso, então as atualizações do app também atualizam o comando. Para remover, clique em **Desinstalar** no mesmo lugar.

Se já existir em `/usr/local/bin/meu-uso` um arquivo que o Meu Uso não instalou, a linha mostra **Indisponível** e o aviso "/usr/local/bin/meu-uso já existe e não foi instalado pelo Meu Uso."
