# Atualizações

O jeito de atualizar depende de como o Meu Uso foi instalado:

- **Versão do Terminal** (a que existe hoje): instalada por um comando no Terminal e atualizada com `meu-uso update`. Ainda não tem assinatura da Apple.
- **Build de desenvolvimento**: compilado do código ou baixado do CI. Não se atualiza.
- **Versão assinada** (ainda não existe): vai se atualizar sozinha pelo [Sparkle](https://sparkle-project.org), o framework de atualização padrão dos apps de Mac.

A versão aparece no rodapé da janela. Num build de desenvolvimento, ela termina em `-dev`.

## Instalar e atualizar pelo Terminal

```bash
curl -fsSL https://raw.githubusercontent.com/Gabrielbrazz/meu-uso/main/script/install.sh | bash
```

O script:

1. descobre a versão mais recente nas releases do GitHub (versões prévias ficam de fora);
2. baixa o `MeuUso.zip` e o checksum dessa versão;
3. confere o checksum e a assinatura do app antes de mexer em qualquer coisa no seu Mac;
4. fecha o Meu Uso, se estiver aberto;
5. troca o app em Aplicativos (ou em `~/Applications`, se você não tiver permissão na pasta Aplicativos) e, se a troca falhar, volta a versão anterior;
6. cria o comando `meu-uso`, se a pasta `/usr/local/bin` permitir; senão, explica como instalar pelos Ajustes;
7. abre o app.

Para **atualizar**, rode `meu-uso update`. Ele usa a cópia do mesmo script que vem dentro do app, apontando para o app instalado. Se já estiver na versão mais nova, só avisa. `meu-uso update --force` reinstala a versão atual. Rodar de novo o comando `curl` também funciona.

O script aceita algumas opções: `--version v0.2.0` instala uma versão específica (inclusive uma versão prévia, como `v0.2.0-beta.1`), `--force` reinstala mesmo sem versão nova e `--no-open` não abre o app no fim.

### Aviso de versão nova

Quando abre e depois uma vez por dia, o app consulta no GitHub qual é a versão mais recente. Se for mais nova que a instalada, aparece o aviso **Atualização disponível** no topo da janela, com o botão **Copiar comando de atualização**. Cole o comando no Terminal. O botão de fechar (✕) adia o aviso até a próxima consulta.

Nessa versão, o item **Buscar atualizações…** do menu **Opções** fica desativado e a seção **Atualizações** não aparece nos Ajustes. Para conferir na hora, rode `meu-uso update`.

### O que muda sem a assinatura da Apple

- **Só pelo Terminal.** O `.zip` baixado pelo navegador vem com a marca de quarentena do macOS, que bloqueia apps sem assinatura da Apple. Pelo Terminal, o arquivo não ganha essa marca.
- **Sem iCloud.** A sincronização entre Macs precisa de uma permissão assinada pela Apple, então fica indisponível. Veja [Sincronização com o iCloud](icloud-sync.md).
- **Acesso às chaves.** O macOS amarra o "Permitir sempre" das chaves (Keychain) à assinatura de cada versão. Depois de uma atualização, ele pode pedir de novo para o Meu Uso ler os logins dos provedores.

### Publicar uma versão

Uma tag `vX.Y.Z` dispara o workflow `release-terminal.yml`. Ele compila o app para Apple Silicon e Intel, confere o pacote e publica `MeuUso.zip` e `MeuUso.zip.sha256` na release do GitHub, com as instruções de instalação nas notas. Uma tag com sufixo de versão prévia (como `v0.2.0-beta.1`) vira uma pre-release, que o script só instala quando você pede por ela com `--version`.

## Builds de desenvolvimento

Há dois jeitos de ter um build de desenvolvimento:

- **Compilar do código.** Na raiz do repositório, rode `./script/build_and_run.sh` (exige o Xcode 26). O script monta o app em `dist/MeuUso.app` e o abre dali, sem instalar nada em `/Applications`.
- **Baixar o app de desenvolvimento do CI.** Cada execução do CI gera o artefato `MeuUso-dev`, um `.zip` com o app, que fica disponível por 7 dias. Baixe com o GitHub CLI (comando abaixo). Assim o arquivo não ganha a marca de quarentena, e o macOS deixa abrir o app mesmo sem notarização. Baixado pelo navegador, ele vem com essa marca, e o macOS bloqueia a abertura.

```sh
gh run download <run-id> -n MeuUso-dev && ditto -x -k MeuUso-dev.zip .
```

O passo a passo completo está em [Depuração e captura de logs](debugging.md#testar-sem-xcode-local).

Esses builds nunca buscam atualizações: a seção **Atualizações** não aparece nos Ajustes, o item **Buscar atualizações…** do menu **Opções** fica desativado e o `meu-uso update` explica que é um build de desenvolvimento. Para atualizar, compile de novo a partir do código mais recente ou baixe um artefato mais novo do CI.

## Como vai funcionar na versão assinada

Quando houver uma versão assinada e notarizada, o app instalado por ela vai se atualizar assim:

- **Busca automática.** O app procura uma versão nova em segundo plano, a cada hora. Quando encontra, aparece o aviso **Atualização disponível** no topo da janela, em vez de uma janela do Sparkle que abriria escondida atrás dos outros apps. Clique em **Instalar atualização** para abrir na frente a janela da atualização (notas da versão, download e instalação). O botão de fechar (✕) adia o aviso; ele volta na próxima vez que o app encontrar a atualização.
- **Busca manual.** Em **Ajustes → Atualizações**, clique em **Buscar atualizações…** quando quiser (o mesmo item fica no menu **Opções** do rodapé). Tanto na busca manual quanto no aviso, o Meu Uso vem para a frente antes de abrir o Sparkle, para a janela da atualização não ficar escondida atrás de outro app. Como o Meu Uso normalmente fica só na barra de menus, ele mostra um ícone no Dock enquanto a atualização acontece e depois some de lá de novo.
- **Para desligar.** A chave **Buscar automaticamente**, em **Ajustes → Atualizações**, desliga as buscas em segundo plano. A busca manual continua funcionando.

### Acesso antecipado

**Ajustes → Atualizações → Acesso antecipado** inclui as versões prévias (beta) antes de elas chegarem a todo mundo. Desative para voltar a receber só versões estáveis; você fica na versão atual até a próxima versão estável alcançá-la.

Todo mundo recebe as versões estáveis. O acesso antecipado só *acrescenta* as versões prévias.

### De onde vêm as atualizações assinadas

Cada release assinada publica um DMG nas releases do GitHub do Meu Uso, e a lista de versões disponíveis (o "appcast") fica em `https://gabrielbrazz.github.io/meu-uso/appcast.xml`. Esse endereço só passa a existir com a primeira release assinada, que depende da conta de desenvolvedor da Apple e de ligar a variável `SIGNED_RELEASES` no repositório. Uma tag simples (como `v0.1.0`) publica para todo mundo; uma tag com sufixo de versão prévia (como `v0.1.0-beta.1`) publica só no acesso antecipado.

Cada download é assinado de dois jeitos (a notarização da Apple e a assinatura própria do Meu Uso), e o app recusa qualquer arquivo que não confira. Só o build assinado traz o feed (veja `script/build_and_run.sh` e `script/release.sh`).
