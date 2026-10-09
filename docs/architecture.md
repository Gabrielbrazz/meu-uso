# Arquitetura

Um mapa geral de como o Meu Uso é montado, para quem mexe no código. Para saber o que o app *faz*, comece pelos [documentos de comportamento](README.md).

## A forma do app

O Meu Uso é um pacote SwiftPM com um módulo compartilhado e dois executáveis finos. Não existe projeto do Xcode, mas o build precisa do Swift 6.2 que vem com o Xcode 26. O executável principal é um app de barra de menus: uma interface SwiftUI dentro de um item de status e de um painel do AppKit. O código, em `Sources/MeuUso/`, fica agrupado por papel:

- `App/`: inicialização e a ponte com o AppKit (item de status, painel, ponto de entrada do app).
- `Models/`: os tipos de valor pequenos que o resto do app usa para se comunicar (`MetricLine`, `WidgetData`, descritores).
- `Providers/`: uma pasta por provedor (Claude, Codex, Cursor, Devin, Grok, OpenCode, …).
- `Pricing/`: o motor de preços das linhas de gasto (veja [Preços dos modelos](pricing.md)).
- `Stores/`: o estado mutável que a interface observa.
- `Services/`: infraestrutura compartilhada (HTTP, a API local, execução de processos).
- `Support/`: utilitários pequenos e compartilhados (formatação, parsing, animações, idioma).
- `Views/`: as telas em SwiftUI (painel, Personalizar, Ajustes, faixa da barra de menus).

## Raiz de composição

O `AppContainer` é o único lugar que liga tudo. Na abertura, ele monta a lista de provedores (pelo `ProviderCatalog`), transforma essa lista num `WidgetRegistry`, cria os stores, inicia o ciclo periódico de atualização e sobe a API HTTP local. Todo o resto recebe daqui o que precisa, em vez de buscar variáveis globais, o que deixa cada parte testável isoladamente.

O executável `meu-uso` (o produto `meu-uso-cli`, que vai dentro do app como `Contents/Helpers/meu-uso`) importa o mesmo módulo e monta o mesmo `ProviderCatalog`. Uma chamada normal lê o `ProviderSnapshotCache` e só atualiza, pelo `WidgetDataStore`, os provedores sem snapshot ou com snapshot vencido. Com `--force`, ela força a atualização por esse mesmo caminho antes de ler. Os provedores marcam os recursos numéricos que exportam pelo contrato estável de limites, e a CLI e o `/v1/limits` usam o mesmo serializador sobre esses snapshots normalizados. A CLI nunca abre a interface gráfica nem duplica lógica de provedor, autenticação, preços ou mapeamento.

## O fluxo de um provedor

Cada provedor é um módulo pequeno que segue o protocolo `ProviderRuntime`. Uma atualização passa por três partes:

1. **Auth store**: lê credenciais que já existem no Mac (arquivos de configuração, Keychain). O Meu Uso nunca pede para o usuário colar tokens.
2. **Cliente de uso**: faz as chamadas HTTP para a API do provedor.
3. **Mapper**: traduz a resposta do provedor para o vocabulário do app. O resultado é um `ProviderSnapshot` com valores tipados de widget (`.progress`, `.values`, `.badge`, `.chart`), além de avisos `.text`, que continuam disponíveis pela API local mas não viram widget.

Como todo provedor produz as mesmas formas normalizadas de `MetricLine`, a interface desenha todos do mesmo jeito e não precisa conhecer os detalhes de cada um. Para adicionar um, veja [Como adicionar um provedor](adding-a-provider.md).

Claude, Codex, Grok e pi compartilham o `IncrementalJSONLScanner` para ler o histórico local em JSONL. Os eventos lidos de cada arquivo ficam em cache por caminho, tamanho e data de modificação, num armazenamento versionado em Application Support, separado por provedor e pela pasta de dados lida. Instâncias de provedor que leem a mesma pasta compartilham um único actor de leitura, o que evita ler os mesmos arquivos de novo para cards diferentes; o armazenamento em disco garante o reaproveitamento de uma abertura do app para outra.

A leitura descarta os registros de arquivos cuja data de modificação sai da janela de histórico pedida, mas a agregação e os preços rodam a cada atualização, a partir dos eventos em cache. Os arquivos são lidos em lotes pequenos e limitados. Registros individuais grandes demais são pulados e registrados no log, para que históricos cheios de mídia ou corrompidos não esgotem a memória.

## Subprocessos locais

Os utilitários de credencial e de descoberta capturam stdout e stderr em filas privadas separadas. Os dois fluxos são lidos enquanto o comando roda, então nem uma saída grande nem um pool de workers compartilhado ocupado deixam a leitura do pipe presa. Um comando que estoura o prazo ainda encerra a árvore de processos e informa o tempo esgotado.

## Stores

A interface lê de alguns stores observáveis:

