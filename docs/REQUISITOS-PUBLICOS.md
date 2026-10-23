# Jogo de Leitura — requisitos públicos (v0.3)

Este documento descreve o produto sem dados pessoais. Perfis, fotografias, gravações e palavras particulares de cada família são conteúdo privado configurado no aparelho.

## Objetivo

Criar um jogo de alfabetização para tablets Android em que a criança pratica a ordem das letras e a associação entre letra e som ao completar palavras. O jogo deve permitir personalização por responsáveis e oferecer controles acessíveis, com alvos grandes e ritmo ajustável.

## Ciclo principal

1. A criança escolhe um de três personagens ilustrados.
2. Uma imagem e uma voz apresentam a palavra a formar. Nas fases iniciais, a palavra completa aparece como pista.
3. O cenário se move como uma corrida vertical, com a pista vindo de cima para baixo e a tela em paisagem. Duas letras aparecem em pistas distintas: uma é a próxima letra correta e a outra é uma alternativa.
4. A criança toca em qualquer altura da metade esquerda ou direita da tela, com cores distintas e uma linha central neutra. O personagem se desloca para a pista escolhida e coleta a letra.
5. A aproximação desacelera para permitir a escolha. Se não houver toque, a mesma etapa reaparece sem penalidade.
6. Um acerto acrescenta a letra à palavra em construção, oferece feedback visual breve e reproduz o som da letra.
7. Ao terminar a palavra, o jogo mostra a grafia completa, pronuncia a palavra e faz uma comemoração curta.
8. Cada palavra completa libera uma corrida bônus de plataforma por 15 segundos. O personagem corre sozinho, e um toque em qualquer lugar comanda um salto. Estrelas extras e animações diferentes dos três personagens celebram o acerto.
9. Depois do bônus, o jogo volta automaticamente à próxima palavra. A última palavra também concede o bônus antes de terminar a partida, com opção de iniciar outra.

Exemplo genérico: para `BOLA`, o painel começa em `_ _ _ _`. A primeira escolha pode ser `B` ou `P`. Após escolher `B`, o painel mostra `B _ _ _`.

## Progressão pedagógica

- Começar por palavras curtas, concretas e familiares; incluir nomes próprios cadastrados somente em perfis privados.
- Começar com letras maiúsculas e introduzir minúsculas em uma fase posterior.
- Mostrar a palavra alvo como pista no início e retirar a pista gradualmente conforme acertos consistentes.
- Reapresentar ocasionalmente palavras dominadas, misturadas a palavras novas.
- Variar posição e alternativas; não repetir sempre a mesma sequência.
- Usar alternativas fáceis no começo e mais parecidas apenas quando a fase justificar.
- Avançar automaticamente com base no desempenho, com controle manual de fase pelo responsável.
- Nas primeiras fases, uma escolha incorreta repete a letra atual com feedback acolhedor. O reinício da palavra pode ser habilitado para fases posteriores.
- Ausência de resposta não deve ser confundida com escolha incorreta.
- O bônus é uma recompensa sem vidas, buracos ou penalidade por não coletar estrelas. Não exige pontuação mínima, nem altera os acertos ou erros de leitura.
- Registrar acertos, escolhas incorretas, ausência de resposta e nível de pista para acompanhamento do responsável.

## Acessibilidade

- Duas metades completas da tela como áreas de toque, com delimitação visual clara. Ajustes de tamanho e posição serão disponibilizados ao responsável.
- Nenhuma ação essencial do primeiro protótipo depende de arrastar, pinçar, pressionar longamente, tocar duas vezes ou acertar alvos pequenos.
- Velocidade da cena, desaceleração e janela de escolha ajustáveis.
- Texto grande, contraste forte e animações que não escondam as alternativas.
- Música, voz e efeitos com controles de volume independentes; redução de efeitos visuais disponível.
- A borda entre os dois alvos não deve transformar um toque ambíguo em resposta incorreta.
- No bônus, toda a tela aceita o comando de pulo. Uma janela breve aproveita toques perto da aterrissagem, e toques repetidos no ar não provocam saltos extras.
- O layout deve se adaptar a vários tamanhos de tablet Android e ser validado em aparelhos reais.

## Conteúdo e privacidade

- O aplicativo público inclui palavras e ilustrações genéricas.
- O responsável pode adicionar, editar, ocultar e excluir palavras; trocar ilustrações por fotos; e gravar áudio opcional.
- Uma voz automática serve de alternativa quando não houver gravação.
- Fotografias, gravações e perfis privados ficam no armazenamento do aparelho e não fazem parte do repositório público nem do pacote geral do aplicativo.
- Importar e exportar pacotes de conteúdo entre aparelhos, sem exigir internet.
- O progresso fica local em cada aparelho na primeira versão.
- Sincronização automática e distribuição por loja de aplicativos são possibilidades futuras.

## Acesso dos responsáveis e instalação

- A área de configurações é aberta por um comando discreto e protegida por PIN próprio.
- A primeira instalação usa a fixação de tela disponibilizada pelo Android e protegida pelo PIN do aparelho. Uma configuração mais restritiva de dispositivo dedicado será avaliada se necessário.
- A primeira distribuição é direta para tablets da família. O jogo deve funcionar durante a partida sem conexão.
- A forma de instalação e a saída de emergência devem ser testadas em cada modelo de tablet.

## Critérios de aceitação do primeiro protótipo

1. A escolha de personagem e as duas escolhas de letra funcionam por toques em alvos grandes.
2. Cada etapa oferece duas letras distintas, uma correta, com posições variáveis.
3. Um acerto preenche a próxima posição e reproduz o som correspondente.
4. Um erro inicial repete a letra atual; não responder oferece nova oportunidade sem registrar erro.
5. A palavra completa é mostrada e pronunciada ao final.
6. O responsável consegue substituir a imagem de uma palavra e associar uma gravação sem editar código.
7. Uma partida funciona com a internet desligada.
8. Um pacote exportado de um tablet pode ser importado em outro.
9. Alvos, ritmo e áudio podem ser ajustados em um aparelho real.
10. Toda palavra completa oferece exatamente 15 segundos de corrida bônus, com movimento próprio do personagem selecionado e retorno automático às letras ou ao encerramento.

## Fora do primeiro protótipo

- Publicação em loja de aplicativos.
- Sincronização automática pela internet.
- Jogo 3D ou modelos criados em Blender.
- Garantia de resultado pedagógico sem observação e ajuste com responsáveis e educadores.


