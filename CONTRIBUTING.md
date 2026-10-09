# Como contribuir com o Meu Uso

Obrigado pelo interesse! O Meu Uso é um projeto pequeno, mantido por uma pessoa, e quer continuar simples. Ele faz uma coisa: mostrar o uso das suas assinaturas de IA, em português, de um jeito rápido e bonito.

## Antes de começar

- **Mudança grande ou feature nova:** abra uma [issue](https://github.com/Gabrielbrazz/meu-uso/issues/new/choose) antes do PR e combine a ideia. Isso evita trabalho perdido.
- **Correção pequena:** bug claro, texto, documentação ou tradução podem ir direto para PR.
- **Um assunto por PR:** não misture mudanças que não têm relação.
- **Escopo:** pedidos fora do acompanhamento de uso de IA tendem a ser recusados.

Ao enviar um PR, você concorda que a sua contribuição fica sob a [licença MIT](LICENSE) do projeto.

## Fluxo

1. Faça um fork e crie uma branch (`feat/minha-mudanca`, `fix/algum-bug`).
2. Faça a mudança.
3. Rode `swift build` e `swift test` (é preciso o Xcode 26). Para ver o app, use `./script/build_and_run.sh`.
4. Abra o PR contra o `main` deste repositório e descreva o que mudou.
5. O CI compila, roda os testes, confere a tradução e gera o app de desenvolvimento (`MeuUso-dev`) para teste.

Mudança visual pede print de antes e depois no PR.

## Texto da interface

O app é só em português do Brasil, mas o código continua em inglês. Todo texto de tela novo precisa de tradução na tabela [`assets/Localization/pt-BR.lproj/Localizable.strings`](assets/Localization/pt-BR.lproj/Localizable.strings), e o CI acusa o que faltar. Como fazer está no [glossário e guia de tradução](docs/glossario.md):
- `Text("...")` já é traduzido pela tabela; fora do SwiftUI, use `L10n.tr` e `L10n.format`;
- monte frases inteiras, nunca pedaços;
- use os termos do glossário;
- escreva com maiúscula só no começo da frase.

Para conferir antes de abrir o PR:

```bash
python3 script/check_localization.py
```

## Adicionar um provedor

Cada provedor é uma pasta em `Sources/MeuUso/Providers/<Nome>/` que implementa `ProviderRuntime`. O provedor lê as credenciais que já estão no Mac, chama a API e normaliza a resposta em métricas. O passo a passo está em [docs/adding-a-provider.md](docs/adding-a-provider.md), e a visão geral em [docs/architecture.md](docs/architecture.md).

1. Crie a pasta e implemente `ProviderRuntime`.
2. Registre o provedor em `ProviderCatalog.make` (`Sources/MeuUso/Providers/ProviderCatalog.swift`), na posição alfabética.
3. Escreva testes em `Tests/MeuUsoTests/`.
4. Crie a página em `docs/providers/`: métricas, de onde vêm as credenciais, endpoints e solução de problemas.
5. Traduza os títulos das métricas e as mensagens de erro.

Também dá para só [pedir um provedor](https://github.com/Gabrielbrazz/meu-uso/issues/new?template=new_provider.yml).

## Padrões de código

- **Toolchain:** Swift 6 com concorrência estrita, compilado com SwiftPM, sem projeto do Xcode.
- **Padrões existentes:** siga o que o código já faz. O [AGENTS.md](AGENTS.md) reúne as convenções.
- **Documentação:** mudança de comportamento visível atualiza a página correspondente em `docs/` no mesmo PR.
- **Dependências:** nenhuma dependência nova sem justificativa.
- **Privacidade:** nada de telemetria, analytics ou chamadas de rede além das necessárias para o provedor e para as tabelas de preço.

## Código herdado

Boa parte do código veio do [OpenUsage](https://github.com/robinebers/openusage). Referências como `robinebers/openusage#123` nos comentários apontam para issues de lá e ficam como registro de origem.

## Mantenedor

- [@Gabrielbrazz](https://github.com/Gabrielbrazz)

## Dúvidas

Abra uma issue com o [modelo de bug](https://github.com/Gabrielbrazz/meu-uso/issues/new?template=bug_report.yml) ou de [sugestão](https://github.com/Gabrielbrazz/meu-uso/issues/new?template=feature_request.yml).
