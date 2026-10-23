# Plano de desenvolvimento

## 0. Base do projeto

Criar projeto Godot 2D com dados genéricos, sem dependência de rede. **Concluído quando:** abre no editor e inicia uma cena de demonstração.

## 1. Escolha acessível de letras

Mostrar palavra, imagem, duas pistas, dois alvos grandes, personagem provisório, avanço da palavra, repetição após erro e alternância da resposta correta. **Concluído quando:** uma palavra pode ser completada por toques no desktop e em um tablet Android.

## 2. Teste no tablet real

Observar posição e tamanho úteis dos alvos, tempo de decisão, contraste e clareza do feedback. Ajustar o protótipo antes de detalhar arte e fases. **Concluído quando:** os controles são validados em uma sessão curta com a criança, sem precisar de gestos precisos.

## 3. Conteúdo e áudio

Construir a área de responsáveis, o cadastro de palavras e imagens, gravação de voz, sons de letras, persistência local e exportação/importação de conteúdo entre tablets. **Concluído quando:** um responsável edita uma palavra sem tocar no código e transfere o pacote para outro aparelho.

## 4. Progressão e acompanhamento

Criar pistas decrescentes, dificuldade crescente, revisão de palavras e registro distinto de acerto, escolha incorreta e ausência de resposta. **Concluído quando:** a criança recebe uma palavra com menos pista depois de dominá-la e o responsável consegue consultar os resultados.

## 5. Arte, proteção e distribuição

Substituir gráficos provisórios por personagens e cenários finais; incluir música, volumes ajustáveis, PIN da área de responsáveis, fixação de tela e APK instalável. Separar conteúdo genérico público de pacotes familiares privados. **Concluído quando:** o jogo funciona offline em vários tablets Android e o responsável consegue sair com segurança.

## Depois da primeira versão

Sincronização automática opcional, distribuição pelo domínio ou Google Play e controle por deslize, conforme testes com usuários.

## Participação do responsável

1. Separar um tablet para o primeiro teste e informar o modelo quando possível.
2. Observar se alvos, ritmo e letras funcionam confortavelmente.
3. Separar fotos e gravar vozes para o conteúdo privado, sem enviá-las ao GitHub público.
4. Testar a fixação de tela e guardar os PINs de administração e saída.

Godot é a única ferramenta de criação necessária agora. Blender não é necessário para o protótipo 2D. Android SDK e Java serão configurados quando formos gerar o APK.