- `WidgetDataStore`: o snapshot mais recente de cada provedor, além da atualização e do cache. Ele guarda separados os snapshots em cache deste Mac e os snapshots renderizados, para que o histórico de outros Macs nunca seja gravado de volta e contado de novo.
- `LayoutStore`: quais métricas aparecem, a ordem de provedores e métricas e quais métricas têm estrela para a barra de menus.
- `ProviderEnablementStore`: quais provedores o usuário ativou ou desativou.
- `ICloudUsageSyncStore`: um arquivo de histórico por Mac, gravado de forma coordenada e atômica, as notificações de metadados do iCloud e o estado visível de dispositivos e erros. O acesso a arquivos é injetado para os testes de ciclo de vida e de falha.

A atualização roda num timer no `AppContainer`. Cada passada respeita o cache, então a rede só é chamada quando um snapshot de fato venceu.

Provedores com linhas de gasto declaram um escopo de histórico explícito ao lado dos descritores de exportação. Fontes locais de cada Mac podem ser somadas entre os arquivos dos dispositivos; fontes da conta inteira, como o Cursor, não. O `WidgetDataStore` renderiza de novo só as linhas de gasto a partir da união e mantém o estado de cota e de erro de cada Mac.

## A ponte com o AppKit

Apps de barra de menus no macOS ficam num `NSStatusItem`. O Meu Uso mostra o conteúdo num `NSPanel` próprio, que pode virar janela-chave, em vez de um `NSPopover`. A janela de um popover só vira janela-chave enquanto o app inteiro está ativo, e ativar um app de barra de menus (acessório) é assíncrono e pouco confiável nas versões recentes do macOS. Com isso, o popover acaba sem receber teclas até um segundo clique. Um `NSPanel` que não ativa o app, com `canBecomeKey` igual a `true`, recebe o foco do teclado no instante em que abre, então a navegação por teclado e o gravador de atalho dos Ajustes simplesmente funcionam. A pasta `App/` cuida dessa camada AppKit e hospeda as views SwiftUI dentro dela, para que quase toda a interface continue sendo SwiftUI puro.

O SwiftUI mede o conteúdo de cada tela e conduz o redimensionamento do painel no mesmo relógio de animação da navegação entre telas. As posições das linhas usadas para reordenar arrastando ficam fora do estado observável das views, então rolar e trocar de tela não reconstroem as listas inteiras, e a sombra do painel só é atualizada quando o tamanho se assenta. A borda de cima do painel e cada passo do redimensionamento caem em pontos inteiros, então o painel fica parado sob a barra de menus enquanto a altura anima. Os Ajustes continuam montados depois da primeira visita, então voltar a eles reaproveita os controles nativos.

## Plataformas

O Meu Uso roda no macOS 15 (Sequoia) e posteriores. Ele é compilado com o SDK mais recente e continua compatível com versões anteriores: no macOS 26 (Tahoe), usa os controles Liquid Glass do sistema; no macOS 15, volta aos controles padrão com o mesmo comportamento (o rodapé continua fixo, os botões mantêm seus estados). Quase todas essas verificações de versão ficam num arquivo só, `Support/LiquidGlassFallbacks.swift`, para as views ficarem livres de `#available`. A exceção é o efeito do modo festa, em `Support/TooMuchTransparencyEffect.swift`.

O build de release (`script/release.sh`) gera um binário universal (arm64 + x86_64), então um único DMG roda nativamente em Macs com Apple Silicon e com Intel. Ainda não saiu nenhuma release assinada; é esse script que vai gerá-la. O build de desenvolvimento (`script/build_and_run.sh`) fica só na arquitetura da máquina: um build universal só dobraria o tempo de compilação, sem ganho nenhum.

## Idioma

O app é só em português do Brasil, mas o código continua em inglês. Cada texto de interface em inglês é a chave de uma tabela, `assets/Localization/pt-BR.lproj/Localizable.strings`, que traz a tradução. Os scripts de build (`script/build_and_run.sh` e `script/release.sh`) copiam a pasta `pt-BR.lproj` para `Contents/Resources` do app. Literais de SwiftUI já funcionam como chave; o resto passa por `L10n` (`Sources/MeuUso/Support/L10n.swift`), que também acha a tabela quando quem roda é a CLI dentro do app. Números, moeda e datas usam `AppLocale.current` (`pt_BR`, no mesmo arquivo), seja qual for a região do Mac. O `swift test` e o `swift run` rodam sem a tabela e veem o texto em inglês. As regras e os termos estão no [glossário](glossario.md), e o CI confere as traduções com `script/check_localization.py`.

## API HTTP local

Um servidor pequeno de loopback expõe o uso atual em JSON em `127.0.0.1:6737`, para outras ferramentas do Mac. Veja [API HTTP local](local-http-api.md) para as rotas e o que isso significa para a privacidade.
