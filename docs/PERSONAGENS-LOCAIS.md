# Pacote local de personagens

O jogo usa os três personagens genéricos quando nenhum pacote local está instalado. Um pacote opcional troca imagens, nomes, papéis e ordem dos três personagens, sem alterar os controles da corrida.

## Instalação local

Coloque um atlas PNG transparente e um arquivo `pack.json` em um destes diretórios:

1. `user://characters/` (armazenamento local do aplicativo, prioridade maior).
2. `game/private/characters/` (pacote local de desenvolvimento).

O diretório `private/` já está ignorado pelo Git. Imagens de referência, personagens baseados em pessoas, nomes personalizados, prompts privados e capturas da versão personalizada devem permanecer nesse diretório ou no armazenamento local. A documentação e as capturas públicas continuam usando o conjunto genérico.

## Formato

```json
{
  "version": 1,
  "atlas": "friends.png",
  "characters": [
    {"name": "Ursinho", "role": "bear", "region": [0, 0, 512, 1024]},
    {"name": "Princesa", "role": "princess", "region": [512, 0, 512, 1024]},
    {"name": "Cavaleiro", "role": "knight", "region": [1024, 0, 512, 1024]}
  ]
}
```

Cada `region` é `[x, y, largura, altura]`, em pixels do atlas. As três entradas definem a ordem de seleção da esquerda para a direita. O papel define a cor do cartão. As regiões devem estar dentro da imagem, sem incluir pixels de personagens vizinhos.

A troca só ocorre após validar as três entradas. Pacotes ausentes ou inválidos mantêm o conjunto genérico. O pacote não muda o progresso de leitura nem as áreas de toque.

Para gerar capturas da versão personalizada, use um destino privado com o script de prévia. Não substitua capturas públicas com imagens da família.
