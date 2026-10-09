# Depuração e captura de logs

Como rodar um build local e acompanhar o que o app está fazendo. Ajuda quando um provedor se comporta mal ou quando você investiga um problema na abertura ou na atualização.

## Rodar um build local

Precisa do Xcode 26. Na raiz do repositório, `swift build` compila e `swift test` roda os testes (sem a tabela de tradução, então eles veem o texto em inglês). Para montar e abrir o app, use o script do projeto:

```sh
./script/build_and_run.sh          # compila e abre o app de desenvolvimento a partir de dist/
./script/build_and_run.sh build    # só compila e monta, sem abrir
./script/build_and_run.sh verify   # abre e confirma que o processo está rodando
```

O script monta e assina um app em `dist/` e o abre ali mesmo; nada é instalado em `/Applications`. O build de desenvolvimento usa um bundle ID próprio (`io.github.gabrielbrazz.meuuso.dev`), então tem ajustes e Keychain separados e nunca interfere num Meu Uso de release.

Esse build não traz feed de atualização, então nunca busca atualizações (a seção **Atualizações** nem aparece nos **Ajustes**). O Sparkle só funciona em builds de release, assinados e notarizados, que leem o feed `https://gabrielbrazz.github.io/meu-uso/appcast.xml`. Esse feed só passa a existir com a primeira release assinada; até lá, não há como testar atualizações. Veja [Atualizações](updates.md).

## Testar sem Xcode local

Sem Xcode no Mac, use o build do CI. A cada push no `main` e a cada PR aberto contra o `main`, o job "Dev app" do CI (`.github/workflows/ci.yml`) compila o app de desenvolvimento e publica o artefato `MeuUso-dev`, que fica disponível por 7 dias. Esse job só roda se a compilação e os testes passarem. Para baixar e abrir, numa pasta vazia:

```sh
gh run list --workflow ci.yml                    # mostra o ID de cada execução
gh run download <id-da-execução> -n MeuUso-dev   # baixa o MeuUso-dev.zip
ditto -x -k MeuUso-dev.zip .                     # extrai o MeuUso.app
open MeuUso.app
```

Baixe pelo `gh`: ele não marca o arquivo com a quarentena do macOS, então o app, que tem só assinatura ad hoc, abre normalmente. Baixado pelo navegador, o macOS bloquearia o app. Esse build não tem iCloud (a Sincronização com o iCloud fica indisponível) e, sem uma identidade de assinatura estável, o macOS pode pedir de novo acesso ao Keychain a cada build novo.

### Encontrar texto sem tradução

O app lê as traduções da tabela que vai dentro dele (`Bundle.main`). Para destacar o que ficou sem tradução, abra o app com a opção `-NSShowNonLocalizedStrings YES`. Feche antes o app de desenvolvimento, se ele estiver aberto, porque só roda uma cópia de cada build por vez:

```sh
open MeuUso.app --args -NSShowNonLocalizedStrings YES
```

Com essa opção, todo texto que passa pela tabela e não tem tradução aparece EM MAIÚSCULAS, e o macOS registra um aviso no log do sistema. A opção vale só para essa abertura. Funciona com o app montado pelo script ou pelo CI; com `swift run`, que não tem tabela, tudo apareceria em maiúsculas.

Dois cuidados:

- Texto que nem passa pela tabela continua em inglês normal. O `python3 script/check_localization.py --lint` ajuda a achar esses casos.
- Pode haver falso positivo: um texto que já chega traduzido e passa de novo pela tabela também aparece em maiúsculas.

## Acompanhar os logs

Para ver os logs do app ao vivo enquanto reproduz um problema:

```sh
./script/build_and_run.sh logs
```

Isso abre o app de desenvolvimento e depois transmite os logs unificados dele. Por baixo, o script filtra o log do sistema pelo processo do app, o equivalente a:

```sh
log stream --info --style compact --predicate 'process == "MeuUso"'
```

Para ler os logs *depois*, em vez de ao vivo, use `log show` com uma janela de tempo:

```sh
log show --last 10m --info --predicate 'process == "MeuUso"'
```

## Arquivo de log

Além do log unificado acima, o app grava um arquivo de log em `~/Library/Logs/MeuUso/MeuUso.log`. É esse arquivo que você manda num relato de problema. Ele tem um limite de cerca de 10 MB, com um arquivo anterior `.1`. Aumente o detalhe em **Ajustes → Avançado → Nível de log** (use **Depuração** para o detalhe completo) e pegue o arquivo com **Copiar caminho do log** ou **Mostrar no Finder**, na mesma seção. Veja [Logs](logging.md) para os níveis, as tags de subsistema e a garantia de que segredos nunca vão para o log.

## Linhas de log de conta

A verificação de contas na abertura (qual conta está logada na pasta padrão do Claude e do Codex) deixa um rastro curto no arquivo de log:

- `accounts: claude default identity resolved (claude@<hash>)`: o login padrão identificou a conta. O hash vem do ID da conta, então duas aberturas com a mesma conta sempre batem.
- `accounts: codex default identity unresolved — …`: existe um login, mas não dá para identificar a conta com certeza nesta abertura (um arquivo de autenticação sem ID de conta, ou uma credencial do Keychain cujo segredo o app não lê na abertura). O card funciona como antes; só não participa ainda dos recursos que dependem de conta.
- `stale account cache discarded for claude`: a conta na pasta padrão mudou de uma abertura para outra, então o snapshot em cache da conta anterior foi descartado, em vez de aparecer com o login novo.
- `account identity read skipped for claude, codex: login shell cold and no shell-environment snapshot exists yet`: na primeira abertura, o shell de login demorou a responder, então as famílias citadas ficaram sem leitura nessa abertura. As aberturas seguintes já têm uma cópia salva do ambiente do shell para usar.

## Dicas

- **Um provedor mostra erro.** Reproduza com o `logs` rodando e veja a página do provedor em `docs/providers/`, que explica os estados de erro e de onde ele lê as credenciais.
- **Nada atualiza.** A atualização roda num timer e respeita o cache; veja [Atualização e cache](refreshing.md) para saber quando uma chamada de rede acontece de fato. Para forçar uma, clique com o botão direito numa linha do provedor e escolha **Atualizar** seguido do nome dele (por exemplo, **Atualizar Codex**).
- **Pedidos de permissão ou de acesso ao Keychain a cada build.** O script assina com uma identidade Apple Development estável, para as permissões continuarem valendo. Se os pedidos se repetem, confira se existe uma identidade dessas no seu Keychain (o script avisa quando cai para a assinatura ad hoc).
- **Inspecione a API local.** Com o app aberto, `curl 127.0.0.1:6737/v1/usage` mostra os mesmos snapshots de uso que a interface usa. Ajuda a saber se o problema está na busca e no mapeamento ou na interface. Se um Meu Uso de release também estiver aberto, a porta fica com o que abriu primeiro.
