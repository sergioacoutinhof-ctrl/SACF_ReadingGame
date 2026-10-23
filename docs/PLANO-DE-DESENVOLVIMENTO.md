# Plano de desenvolvimento

## 0. Base do projeto

Criar projeto Godot 2D com dados genéricos, sem dependência de rede. **Concluído quando:** abre no editor e inicia uma cena de demonstração.

## 1. Escolha acessível de letras

Mostrar palavra, imagem, duas pistas verticais, duas metades completas de toque e personagem ilustrado, avanço da palavra, repetição após erro e alternância da resposta correta. **Concluído quando:** uma palavra pode ser completada por toques no desktop e em um tablet Android.

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

Godot é a única ferramenta de criação necessária agora. Blender não é necessário para o protótipo 2D. Android SDK e Java já foram configurados para gerar o primeiro APK de teste.


## Atualização da versão 0.2

Corrida vertical, toque nas metades completas, personagens e cenário novos, música, efeitos de acerto, salto e estrelas implementados e verificados no computador. As etapas de validação no tablet, conteúdo personalizado, fonemas, redução de efeitos e volumes independentes continuam pendentes.


## Atualização da versão 0.3

Bônus de plataforma de 15 segundos após cada palavra, inclusive a última. Corrida automática, salto com toque em toda a tela, plataformas baixas, estrelas extras e três perfis de animação. O retorno às letras é automático. Temporização, aterrissagem, tolerância de toque e fluxo completo verificados no computador; ritmo e conforto dos saltos ainda devem ser observados no tablet.

## Atualização da versão 0.3.2

APK de teste Android exportado e assinado, com ARM de 32 e 64 bits e perfis genérico/personalizado. Ferramentas de exportação instaladas no computador. Conferência do pacote feita antes da entrega; instalação, fluidez e voz no tablet real aguardam o primeiro teste.

## Atualização da versão 0.4

Catálogo público com 42 palavras e ilustrações, pacote particular de palavras, rodadas de seis palavras, cadastro de fotos e edição de palavras no aparelho. PIN criado pelo responsável protege configurações e saída. Integração com fixação nativa do Android e instruções para exigir a senha ao desafixar; validação dos gestos no tablet real continua necessária. Bônus atualizado com letras da mesma palavra, buracos, quedas, vitória e opção de desligar os buracos.
