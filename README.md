# Aventura das Letras

Jogo de alfabetização 2D para tablets Android. A criança escolhe uma princesa, um ursinho ou um cavaleiro e completa palavras coletando a próxima letra em uma corrida vertical.

![Corrida vertical com duas metades de toque](docs/images/vertical-runner.png)

## Versão atual

- Pista em perspectiva, com movimento de cima para baixo.
- Toda a metade esquerda ou direita responde ao toque, incluindo o cabeçalho e as margens; a linha central tem uma pequena faixa neutra para evitar erros ambíguos.
- Letras grandes, palavra completa como pista e marcação das letras já coletadas.
- Personagens e cenário ilustrados, salto ao coletar, estrelas, partículas e comemoração de palavra completa.
- Trilha suave e efeitos musicais originais, reproduzidos offline.
- Ao completar cada palavra, corrida bônus de até 15 segundos com letras da mesma palavra, buracos, salto por toque em qualquer lugar e explosões de estrelinhas. Cair encerra a tentativa; buracos podem ser desligados pelo responsável. Depois, retorno automático às letras.
- Passos e pulos com movimentos diferentes para ursinho, princesa e cavaleiro, inclusive nos pacotes locais.
- No bônus, cada letra coletada é falada; coletas próximas entram em fila.
- Para pausar ou sair, segure **PAIS / SAIR** por 1,2 segundo com um dedo e digite o PIN. O menu oferece continuar, configurar ou sair.
- Um toque é aceito por animação; não responder oferece outra oportunidade sem registrar erro.
- Catálogo público com 42 palavras e ilustrações; pacote privado pode acrescentar nomes da família.
- Rodadas de seis palavras, com avanço pelo catálogo.
- Área dos responsáveis com PIN de seis dígitos, edição de palavras e troca de ilustrações por fotos locais.
- Pedido de fixação nativa no Android, com orientação para exigir a senha do tablet ao desafixar.

No Windows, a voz é preparada como áudio local em segundo plano e reproduzida pelo jogo, evitando o bloqueio do reprodutor de voz do sistema.

Gravações de fonemas, progressão adaptativa, volumes separados, redução de efeitos e importação/exportação de perfis continuam nas próximas etapas. A versão 0.4.1 já permite editar palavras e fotos e exportar o APK de teste.

## Abrir no computador

1. Importe `game/project.godot` no [Godot 4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/).
2. Execute com **F5**. Na primeira abertura, crie e confirme o PIN de seis números.
3. Escolha um personagem. Durante a corrida, clique ou toque em qualquer altura da metade correspondente à letra.
4. No bônus, toque em qualquer lugar para pular; a barra indica o tempo até a próxima palavra. No computador, a barra de espaço também pula.
5. A tecla **M** liga ou desliga o áudio completo no computador. **Esc** abre o pedido de PIN; a saída fica na área dos responsáveis.

A direção da corrida é vertical; a tela continua em formato paisagem para deixar as duas áreas amplas. A validação de alcance e ritmo no tablet real ainda está pendente.

## Instalar no tablet

Veja o [passo a passo de instalação e exportação Android](docs/INSTALAR-NO-ANDROID.md). Há perfis separados para os personagens genéricos e para o pacote local personalizado. A primeira exportação contém ARM de 32 e 64 bits; a validação no aparelho real continua pendente.

## Documentos e verificação

- [Fluxo de entrada, pausa e saída](docs/FLUXO-ENTRADA-E-SAIDA.md)
- [Palavras, fotos e PIN](docs/PALAVRAS-FOTOS-E-PIN.md)
- [Requisitos públicos](docs/REQUISITOS-PUBLICOS.md)
- [Plano de desenvolvimento](docs/PLANO-DE-DESENVOLVIMENTO.md)
- [Arte, prompts, áudio e licença da fonte](docs/ARTE-E-AUDIO.md)
- [Pacotes locais de personagens](docs/PERSONAGENS-LOCAIS.md)
- [Corrida bônus de plataforma](docs/BONUS-DE-PLATAFORMA.md)
- [Correção de estabilidade da voz no Windows](docs/ESTABILIDADE-VOZ-WINDOWS.md)

Teste de lógica e acessibilidade no Godot:

```text
godot --headless --path game --script res://tests/smoke.gd
godot --headless --path game --script res://tests/bonus.gd
godot --headless --path game --script res://tests/family_and_parent.gd
```

Capturas reais de seleção, letras, coleta, conclusão, bônus dos três personagens e retorno às letras, com janela gráfica. Use um destino fora de game/ para evitar importar as capturas como recursos:

```text
godot --path game --script res://tests/visual_preview.gd -- --output-dir=CAMINHO_ABSOLUTO
# Para documentação pública, usar sempre os personagens genéricos:
godot --path game --script res://tests/visual_preview.gd -- --output-dir=CAMINHO_ABSOLUTO --generic-characters
```

## Privacidade

Fotos, gravações, nomes particulares, PINs e chaves de assinatura ficam fora do repositório público. O conteúdo personalizado será salvo no armazenamento local do aplicativo.
