# Arte e áudio da versão 0.2

## Arquivos

- `game/assets/art/friends.png`: atlas transparente com princesa, ursinho e cavaleiro.
- `game/assets/art/meadow.png`: cenário de jardim e castelo.
- `game/assets/audio/collect.wav`: três notas ascendentes ao coletar.
- `game/assets/audio/complete.wav`: pequena frase musical ao completar a palavra.
- `game/assets/audio/bonus.wav`: trilha original mais animada para a corrida de prêmio.
- `game/assets/audio/jump.wav`: pequeno efeito ascendente ao saltar no bônus.
- `game/assets/audio/retry.wav`: indicação suave de nova tentativa.
- `game/assets/audio/meadow.wav`: trilha suave de doze segundos.
- `game/assets/fonts/Fredoka.ttf`: fonte Fredoka, distribuída com a [SIL Open Font License](../game/assets/fonts/OFL.txt), obtida do [repositório oficial Google Fonts](https://github.com/google/fonts/tree/main/ofl/fredoka).

As duas imagens foram criadas com a ferramenta integrada **image_gen**, sem API ou chave externa. O atlas conserva seu canal alfa; as regiões de cada personagem são usadas diretamente pelo jogo. Os efeitos sonoros e a música são síntese original reproduzível por `python tools/make_audio.py`, usando apenas a biblioteca padrão do Python. Não há áudio externo ou dependência de internet durante a partida.

## Prompt final dos personagens

```text
Use case: stylized-concept. Asset type: transparent character atlas for a polished children's literacy game. Create a wide 1536x1024 transparent PNG containing exactly THREE separate full-body cute friendly characters in a single horizontal row, one character strictly within each equal vertical third. Left: smiling little storybook princess, lavender and rose dress, small gold crown, warm brown hair, light brown skin. Center: adorable caramel teddy bear, teal scarf, cream muzzle and belly. Right: smiling child storybook knight, blue silver rounded armor, teal cape, helmet open showing warm face, NO weapon. Premium soft sculpted 3D animated-family-film game render, rounded appealing proportions, large expressive kind eyes, tiny hands and feet, beautiful soft lighting, subtle fabric detail, rich cheerful colors. All three face the viewer, slightly dynamic cheerful standing pose, same scale, each centered x=256,768,1280 and feet at y=910, tops around y=170. Clean silhouettes with generous empty gutters between them and padding on all sides. True transparent background, no ground, no shadows on a background, no panels, no text, no letters, no logo, no scenery. Full character bodies wholly visible; no overlap across the thirds. These are sprites for direct runtime atlas rendering.
```

Parâmetro: `transparent_background=true`.

## Prompt final do cenário

```text
Use case: illustration-story. Asset type: landscape background plate for a children's literacy runner game, 1536x1024 landscape. Make a beautiful polished cozy storybook fantasy meadow, soft dimensional 3D toy-like illustration, gentle daylight and luminous mint teal turquoise palette, lavender and peach flowers, friendly rounded trees, whimsical distant pastel castle on a little hill upper right, soft white clouds, warm inviting magical atmosphere. Composition for game overlay: large clear EMPTY central area (middle 60 percent of image, especially lower half) of very simple pale mint grassy meadow with little detail, so a wide two lane road and large letter cards will be drawn by the game over it. Rich charming lush scenery along outer left and right edges, with rounded bushes, daisy flowers and smooth stones. Horizon around upper third. A few fluffy distant trees and hills upper edge, softly blurred depth, tasteful subtle sparkle light. No path or road, no characters, no text, no UI, no letters, no signage, no logos. Full bleed painterly 3D storybook background, cohesive premium mobile game art, avoid flat vector or harsh outlines. Child friendly, cheerful and calm enough that letters remain legible.
```

Parâmetro: `transparent_background=false`.

## Comportamento visual e sonoro

A próxima letra fica em uma posição dourada no painel superior; as letras coletadas ficam verdes e recebem uma marca. A escolha desloca o personagem para a faixa, com salto, estrelas e um som breve no acerto. A música fica em volume inferior aos efeitos e à voz. A tecla M silencia música, efeitos e voz; controles separados no painel de responsáveis serão implementados em etapa posterior.

A voz automática do protótipo ainda lê o nome da letra. O som fonêmico validado para alfabetização depende da etapa de gravação e conteúdo.


## Animações e áudio do bônus (v0.3)

A corrida usa uma malha simples sobre o mesmo atlas: passos alternados, inclinação e salto. O ursinho tem passadas saltitantes e poeirinha; a princesa tem movimento mais leve de saia e brilho; o cavaleiro tem passos curtos e firmes com rastros de velocidade. O rosto e os traços do pacote local são preservados. Durante os 15 segundos, uma trilha original mais animada substitui a música suave; ao voltar às letras, a trilha habitual retorna.
