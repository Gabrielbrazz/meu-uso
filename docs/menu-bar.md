# Barra de menus

Marque com estrela as métricas mais importantes para elas aparecerem direto na barra de menus.

## Clique com o botão direito no ícone

Clique com o botão direito (ou com a tecla Control pressionada) no ícone da barra de menus para abrir um menu rápido com **Ajustes** e **Encerrar o Meu Uso**. O clique normal abre a janela do app, como sempre.

## Estrelas

Marque uma métrica com estrela pelo menu do clique com o botão direito em qualquer linha (**Adicionar à barra de menus**) ou pela estrela que fica sempre visível ao lado de cada métrica em Personalizar.

- Na primeira abertura, o app já vem com algumas estrelas, para a barra mostrar números logo de cara: Sessão e Semanal no Antigravity, no Claude, no Codex, no Ollama e no Z.ai; Modelos do Cursor e Outros modelos no Cursor; Créditos no Copilot e no OpenRouter. Mude quando quiser: o **Redefinir** de um provedor restaura as estrelas padrão dele, e **Redefinir toda a personalização** restaura o conjunto inteiro. Só os provedores ativados aparecem na barra, e uma instalação nova começa só com os provedores encontrados no seu Mac (veja [Painel § Primeira abertura](dashboard.md#primeira-abertura)). Assim as estrelas padrão não enchem a barra de menus com ferramentas que você não usa.
- No máximo **2 estrelas por provedor**.
- Quando uma estrela não é permitida, o botão da estrela continua clicável: ao clicar, ele balança e mostra o motivo num aviso temporário na parte de baixo de Personalizar (por exemplo, "Até 2 estrelas por provedor").

## Estilos

**Ajustes → Aparência → Estilo do ícone**:

- **Texto**: o ícone do provedor e os valores. Duas métricas com estrela do mesmo provedor aparecem empilhadas, uma sobre a outra, sem rótulo.
- **Barras**: um ícone compacto com as quatro primeiras métricas com estrela que têm limite (métricas sem limite só aparecem no estilo Texto).

## Ocultar o uso ao compartilhar a tela

**Ajustes → Privacidade → Ocultar ao compartilhar a tela** (vem desativado). Enquanto sua tela está sendo compartilhada ou gravada (no Zoom, no Meet ou no Teams, numa gravação de tela ou pelo Compartilhamento de Tela do macOS), a barra troca os números pelo ícone e pelo nome do Meu Uso. Assim, contagens de tokens e gastos nunca aparecem para quem está assistindo. Quando a captura termina, suas métricas com estrela voltam na hora. Capturas que você mesmo inicia (uma gravação de tela, por exemplo) também contam e mostram o nome no lugar dos números.

A detecção usa o próprio aviso do sistema de que "um app está capturando a tela", o mesmo que acende o indicador de captura na barra de menus. Ela confere esse aviso no instante em que ele muda e de novo a cada poucos segundos enquanto o ajuste está ativado.

## O que a barra mostra

A barra só mostra dados reais. Uma métrica com estrela que ainda não foi buscada fica de fora; um provedor cujas estrelas estão todas sem dados some por completo (inclusive o ícone). Quando nada tem dados, a barra volta a mostrar só o ícone do app. As estrelas seguem a ordem de Personalizar: primeiro as métricas de Sempre visível, depois as de Sob demanda. Uma métrica pode ter estrela tanto em Sempre visível quanto em Sob demanda.
