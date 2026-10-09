# Proxy

O Meu Uso pode mandar todas as requisições aos provedores por um proxy, se você quiser.

- Suporta: `socks5://`, `http://`, `https://`
- Arquivo de configuração: `~/.meu-uso/config.json`
- Padrão: desativado
- Interface: nenhuma, só o arquivo

## Arquivo de configuração

```json
{
  "proxy": {
    "enabled": true,
    "url": "socks5://127.0.0.1:10808"
  }
}
```

Para um proxy com autenticação, coloque as credenciais na URL:

```json
{
  "proxy": {
    "enabled": true,
    "url": "http://user:pass@proxy.example.com:8080"
  }
}
```

Se a URL não tiver porta, vale a porta padrão do esquema (socks5 → 1080, http → 80, https → 443).

## Comportamento

- O arquivo é lido uma vez, quando o app abre. **Reinicie o Meu Uso depois de mudar o arquivo.** O comando `meu-uso` lê o arquivo a cada execução.
- `localhost`, `127.0.0.1` e `::1` nunca passam pelo proxy (a [API HTTP local](local-http-api.md) não é afetada).
- Se o arquivo não existir, não puder ser lido, for inválido ou estiver com `"enabled": false`, o proxy simplesmente fica desligado.

## Alcance

Vale para as requisições HTTP que o app faz aos provedores, inclusive a atualização dos [preços dos modelos](pricing.md), que acontece a cada hora. Não é um proxy do sistema todo: a busca de atualizações (Sparkle) e o iCloud não passam por ele.
