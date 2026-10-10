# Privacidade

O Meu Uso não tem telemetria. Ele não envia estatísticas de uso, relatórios de falha nem aviso de "app ativo" para serviço nenhum, e não existe ajuste para ligar isso. Esta página mostra com quem o app fala pela rede, o que ele guarda no seu Mac e quem consegue ler a API local.

## Com quem o app fala pela rede

- **Os provedores que você ativou.** Para mostrar seu uso, o Meu Uso chama a API de cada provedor ativado com as credenciais que já estão no seu Mac. São as mesmas chamadas que as ferramentas do próprio provedor fazem: consultar uso, plano e limites e, quando preciso, renovar o login. O app não consulta provedores desativados (o comando `meu-uso` só consulta um provedor desativado se você pedir por ele pelo nome). A detecção de provedores, na primeira abertura ou quando chega um provedor novo, só olha o seu Mac, sem usar a rede. As páginas de cada provedor, listadas em [Provedores](README.md#provedores), mostram os endereços usados.
- **As tabelas públicas de preço.** Para estimar o custo em dólar a partir dos tokens, o app baixa três listas públicas de [preços dos modelos](pricing.md), no máximo uma vez por hora cada (depois de uma falha, tenta de novo em 30 minutos):
  - `https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json` (LiteLLM);
  - `https://models.dev/api.json` (models.dev);
  - `https://raw.githubusercontent.com/Gabrielbrazz/meu-uso/main/Sources/MeuUso/Resources/pricing_supplement.json` (o suplemento de preços do Meu Uso).

  São downloads simples de dados públicos: não levam uso, logs nem dados de conta. O app traz cópias embutidas dessas listas para funcionar sem internet.
- **A checagem de atualização.** A versão instalada pelo Terminal consulta `https://api.github.com/repos/Gabrielbrazz/meu-uso/releases/latest` quando abre e depois uma vez por dia, para saber se existe versão nova. O pedido leva só a versão do app, no cabeçalho `User-Agent`. O `meu-uso update` e o script de instalação baixam o app das releases do GitHub. Uma futura versão assinada vai usar o feed do Sparkle, `https://gabrielbrazz.github.io/meu-uso/appcast.xml`, a cada hora (se **Buscar automaticamente** estiver ativado). Nenhuma dessas buscas leva dados de uso, contas ou identificadores. Os builds de desenvolvimento não fazem nenhuma delas. Veja [Atualizações](updates.md).
- **O iCloud, só se você ativar.** Com **Sincronizar entre Macs** ativado (vem desativado), o app grava no container privado dele, na sua conta do iCloud: os tokens e gastos diários normalizados, os totais por modelo, os nomes de modelos desconhecidos, o nome do Mac e identificadores das contas do Claude e do Codex (nos cards de conta do Codex, o identificador inclui o e-mail da conta). Credenciais, limites de conta, respostas dos provedores e logs brutos nunca vão para lá. Veja [Sincronização com o iCloud](icloud-sync.md), que também explica por que a opção fica indisponível nos builds de hoje.

As linhas de gasto calculadas a partir dos logs locais das ferramentas (como as do Claude e do Codex) são montadas inteiramente no seu Mac; nenhum dado desses logs sai dele. O botão **Relatar um problema…** e os botões de atalho dos cards só abrem páginas no seu navegador. Fora a exceção acima, o comando `meu-uso` segue as mesmas regras do app. Se você configurar um [proxy](proxy.md), as chamadas aos provedores e às tabelas de preço passam por ele.

## O que fica no seu Mac

- **Log.** O arquivo `~/Library/Logs/MeuUso/MeuUso.log`, mais uma cópia anterior (`MeuUso.1.log`), com no máximo uns 20 MB no total. Tokens, cookies e chaves de API são mascarados antes de qualquer linha ser gravada (sobram só os 4 primeiros e os 4 últimos caracteres, ou `[REDACTED]` quando o valor é curto demais), caminhos dentro da sua pasta pessoal viram `[PATH]` e as respostas dos provedores nunca são gravadas inteiras. O log só sai do Mac se você mesmo enviar. Veja [Logs](logging.md).
- **Ajustes e últimos valores.** Os ajustes e o cache com os últimos valores de cada provedor (o que aparece na hora quando o app abre) ficam nas preferências do app, em `~/Library/Preferences/io.github.gabrielbrazz.meuuso.plist` (no build de desenvolvimento, `io.github.gabrielbrazz.meuuso.dev.plist`).
- **Tabelas de preço.** As cópias baixadas das tabelas públicas de preço ficam em `~/Library/Application Support/MeuUso/pricing/`.
- **Cache da leitura de logs.** Para não reler a cada abertura os logs do Claude, do Codex, do Grok e do pi que não mudaram, o Meu Uso guarda os eventos de uso já lidos em `~/Library/Application Support/MeuUso/log-scan-cache/`. Esses registros têm só os dados de uso necessários para os totais locais, inclusive o custo por evento quando o provedor já registra esse valor, e não guardam linhas JSONL brutas nem texto de conversa. Ficam restritos à sua conta do macOS e nunca são enviados a um provedor nem ao iCloud. Registros de arquivos antigos saem à medida que a janela de leitura avança, e caches de identidades sem uso há 35 dias são removidos. O cálculo de preço roda depois da leitura do cache, então os totais calculados não ficam salvos nele.
- **Chaves de API.** As chaves do OpenRouter e do Z.ai que você digita em Personalizar ficam em `~/.config/meu-uso/openrouter.json` e `~/.config/meu-uso/zai.json`, num JSON simples (`{"apiKey": …}`) que só a sua conta do macOS pode ler. Se a chave vem de uma variável de ambiente (`OPENROUTER_API_KEY`, `ZAI_API_KEY`), o app só lê e não grava nada.
- **ID deste Mac.** Um ID aleatório deste Mac, usado pela sincronização com o iCloud, fica nas chaves do macOS (item `io.github.gabrielbrazz.meuuso.icloud-sync-device-id.v1`). Ele é criado mesmo com a sincronização desativada, mas só sai do Mac se você ativá-la.

## Credenciais guardadas neste Mac

O Meu Uso usa principalmente as credenciais que as ferramentas dos provedores já guardam no seu Mac. Quando ele grava uma chave de API digitada por você ou salva uma credencial renovada, o arquivo é substituído de uma vez só e fica restrito à sua conta do macOS (leitura e escrita só para o dono). O cache de curta duração com tokens renovados do Antigravity (`~/Library/Application Support/MeuUso/antigravity/auth.json`) fica amarrado ao login atual nas chaves do macOS por uma impressão digital de mão única; a credencial de renovação em si não é copiada. Esse cache nunca é usado depois de um logout, de uma troca de conta ou enquanto o acesso às chaves do macOS estiver indisponível.

O acesso ao Claude Desktop é só de leitura. O Meu Uso pode pedir ao macOS permissão para usar o item `Claude Safe Storage` das chaves do macOS, para decifrar o token de acesso atual do Desktop. Ele nunca usa o token de renovação do Desktop, que muda a cada uso, e nunca altera a configuração, os cookies ou os itens do Desktop nas chaves do macOS.

## API local

A [API HTTP local](local-http-api.md) só escuta em `127.0.0.1:6737`, então outros aparelhos da sua rede não conseguem acessá-la. Ela só permite leitura e entrega os mesmos dados de uso da barra de menus, inclusive nomes de conta que podem conter o seu e-mail, mas nunca credenciais nem tokens. E ela não atende páginas da web: as respostas não trazem CORS, e requisições com `Origin` ou com `Host` diferente de `127.0.0.1:6737` e `localhost:6737` recebem 403. Assim, um site aberto no seu navegador não consegue ler esses dados; `curl`, scripts e apps do seu Mac continuam lendo. Veja [CORS e privacidade](local-http-api.md#cors-e-privacidade).

## Na tela

Para esconder os números da barra de menus quando você compartilha ou grava a tela, ative **Ajustes → Privacidade → Ocultar ao compartilhar a tela**. Veja [Barra de menus](menu-bar.md#ocultar-o-uso-ao-compartilhar-a-tela).
