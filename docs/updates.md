# Atualizações

O Meu Uso usa o [Sparkle](https://sparkle-project.org), o framework de atualização padrão dos apps de Mac, para se manter atualizado. Mas isso só funciona em builds de release, e **ainda não existe nenhuma**: o projeto não tem versão assinada nem notarizada.

## Como instalar e atualizar hoje

Por enquanto, há dois jeitos de ter o app (ele roda no macOS 15 ou mais novo):

- **Compilar do código.** Na raiz do repositório, rode `./script/build_and_run.sh` (exige o Xcode 26). O script monta o app em `dist/MeuUso.app` e o abre dali, sem instalar nada em `/Applications`.
- **Baixar o app de desenvolvimento do CI.** Cada execução do CI gera o artefato `MeuUso-dev`, um `.zip` com o app, que fica disponível por 7 dias. Baixe com o GitHub CLI (comando abaixo). Assim o arquivo não ganha a marca de quarentena, e o macOS deixa abrir o app mesmo sem notarização. Baixado pelo navegador, ele vem com essa marca, e o macOS bloqueia a abertura.

```sh
gh run download <run-id> -n MeuUso-dev && ditto -x -k MeuUso-dev.zip .
```

O passo a passo completo está em [Depuração e captura de logs](debugging.md#testar-sem-xcode-local).

Esses builds de desenvolvimento não têm feed de atualização, então nunca buscam atualizações: a seção **Atualizações** não aparece nos Ajustes, e o item **Buscar atualizações…** do menu **Opções** fica desativado. Para atualizar, compile de novo a partir do código mais recente ou baixe um artefato mais novo do CI. Você reconhece um build de desenvolvimento pela versão no rodapé, que termina em `-dev`.

## Como funciona nos builds de release

Quando houver uma release assinada, o app instalado por ela vai se atualizar assim:

- **Busca automática.** O app procura uma versão nova em segundo plano, a cada hora. Quando encontra, aparece o aviso **Atualização disponível** no topo da janela, em vez de uma janela do Sparkle que abriria escondida atrás dos outros apps. Clique em **Instalar atualização** para abrir na frente a janela da atualização (notas da versão, download e instalação). O botão de fechar (✕) adia o aviso; ele volta na próxima vez que o app encontrar a atualização.
- **Busca manual.** Em **Ajustes → Atualizações**, clique em **Buscar atualizações…** quando quiser (o mesmo item fica no menu **Opções** do rodapé). Tanto na busca manual quanto no aviso, o Meu Uso vem para a frente antes de abrir o Sparkle, para a janela da atualização não ficar escondida atrás de outro app. Como o Meu Uso normalmente fica só na barra de menus, ele mostra um ícone no Dock enquanto a atualização acontece e depois some de lá de novo.
- **Para desligar.** A chave **Buscar automaticamente**, em **Ajustes → Atualizações**, desliga as buscas em segundo plano. A busca manual continua funcionando.

## Acesso antecipado

**Ajustes → Atualizações → Acesso antecipado** inclui as versões prévias (beta) antes de elas chegarem a todo mundo. Desative para voltar a receber só versões estáveis; você fica na versão atual até a próxima versão estável alcançá-la.

Todo mundo recebe as versões estáveis. O acesso antecipado só *acrescenta* as versões prévias.

## De onde vêm as atualizações

Cada release publica um DMG nas releases do GitHub do Meu Uso, e a lista de versões disponíveis (o "appcast") fica em `https://gabrielbrazz.github.io/meu-uso/appcast.xml`. Esse endereço só passa a existir com a primeira release assinada. Uma tag simples (como `v0.1.0`) publica para todo mundo; uma tag com sufixo de versão prévia (como `v0.1.0-beta.1`) publica só no acesso antecipado.

Cada download é assinado de dois jeitos (a notarização da Apple e a assinatura própria do Meu Uso), e o app recusa qualquer arquivo que não confira. Só o build de release assinado traz o feed; os builds de desenvolvimento não têm (veja `script/build_and_run.sh` e `script/release.sh`).
