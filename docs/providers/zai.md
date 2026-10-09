# Z.ai

Acompanha as cotas de uso do GLM Coding Plan do [Z.ai](https://z.ai) (Zhipu AI), a assinatura para programação.

## O que mostra

| Métrica | O que significa |
|---|---|
| Sessão | Uso de tokens na janela móvel de 5 horas (porcentagem) |
| Semanal | Uso de tokens na janela móvel de 7 dias (porcentagem) |
| Buscas na web | Chamadas mensais de busca na web, leitura da web e Zread (usado / limite) |

Quando o Z.ai informa o nome do seu plano, o Meu Uso mostra o plano ao lado do nome do provedor.

## De onde vêm as credenciais

O Z.ai não tem uma CLI ou app de onde o Meu Uso possa reaproveitar uma credencial, então você fornece uma chave de API. O Meu Uso lê a chave do primeiro lugar onde ela aparecer, nesta ordem:

1. `~/.config/meu-uso/zai.json`: `{"apiKey":"…"}` (o arquivo que a seção Chave de API grava)
2. `~/.config/zai/key.json`
3. A variável de ambiente `ZAI_API_KEY`
4. A variável de ambiente `GLM_API_KEY` (o nome antigo da Zhipu, ainda aceito)

Você também pode adicionar e trocar a chave em **Personalizar** → Z.ai → **Chave de API**, sem mexer em arquivo. De qualquer jeito, nada sai do seu Mac além das mesmas chamadas de API que a própria página de assinatura do Z.ai faz.

## Configuração

1. [Assine um GLM Coding Plan](https://z.ai/subscribe) e pegue a sua chave de API no [console do Z.ai](https://z.ai/manage-apikey/apikey-list).
2. Adicione a chave ao Meu Uso em **Personalizar** → Z.ai → **Chave de API**, **ou** exporte-a:

```bash
export ZAI_API_KEY="SUA_CHAVE_DE_API"
```

3. Se o Z.ai estiver desligado, ative-o em **Personalizar**. Ele aparece no painel na próxima atualização. Para vê-lo também na barra de menus, use **Adicionar à barra de menus** numa métrica (numa instalação nova, Sessão e Semanal já começam lá).

## Por dentro

Dois endpoints internos e não documentados que a própria página de assinatura do Z.ai usa (estáveis na prática):

- `GET https://api.z.ai/api/biz/subscription/list`: o nome do plano (opcional; uma falha aqui não apaga os medidores).
- `GET https://api.z.ai/api/monitor/usage/quota/limit`: os medidores de cota.

A resposta de cota traz uma lista `limits`. Cada entrada `CREDIT_LIMIT` (chamada `TOKENS_LIMIT` em respostas antigas) é uma janela de cota em porcentagem, e a duração da janela decide qual medidor ela alimenta: menos de um dia vira Sessão, e um dia ou mais vira Semanal. Já uma entrada `TIME_LIMIT` é a contagem mensal de buscas na web. Os horários de renovação vêm como timestamp Unix em milissegundos. Valores de uso obrigatórios que faltam são tratados como resposta inválida, em vez de aparecer como zero.

## Solução de problemas

- **"Nenhuma chave de API do Z.ai"**: adicione uma chave em Personalizar → Z.ai → Chave de API ou exporte `ZAI_API_KEY`.
- **"Chave de API do Z.ai inválida"**: a chave foi recusada (401/403). Gere outra no [console do Z.ai](https://z.ai/manage-apikey/apikey-list).
- **"Nenhum GLM Coding Plan ativo"** (aviso âmbar ao lado do nome): a chave é válida, mas a conta não tem GLM Coding Plan, então não há o que medir. Assine em [z.ai/subscribe](https://z.ai/subscribe). O uso aparece quando o plano estiver ativo.
- **Os medidores mostram "Sem dados de uso"**: você tem um plano, mas o endpoint de cota ainda não devolveu limites que possam ser usados. Confira o seu [plano](https://z.ai/manage-apikey/coding-plan/personal/my-plan).
