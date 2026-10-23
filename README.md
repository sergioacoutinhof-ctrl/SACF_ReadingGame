# Jogo de Leitura

Protótipo público de um jogo de alfabetização para tablets Android. A criança escolhe um personagem e completa palavras escolhendo uma entre duas letras com alvos de toque grandes. A versão atual usa palavras e ilustrações genéricas e não contém dados de nenhuma família.

## Estado

- **Etapa 0/1 em andamento:** protótipo 2D de escolha de letras.
- Requisitos: [docs/REQUISITOS-PUBLICOS.md](docs/REQUISITOS-PUBLICOS.md).
- Passos de desenvolvimento: [docs/PLANO-DE-DESENVOLVIMENTO.md](docs/PLANO-DE-DESENVOLVIMENTO.md).
- O editor de conteúdo, a gravação de voz, a progressão adaptativa, os personagens finais e o instalador Android ainda serão construídos.

## Abrir o protótipo

1. Baixe [Godot 4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/) ou uma versão estável compatível da série 4.7. Não é necessário usar a edição .NET.
2. No Godot, escolha **Importar** e selecione `game/project.godot`.
3. Execute a cena principal com **F6** ou o projeto com **F5**.
4. Em computador, clique nos alvos com o mouse; em tablet, toque nas áreas grandes.

O protótipo pode ser validado no computador antes de configurar a exportação para Android. A [documentação oficial de exportação](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) descreve os componentes de Android SDK e Java necessários para gerar um APK no Windows.

## Privacidade

Fotos, gravações, nomes particulares, PINs e chaves de assinatura não devem ser commitados neste repositório público. O conteúdo personalizado ficará no armazenamento local do aplicativo e poderá ser exportado pelo responsável quando esse recurso estiver pronto.
