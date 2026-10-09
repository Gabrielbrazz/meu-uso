# Sincronização com o iCloud

> **Disponibilidade.** A sincronização só funciona num build assinado com um perfil de provisionamento que inclua o container do app no iCloud: `iCloud.io.github.gabrielbrazz.meuuso` (ou `iCloud.io.github.gabrielbrazz.meuuso.dev`, no build de desenvolvimento). Hoje nenhum build disponível tem esse perfil: ainda não existe release, e o app de desenvolvimento gerado pelo CI (`MeuUso-dev`) não o inclui. Um build feito no seu Mac com `./script/build_and_run.sh` também fica sem ele, a menos que um perfil de desenvolvimento do container esteja instalado (veja [Configuração para desenvolvimento e release](#configuração-para-desenvolvimento-e-release)). Sem o perfil, a chave **Sincronizar entre Macs** aparece nos Ajustes, mas, ao ativá-la, surge o aviso "O iCloud Drive não está disponível. Confira se este Mac tem sessão iniciada no iCloud e se o iCloud Drive está ativado." e nada é sincronizado, mesmo com o iCloud Drive ativado.

**Sincronizar entre Macs** vem desativado. Com ele ativado, cada Mac grava um arquivo versionado com o histórico do Meu Uso no container privado do app no iCloud e lê os arquivos gravados pelos outros Macs com a mesma conta do iCloud. Um ID aleatório do aparelho fica guardado nas chaves do macOS, para o mesmo Mac continuar atualizando o mesmo arquivo depois de redefinir os ajustes ou reinstalar o app. Não há escolha de pasta, código de pareamento nem conta separada.

O arquivo traz os tokens e gastos diários normalizados, os totais por modelo e os nomes de modelos desconhecidos das fontes que ficam em cada Mac: Antigravity, Claude, Codex, Grok e OpenCode. Também traz o nome do Mac e, quando existem, identificadores de conta e de organização ou espaço de trabalho do Claude e do Codex (nos cards de conta do Codex, o identificador inclui o e-mail da conta). Nunca traz credenciais, limites de conta, logs brutos ou respostas dos provedores. O histórico do Cursor já vale para a conta inteira, então fica só local e nunca é somado entre Macs. Desativar um provedor tira na hora as contribuições dos outros Macs da visão somada e deixa esse provedor de fora da próxima gravação deste Mac no iCloud, mas o cache local dele continua.

O histórico do Claude que identifica a conta e a organização só é somado com as mesmas contas nos outros Macs. Históricos antigos, de uma conta só e sem informação de conta, continuam compatíveis quando há apenas um card do Claude na tela e são ignorados quando há vários. Se o histórico de contas do Codex exigir um arquivo de sincronização com contas, o histórico do Claude sem conta conhecida fica de fora desse arquivo. Os outros provedores continuam sincronizando.

Os cards do Codex Swap só somam histórico quando a conta e o espaço de trabalho batem. Histórico antigo do Codex sem essa informação fica fora dos cards do Swap. Instalações do Codex sem cards de conta mantêm o comportamento de sincronização de antes. Cada Mac conta o gasto de uma pasta do Codex para a conta conectada naquela pasta, então o mesmo histórico nunca aparece em dois cards.

O Meu Uso junta os arquivos válidos na memória e refaz Hoje, Ontem, Últimos 30 dias, Tendência de uso, os avisos de modelo desconhecido e os detalhamentos por modelo. As mesmas linhas de gasto somadas alimentam o painel, o Gasto total, as métricas com estrela na barra de menus, os cards de compartilhamento e a API HTTP local. `/v1/usage` e `/v1/limits` leem os mesmos dados exibidos: o primeiro é o formato antigo, pensado para a interface e já obsoleto, e o segundo é o formato normalizado. Dentro desses dados, cotas, planos, saldos e erros dos provedores continuam sendo os valores deste Mac. Linhas guardadas num arquivo antigo de outro Mac são ignoradas quando saem da mesma janela de datas usada pela leitura do histórico local.

Este Mac atualiza o arquivo dele depois de cada rodada de atualização de cinco minutos, de uma atualização manual ou de uma mudança nos provedores ativados. A entrega pelo iCloud não é imediata, então outro Mac pode levar mais de cinco minutos para receber o arquivo, principalmente se estiver offline. Mudanças baixadas recarregam na hora, assim que o macOS avisa que chegaram.

Os Ajustes listam cada arquivo de aparelho válido, com o horário em que aquele Mac o gerou (por exemplo, "Atualizado há 5min"). Para tirar um Mac do resumo somado, desative a sincronização naquele Mac; isso apaga o arquivo dele do iCloud. Desativar a sincronização também faz aquele Mac parar de ler os outros e volta na hora todas as telas dele para o gasto só local. Arquivos com defeito são ignorados e aparecem nos Ajustes ("Parte dos dados de uso sincronizados não pôde ser lida. Veja os detalhes no log.") e no log do app.

## Configuração para desenvolvimento e release

A Apple exige que o container do iCloud esteja no perfil de provisionamento embutido no app. O Meu Uso usa recursos separados para que builds de desenvolvimento não gravem no histórico de produção:

- `io.github.gabrielbrazz.meuuso.dev` usa `iCloud.io.github.gabrielbrazz.meuuso.dev`.
- `io.github.gabrielbrazz.meuuso` usa `iCloud.io.github.gabrielbrazz.meuuso`.

Crie um perfil `MAC_APP_DEVELOPMENT` que inclua todos os Macs de desenvolvimento registrados e um perfil `MAC_APP_DIRECT` para as releases. Instale o perfil de desenvolvimento em cada Mac incluído. O build de desenvolvimento escolhe sozinho o perfil mais novo e ainda válido que combine com o bundle de desenvolvimento e com o container do iCloud, procurando na pasta atual de perfis do Xcode ou na pasta antiga do MobileDevice:

```bash
./script/build_and_run.sh
```

Defina `ICLOUD_PROVISIONING_PROFILE=/path/to/profile.mobileprovision` só quando precisar substituir essa escolha automática. Se o caminho informado não existir, o build falha, em vez de gerar em silêncio um app sem acesso ao iCloud. Se nenhum perfil compatível for encontrado, o script avisa (`no matching installed iCloud provisioning profile was found`) e gera o app sem acesso ao iCloud.

O workflow de release lê o perfil `MAC_APP_DIRECT`, em base64, do segredo de Actions `APPLE_DEVELOPER_ID_ICLOUD_PROFILE` do repositório. Guarde os perfis de provisionamento originais e o `.p12` de assinatura num gerenciador de senhas, nunca no repositório. Um perfil de provisionamento traz certificados e permissões (entitlements), não chaves privadas, mas tratá-lo como material de assinatura deixa a troca previsível.

Para conferir o histórico que um build em execução gravou de fato, encontre o arquivo primeiro e só chame o `jq` se ele existir:

```bash
file=$(find "$HOME/Library/Mobile Documents" \
  -type f -path '*meuuso*/MeuUso/History/v1/*.json' -print -quit)

if [[ -n "$file" ]]; then
  jq . "$file"
else
  echo "No MeuUso iCloud history file found"
fi
```

É normal não haver arquivo quando a sincronização está desativada, quando o app foi assinado sem o perfil certo ou quando a primeira gravação ainda não terminou. O aviso nos Ajustes e o log do app diferenciam esses casos; o indicador de carregamento só aparece enquanto uma leitura ou gravação no iCloud está de fato acontecendo.
