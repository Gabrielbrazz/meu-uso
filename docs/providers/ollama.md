# Ollama

Acompanha o uso do plano do [Ollama Cloud](https://ollama.com): os limites de sessão, semanal e mensal que o Ollama mostra na própria página de ajustes.

## O que mostra

| Métrica | O que significa |
|---|---|
| Sessão | Uso na janela de 5 horas (porcentagem da franquia do seu plano) |
| Semanal | Uso na janela de 7 dias (porcentagem da franquia do seu plano) |
| Mensal | Uso no mês (porcentagem da franquia do seu plano), quando a sua conta informa |
| Últimas 4 semanas | Cobranças além do seu plano nas últimas quatro semanas. US$ 0,00 em planos de assinatura; valores reais no modo pago por uso e no uso com chave de API |

O seu plano (Free, Pro, Max) aparece ao lado do nome do provedor. Se o Ollama não conseguir dizer ao Meu Uso em qual plano você está, o plano fica de fora e o card explica por quê. Os medidores continuam funcionando de qualquer forma.

Sessão, Semanal e Mensal ficam sempre visíveis, e Sessão e Semanal já começam na barra de menus. Mensal começa fora da barra de menus e vem logo depois de Semanal. Últimas 4 semanas fica atrás da seta do card. Você pode mover qualquer uma delas em **Personalizar**. Um US$ 0,00 nessa linha quer dizer que não houve cobrança extra, e não que o mês ficou sem uso: o uso dentro da franquia do plano aparece nos medidores de limite.

A janela de sessão tem 5 horas e a semanal tem 7 dias, mas o Ollama só informa quanto de cada janela você usou, nunca quando a janela atual começou ou termina. Por isso, esses medidores não mostram uma contagem até a renovação, para não exibir um número chutado. O Mensal também não tem contagem. Modelos locais não contam para esses limites; só os modelos na nuvem.

## De onde vêm as credenciais

Não há nada para colar. O Ollama cria uma chave de assinatura digital em `~/.ollama/id_ed25519` na primeira vez que roda, e o `ollama signin` liga essa chave à sua conta no ollama.com. O Meu Uso lê a chave, assina cada pedido com ela exatamente como a CLI do Ollama faz e nunca manda a chave para lugar nenhum. Só a assinatura digital sai do seu Mac.

Como essa chave existe mesmo que você nunca tenha entrado, o Meu Uso só consegue saber que o Ollama está instalado, e não que o Ollama Cloud está configurado. Por isso, o Ollama nunca se ativa sozinho, mesmo com a chave presente. Se você usa o Ollama só com modelos locais, ele não atrapalha mostrando um aviso de login de um produto que você não usa. Ative-o em **Personalizar** quando quiser.

## Configuração

1. Instale o [Ollama](https://ollama.com/download) e crie uma conta num [plano na nuvem](https://ollama.com/pricing), incluindo o Free.
2. Entre:

```bash
ollama signin
```

3. Ative o **Ollama** em **Personalizar**. Ao contrário da maioria dos provedores, ele nunca se ativa sozinho (veja acima).

Os limites que o Ollama informa para a sua conta aparecem na próxima atualização. Contas Free podem informar um limite Mensal sem limites de Sessão ou Semanal.

## Por dentro

Dois endpoints do ollama.com, os dois autenticados com uma assinatura digital feita pela sua chave local do Ollama:

- `GET https://ollama.com/api/usage`: os medidores de sessão, semanal e mensal, mais o gasto da atividade recente.
- `POST https://ollama.com/api/me`: o nome do plano (opcional; uma falha aqui não apaga os medidores).

Cada pedido leva um header `Authorization` no formato `<public key>:<signature>`, assinando o texto `<METHOD>,<request-uri>`, em que a URI inclui um parâmetro `ts` em segundos Unix. É o mesmo esquema que a CLI do Ollama usa, então um header capturado não pode ser reaproveitado depois.

O endpoint de uso não é documentado (é ele que alimenta a página de ajustes do próprio Ollama), então o Meu Uso lê a resposta com cuidado: `usage` é uma fração (`0.349` → 34,9%) e `cost` é um texto decimal. Um limite que não vem na resposta fica de fora da API local e aparece como "Sem dados" se a linha dele estiver ativada no painel, em vez de aparecer como uso zero. Uma resposta sem nenhum `limits` é tratada como resposta inválida.

## Solução de problemas

- **"Nenhuma chave do Ollama encontrada"**: o Ollama nunca rodou neste Mac. [Instale-o](https://ollama.com/download) e rode `ollama signin`.
- **"Nenhum login no Ollama Cloud encontrado"**: o Ollama está instalado, mas a chave não está ligada a uma conta. Rode `ollama signin`.
- **"Não foi possível ler ~/.ollama/id_ed25519"**: o arquivo da chave existe, mas não pode ser lido. Confira as permissões (o dono deve ser você, com modo `600`).
- **"Não foi possível ler seu plano do Ollama"** (aviso âmbar ao lado do nome): o plano sumiu porque o Ollama não respondeu a esse pedido ou respondeu algo que o Meu Uso não conseguiu ler. Os seus medidores não são afetados e continuam em dia. O plano volta sozinho quando o Ollama responder normalmente.
- **Os medidores mostram "Sem dados de uso"**: você entrou, mas o Ollama ainda não devolveu nenhum limite para a conta. Confira o seu uso em [ollama.com/settings](https://ollama.com/settings).
