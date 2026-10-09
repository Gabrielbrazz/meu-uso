# Como adicionar um provedor

Como adicionar um novo provedor de IA ao Meu Uso. Leia antes a [visão geral da arquitetura](architecture.md), para as partes abaixo fazerem sentido.

## O que é um provedor

Um provedor é um módulo Swift pequeno em `Sources/MeuUso/Providers/<Nome>/` que segue o protocolo `ProviderRuntime`. Ele tem três partes:

- um **auth store**, que lê credenciais que já estão no Mac do usuário (arquivos de configuração, Keychain);
- um **cliente de uso**, que chama a API do provedor;
- um **mapper**, que traduz a resposta para o vocabulário de métricas do app.

O Meu Uso nunca pede para o usuário colar um token. Se a CLI ou o app do próprio provedor já fez login, o Meu Uso lê essas credenciais.

Além de `refresh()`, todo provedor implementa `hasLocalCredentials()`, uma verificação rápida e só local (arquivos, Keychain; nunca a rede) que diz se essas credenciais existem. Uma instalação nova faz essa verificação uma vez para ativar exatamente os provedores que o usuário tem (veja `FirstRunSeeder`). Instalações existentes fazem a verificação uma vez, na primeira abertura depois que o seu provedor é lançado (veja `NewProviderSeeder`). É essa implementação que faz o provedor novo ser ativado sozinho para quem de fato tem a ferramenta (veja [Quais provedores ficam ativados](provider-enablement.md)). Use as mesmas fontes de credencial que o `refresh()` lê e rode as leituras que bloqueiam com `loadOffMainActor`.

## O contrato de métricas

`refresh()` devolve um `ProviderSnapshot` cujas `lines` são valores `MetricLine`. Escolha o caso pela forma do número, não pelo provedor:

- **`.progress`**: um medidor com teto, com `used`, `limit` e um `format`:
  - `.percent` para limites do tipo cota (sessão, semanal);
  - `.dollars` para um valor em dólar com teto (créditos com limite);
  - `.count(suffix:)` para uma contagem com teto (por exemplo, requisições por ciclo).
  - Acrescente `resetsAt` quando a janela renova num horário conhecido, e `periodDurationMs` com a duração do ciclo.
- **`.values`**: uma linha sem teto com um ou mais números brutos. Cada um é um `MetricValue`: um número, o tipo dele e um rótulo de unidade opcional, como `"tokens"`. Use para qualquer linha numérica sem limite: um dia de gasto traz dólares *e* tokens, e os créditos do Codex trazem dólares *e* uma contagem. O widget escolhe o que mostrar (só custo, só tokens ou os dois) pelo descritor, e a formatação acontece na hora de exibir, então a barra de menus nunca precisa interpretar um texto. Prefira esse caso para números.
- **`.badge`**: uma etiqueta curta de status, como "Desativado" ou o limite do pagamento por uso. Use para estado, não para um número que enche uma barra.
- **`.chart`**: pontos numéricos com data, para uma linha compacta de tendência de uso.
- **`.text`**: um aviso em texto do provedor, preservado na API local. Não vira widget; use `.progress`, `.values`, `.badge` ou `.chart` em toda linha que tem descritor.

Preencha o `plan` do snapshot quando o provedor informa um nome de plano. Em caso de falha, devolva `ProviderSnapshot.error(provider:error:)` com um erro tipado do provedor sempre que possível. O `errorDescription` desse erro, passado por `L10n.tr`, vira a mensagem amigável que aparece no card, na API local e na CLI, e o `WidgetDataStore` grava a falha no log como `[refresh] <id> failed: <mensagem>`. Use a versão só com mensagem apenas quando não houver erro tipado, e nunca devolva dados velhos ou vazios em silêncio. (A categoria `ErrorCategory`, que os erros declaram com `CategorizedError`, alimentava a telemetria do projeto original. O Meu Uso não tem telemetria, então essa categoria não sai do app.)

## Passos

