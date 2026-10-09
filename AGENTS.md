# AGENTS.md

O Meu Uso é um app de barra de menus para macOS, feito em SwiftUI sobre SwiftPM, que mostra o uso dos provedores de IA (Claude, Codex, Cursor, Grok, Devin e outros). A interface é em português do Brasil.

Este arquivo documenta as convenções de engenharia do projeto. Leia antes de contribuir.

## Instruções para agentes

- **Fonte única.** O AGENTS.md é a fonte das instruções para agentes neste repositório. Os arquivos CLAUDE.md só podem apontar para o AGENTS.md mais próximo com `@AGENTS.md`; não coloque orientação, instrução duplicada nem regra de projeto neles.
- **Fork independente.** O Meu Uso é um fork independente do [OpenUsage](https://github.com/robinebers/openusage) e não sincroniza com ele.
  - Nada no código, nos scripts ou nos workflows pode apontar para a infraestrutura do projeto original: appcast, Pages, analytics, contatos.
  - Referências a issues de lá ficam qualificadas como `robinebers/openusage#123`.
- **Sem telemetria.** O app não coleta dados. Não adicione analytics, crash reporting nem chamadas de rede que não sejam aos provedores ou às tabelas de preço (veja `docs/privacy.md`).

## Releases

- `main` é a linha ativa. O `.github/workflows/release.yml` publica uma versão a partir de uma tag `v*`, com appcast do Sparkle em `gh-pages`. Ele só funciona depois de configurar os segredos da Apple (Developer ID, notarização) e as chaves EdDSA do Sparkle; até lá não há release assinada. O passo a passo está na skill release-swift.
- **Nunca aumente o número da versão por conta própria.** Proponha o número e espere a aprovação explícita do mantenedor antes de criar tag ou release. As versões começam em `0.1.0`.
- Beta usa tag `-beta.N` e fica como pre-release no canal beta do Sparkle; versão estável usa tag simples e vira a "Latest" do GitHub.
- Nunca deixe uma release em rascunho nem publique notas em branco.

## Arquitetura

- Target executável SwiftPM; conteúdo SwiftUI dentro de um `NSStatusItem` e de um `NSPanel` próprio do AppKit, que aceita foco de teclado.
- Swift 6 com concorrência estrita.
- Cada provedor implementa o protocolo `ProviderRuntime`:
  - um auth store lê as credenciais que já estão na máquina;
  - um cliente chama a API do provedor;
  - um mapper normaliza a resposta em `MetricLine`.

  A interface só renderiza esses valores normalizados.
- Veja `docs/` para o comportamento do app e para os docs de desenvolvimento (arquitetura, como adicionar um provedor).

## Idioma e tradução

- **Código em inglês, tela em pt-BR.** Nomes e comentários ficam em inglês. Todo texto de tela é pt-BR e sai da tabela `assets/Localization/pt-BR.lproj/Localizable.strings`, cuja chave é o texto em inglês do código.
- **Regras completas** em `docs/glossario.md`:
  - literal de SwiftUI só precisa da entrada na tabela;
  - fora do SwiftUI, use `L10n.tr` / `L10n.format` / `L10n.plural`;
  - frases inteiras com placeholder;
  - nunca `bundle: .module` nem `#bundle`.
- **Rótulos que servem de chave ficam em inglês nos dados:** nomes de métrica, períodos do Gasto total, unidades. Eles são traduzidos só na exibição.
- **Testes em inglês.** O `swift test` roda sem tabela, então a saída em inglês precisa continuar idêntica.
- **Números e datas** no padrão brasileiro, via `AppLocale.current`.
- **Antes de abrir PR**, rode `python3 script/check_localization.py`. O CI roda o mesmo.

## Provedores

Convenções para os módulos em `Sources/MeuUso/Providers/<Nome>/`.

- **Estrutura:** uma pasta por provedor, com auth store, cliente de uso e mapper, implementando `ProviderRuntime`:
  - `refresh()`;
  - `hasLocalCredentials()`, a sondagem de credenciais locais que o `FirstRunSeeder` usa na primeira execução e o `NewProviderSeeder` usa na primeira abertura depois que o provedor é lançado. Use as mesmas fontes de credencial e os mesmos filtros que o `refresh()`, reaproveitando os leitores do auth store em vez de criar um segundo caminho.

  Veja `docs/adding-a-provider.md` e `docs/provider-enablement.md`.
- **Preço de modelos:** toda estimativa de gasto (Claude, Codex, Cursor, Grok, Antigravity) passa pelo motor de `Sources/MeuUso/Pricing/` (veja `docs/pricing.md`).
  - Preços e regras de alias de modelos nativos do Cursor ficam em `Sources/MeuUso/Resources/pricing_supplement.json`; sincronize com [Cursor models & pricing](https://cursor.com/docs/models-and-pricing.md) (atualize `updated_at`, preços e `alias_rules`).
  - Os apps instalados leem esse arquivo direto do `main`, então o merge já publica. O CI valida o JSON antes.
  - Os snapshots do LiteLLM e do models.dev se regeneram com `script/update_pricing_snapshots.sh`, uma tarefa de release.
- **Ordem padrão:** Claude, Codex e Cursor primeiro, nessa ordem; depois os demais em ordem alfabética do nome exibido (Antigravity, Devin, Grok, …). A ordem é a da lista em `ProviderCatalog.make` (`Sources/MeuUso/Providers/ProviderCatalog.swift`), que alimenta a ordem padrão do `LayoutStore` e o `resetToDefault`. Provedor novo entra na parte alfabética.
- **Posição padrão das métricas:** ao criar ou mudar uma métrica, confirme os quatro padrões com o mantenedor antes de escolher; nunca decida sozinho:
  1. ligada ou desligada (`DefaultLayout.metricIDs`);
  2. sempre visível ou sob demanda, atrás da seta do provedor (`DefaultLayout.expandedMetricIDs`). Todo provedor mantém pelo menos uma linha sempre visível;
  3. fixada na barra de menus (`DefaultLayout.pinnedMetricIDs`);
  4. ordem dentro do provedor (a ordem de declaração em `widgetDescriptors`).
- **Tradução do provedor:** títulos de métrica e mensagens de erro de um provedor novo entram na tabela pt-BR.

## Rodar e testar

- **Compilar:** é preciso o Xcode 26. `swift build`, `swift test` e `./script/build_and_run.sh`, que compila e abre o app de dev a partir de `dist/`.
- **Sem Xcode local:** o CI compila, testa e publica o app de dev como artefato `MeuUso-dev`.
- **Sem hot reload.** O app é um processo de barra de menus de vida longa, então **toda mudança de código exige recompilar e reabrir o app**. O script encerra só a cópia de dev que ele mesmo abriu, nunca outro app instalado.

## Pull requests

A descrição de todo PR segue o modelo em `.github/PULL_REQUEST_TEMPLATE.md`, para que a revisão seja rápida:
- **Resumo:** uma ou duas frases sobre a mudança.
- **Contexto:** o comportamento anterior, o bug ou a lacuna.
- **O que muda:** o que o PR muda de fato.
- **Atenção** (opcional): riscos, pendências, trade-offs.
- **Testes** (opcional): como a mudança foi verificada.
- **Prints:** obrigatórios em qualquer mudança visual.

## Documentação

- Mudança de lógica atualiza os docs de `docs/` que descrevem o comportamento afetado.
- Docs em português, simples, pouco técnicos e fáceis de escanear; sem detalhes de design visual.

## Convenções de código

- Ao corrigir bug, adicione teste de regressão quando couber.
- Arquivos com menos de ~500 linhas; divida ou refatore quando passar disso.
- Nenhuma dependência nova sem justificativa.
- Ao adicionar um provedor, siga as convenções de "Provedores".

## Tratamento de erros

Falhe de forma visível: registre o erro no log e mostre uma mensagem amigável a quem usa. Não crie fallbacks silenciosos que escondem problemas reais. Valide só nas fronteiras do sistema (entrada do usuário, APIs externas); confie no código interno e nas garantias dos frameworks.

## Interface

- Em português, maiúscula só no começo de título, botão e item de menu; os termos seguem o glossário (`docs/glossario.md`).
- Siga a linguagem visual existente; o app tem uma aparência própria.
- Só adicione tooltips (`hoverTooltip`) quando pedirem explicitamente. Não coloque por iniciativa própria em controles novos.
