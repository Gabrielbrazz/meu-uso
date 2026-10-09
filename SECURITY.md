# Política de segurança

## Como relatar uma vulnerabilidade

Se encontrar uma falha de segurança no Meu Uso, relate em particular. **Não abra uma issue pública.**

1. Abra a página de [relato privado de vulnerabilidade](https://github.com/Gabrielbrazz/meu-uso/security/advisories/new).
2. Descreva o problema.

O relato fica privado até a correção sair.

## O que incluir

- descrição da vulnerabilidade;
- passos para reproduzir;
- versões afetadas;
- impacto: o que alguém mal-intencionado consegue fazer.

## Prazo de resposta

O projeto é mantido por uma pessoa, então os prazos são de melhor esforço:
- confirmação de recebimento em até 7 dias;
- uma avaliação inicial logo depois.

## Escopo

- **O que conta:** o app Meu Uso e o código deste repositório. Isso inclui a leitura de credenciais dos provedores, a CLI `meu-uso` e a API local em `127.0.0.1:6737`.
- **O que não conta:** falhas nos próprios provedores (Anthropic, OpenAI, GitHub, Cursor etc.). Relate essas a cada um deles.