1. **Confira antes.** Veja as issues abertas e `docs/providers/` para saber se o provedor já foi pedido ou está em andamento.
2. **Crie o módulo.** Crie `Sources/MeuUso/Providers/<Nome>/` com o auth store, o cliente de uso e o mapper, seguindo `ProviderRuntime`: `refresh()` e `hasLocalCredentials()` (o compilador exige o segundo; não há implementação padrão). A verificação precisa continuar só local e reaproveitar as mesmas funções de leitura do auth store e os mesmos filtros de credencial utilizável com que o `refresh()` começa. Não crie um segundo caminho de leitura de credenciais. Reaproveite os utilitários de `Support/` (`ProviderParse` para ler JSON, números e porcentagens, `MeuUsoISO8601` para datas) em vez de copiá-los.
3. **Declare os widgets.** Exponha as métricas do provedor como `WidgetDescriptor`s, usando as factories de `WidgetDescriptor+Factories.swift` (`percent`, `boundedDollars`, `boundedCount`, `values`, `combined`, `spendTiles`, `badge`, `usageTrend` e outras). Para uma métrica aparecer em `/v1/limits` e na CLI, marque o descritor com `.exportingLimit(...)`, como fazem os provedores existentes.
4. **Traduza os textos novos.** Títulos de métrica, unidades, notas de origem e mensagens de erro ficam em inglês no código e precisam de tradução na tabela `assets/Localization/pt-BR.lproj/Localizable.strings`, seguindo o [glossário](glossario.md). Mensagens de erro passam por `L10n.tr`; títulos e unidades são traduzidos na hora de exibir e só precisam da entrada na tabela. Nomes de provedor, plano e modelo não se traduzem. Confira com `python3 script/check_localization.py` (o CI roda o mesmo).
5. **Registre o provedor.** Acrescente o provedor à lista em `ProviderCatalog.make` (`Sources/MeuUso/Providers/ProviderCatalog.swift`), que o app e a CLI usam. A ordem da lista é a ordem padrão: Claude, Codex e Cursor primeiro, depois os outros em ordem alfabética.
6. **Teste.** Escreva testes focados em `Tests/MeuUsoTests/`, incluindo um teste do mapper que recebe uma resposta de exemplo da API e confere as linhas de métrica resultantes. Os testes rodam sem a tabela de tradução, então neles os textos aparecem em inglês.
7. **Documente.** Crie uma página em português em `docs/providers/` dizendo o que o provedor acompanha, de onde vêm as credenciais, quais endpoints ele chama e o que significam os estados de erro.
8. **Rode.** Compile e abra com `./script/build_and_run.sh` (precisa do Xcode 26) e confirme que o provedor aparece. Sem Xcode no Mac, use o build do CI (veja [Testar sem Xcode local](debugging.md#testar-sem-xcode-local)).

## Convenções

- Valide só na fronteira (a resposta da API); confie nos tipos internos do app.
- Use os mesmos rótulos de métrica e as mesmas unidades do painel do próprio provedor, para os números serem reconhecíveis. No código eles ficam em inglês; na tela, vale a tradução da tabela.
- Declare os **links rápidos** do provedor no valor `Provider` dele (`links:`). Cada link é um `ProviderLink(label:url:)`, mostrado como um botão na área expandida do card, que abre a URL no navegador padrão. Inclua as páginas de status, console ou painel do próprio provedor quando existirem; deixe `links` de fora (o padrão é vazio) em provedores sem nenhuma. No máximo **dois** links por provedor. Os rótulos ficam em inglês no código e são traduzidos na tela; os padrões são `"Status"`, `"Dashboard"`, `"API Keys"` e `"Usage"` (na tela, Status, Painel, Chaves de API e Uso). Só aparecem links com URL `http(s)` e rótulo preenchido.

## Chaves de API fornecidas pelo usuário

A maioria dos provedores lê credenciais que já estão no Mac (a sessão de uma CLI ou de um app, o Keychain). Um provedor sem nada local para ler, como o OpenRouter e o Z.ai, adota `APIKeyManaging`. Assim a seção **Chave de API**, na tela do provedor em **Personalizar**, cuida da chave sem nenhum trabalho de interface específico para o provedor:

- O auth store expõe um `keyStatus()` com quatro estados (`notSet` / `fromEnvironment` / `saved` / `overrideActive`), um `currentAPIKey()` para o botão de revelar a chave e `saveAPIKey(_:)` / `deleteAPIKey()`, que gravam num arquivo de configuração que o auth store já lê (por exemplo, `~/.config/meu-uso/openrouter.json`). Como o arquivo de configuração tem prioridade sobre a variável de ambiente, uma chave salva já substitui a do ambiente, sem código extra.
- O provedor adota o protocolo repassando essas chamadas ao auth store (`apiKeyStatus`, `currentAPIKey()`, `saveAPIKey(_:)`, `deleteAPIKey()`).
- O `AppContainer` junta todo provedor `APIKeyManaging` em `apiKeyProviders`, e a tela de cada um deles em **Personalizar** mostra a seção. Basta registrar o provedor como de costume.

Guarde a chave num arquivo que o auth store já consulta (não crie um armazenamento paralelo), para o arquivo continuar sendo a fonte da verdade e o usuário ainda poder editá-lo à mão.
