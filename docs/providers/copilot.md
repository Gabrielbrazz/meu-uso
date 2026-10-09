# Copilot

Acompanha a sua cota do GitHub Copilot usando um token do GitHub que as ferramentas do Copilot já deixaram na sua máquina. Sem fluxo de login e sem cookies do navegador.

## O que mostra

| Métrica | O que significa |
|---|---|
| Créditos | Parte usada da sua franquia mensal de créditos de IA (o medidor principal). Em licenças gerenciadas por uma organização e sem franquia, uma contagem simples dos créditos que você mesmo usou no ciclo |
| Uso extra | Interações premium usadas além dos créditos incluídos, depois que o gasto extra é ativado |
| Créditos da organização | Créditos de IA que a organização inteira usou neste mês (licenças Business/Enterprise gerenciadas por uma organização) |
| Gasto da organização | Dólares cobrados da organização por créditos de IA além do pacote incluído |
| Chat | Cota de mensagens de chat usada |
| Sugestões de código | Cota de sugestões de código usada |

Por padrão, Créditos e Uso extra ficam em Sempre visível. Créditos da organização, Gasto da organização, Chat e Sugestões de código começam em Sob demanda, atrás da seta do card. Os medidores de porcentagem mostram quanto foi usado e, quando a resposta traz essa informação, a contagem até a próxima renovação. O nome do plano (Pro, Business, Free, …) aparece ao lado do provedor.

Desde junho de 2026, o GitHub Copilot cobra todos os planos em **créditos de IA**, então o que cada conta mostra depende do plano:

- **Planos pagos** medem o pacote de créditos: você vê Créditos (e Uso extra, se ativou o gasto adicional). Chat e sugestões de código são ilimitados nos planos pagos, então essas linhas mostram "Sem dados".
- **Planos gratuitos** não têm créditos, então Créditos mostra "Sem dados". No lugar, você vê as cotas fixas de Chat e de Sugestões de código, atrás da seta.
- **Licenças gerenciadas por uma organização (Copilot Business / Enterprise atribuídos por uma organização)** não trazem cota percentual por licença. Se o bucket `premium_interactions` da resposta trouxer uma contagem real em `credits_used`, o Meu Uso mostra esse número como **Créditos**. É uma contagem simples, não uma porcentagem, porque o `entitlement` desse bucket é 0 (não há franquia para dividir). Esse é o *seu* consumo e não exige acesso especial. O Meu Uso também procura o uso no faturamento da organização: ele lista as suas organizações, acha aquela cujo faturamento mostra uso de créditos de IA do Copilot e mostra **Créditos da organização** (créditos que a organização inteira usou neste mês) e **Gasto da organização** (dólares cobrados além do pacote incluído). Dois cuidados:
  - Os números de Créditos da organização e Gasto da organização valem para a **organização inteira**, e não são a sua parte. O GitHub não expõe o uso por licença nessa API.
  - Ler o faturamento de uma organização exige que você seja **proprietário da organização ou gerente de cobrança**. Membros comuns não veem Créditos da organização nem Gasto da organização, mas ainda veem a própria contagem de Créditos quando a resposta traz esse dado. Se não trouxer, os medidores mostram "Sem dados".
- Créditos da organização aparece como contagem simples, não como porcentagem: a API de faturamento só informa o uso, nunca a franquia de créditos da organização, e o Meu Uso não inventa um denominador.

O valor dos créditos em dólar (como "US$ 12 de US$ 15 usados") não aparece. O GitHub só mostra esse valor na página de faturamento da web, com login, e lê-lo exigiria os cookies do navegador, o que o Meu Uso não faz. Editores como o VS Code mostram a mesma *porcentagem* de créditos desse endpoint, e não um valor em dólar.

## De onde vêm as credenciais

Conferidas nesta ordem (primeiro os arquivos, que não pedem permissão; as chaves do macOS por último):

1. Token do Copilot no editor: `~/.config/github-copilot/apps.json` (ou o antigo `hosts.json`), gravado pelos plugins do Copilot para VS Code, JetBrains e Neovim.
2. Configuração da CLI do GitHub: `~/.config/gh/hosts.yml` (`oauth_token`), quando o `gh` guarda o token em arquivo.
3. Item da CLI do GitHub nas chaves do macOS (Keychain), no serviço `gh:github.com`, quando o `gh` guarda o token nas chaves do sistema.

### Configuração

Se o uso não aparecer, entre pela CLI do GitHub:

```bash
brew install gh   # se precisar
gh auth login     # escolha GitHub.com e siga as instruções
```

Usar o Copilot num editor compatível já basta: o editor grava o token no `apps.json`.

## Solução de problemas

- **"Entre no GitHub Copilot…"**: nenhum token foi encontrado. Entre no Copilot pelo seu editor ou rode `gh auth login`.
- **"Token do GitHub inválido ou expirado"**: o token foi recusado (401/403). Entre de novo com `gh auth login`.
- **Os medidores mostram "Sem dados", mas o plano aparece**: é o esperado numa licença Copilot Business/Enterprise gerenciada por uma organização quando a resposta não traz um `credits_used` pessoal e você não tem acesso ao faturamento da organização, por não ser proprietário nem gerente de cobrança. O GitHub não expõe a cota por licença de outro jeito, e o faturamento da organização é só para administradores. Se você *é* administrador da organização e ainda não vê Créditos da organização, confira se o seu token consegue listar as suas organizações. O token da CLI do GitHub, do `gh auth login`, consegue; alguns tokens de plugin de editor não.

## Por dentro

`GET https://api.github.com/copilot_internal/user` com os headers padrão do cliente do Copilot (versão da API `2025-04-01`). A resposta informa cada bucket como porcentagem *restante*; os medidores mostram a porcentagem *usada*.

Em licenças gerenciadas por uma organização (identificadas pelo marcador `token_based_billing` nessa resposta), o provedor também chama a API REST pública de faturamento: `GET /user/orgs` para listar as suas organizações e, depois, `GET /orgs/{org}/settings/billing/usage/summary` em cada uma, até achar uma que mostre uso de créditos de IA do Copilot. A organização encontrada fica guardada, então as atualizações seguintes fazem só uma chamada a mais. Se essa organização deixar de mostrar uso do Copilot ou de liberar o acesso, o app procura de novo automaticamente. Falhas passageiras (erro de rede, 429, 5xx) mantêm a organização guardada para a próxima atualização.
