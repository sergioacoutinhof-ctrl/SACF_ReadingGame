# Instalar e testar no Android

## Instalação no tablet

O arquivo `Aventura-das-Letras-teste.apk` é o instalador. O tablet não precisa ter Godot, Java nem ferramentas de desenvolvimento.

1. Copie o APK para o tablet por cabo USB ou baixe pelo seu Google Drive particular.
2. Abra o arquivo no aplicativo Arquivos/Downloads.
3. Se o Android pedir, abra as configurações indicadas e permita instalar aplicativos dessa fonte. Volte ao instalador.
4. Toque em **Instalar** e depois em **Abrir**.
5. Use o tablet deitado. Escolha um personagem e toque em qualquer altura da metade esquerda ou direita. No bônus, qualquer toque pula.

O nome e a posição da opção de instalação variam conforme a versão do Android e o aplicativo usado para abrir o arquivo. A autorização é para essa fonte específica nas versões recentes do Android. [Orientação oficial do Android](https://developer.android.com/studio/publish#publishing-unknown).

Esta versão inclui os dados do jogo e as músicas no próprio APK. A narração depende de uma voz em português disponível no serviço de síntese de fala do tablet. Se houver música, mas não fala, confira a saída de texto para voz nas configurações de idioma/acessibilidade; para uso sem rede, instale os dados de voz em português quando o serviço oferecer essa opção.

## Primeiro teste

- Conferir seleção dos três personagens e os toques nas duas metades, incluindo as bordas.
- Completar uma palavra e observar o bônus de 15 segundos e o retorno automático.
- Observar música, voz, fluidez e tempo confortável para escolher letras.
- Se não instalar, anotar a mensagem e consultar **Configurações > Sobre o tablet** para obter modelo e versão do Android.

O APK 0.3.2 contém ARM de 32 e 64 bits, usa OpenGL Compatibility, mantém a tela em paisagem e declara Android API 24 como mínimo. Isso amplia a cobertura; a execução precisa ser confirmada no aparelho real. O protótipo ainda não implementa PIN nem bloqueio de saída. A fixação de aplicativo, quando disponível, é uma configuração do próprio Android.

## Exportar novamente no computador

Ferramentas usadas: Godot Standard 4.7.2, modelos Android da mesma versão, OpenJDK 17, Android Build-Tools 35.0.1 e Platform-Tools. Os caminhos Java SDK e Android SDK ficam nas preferências locais do editor. [Guia oficial do Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

`game/export_presets.cfg` oferece dois perfis:

- **Android - Generico:** personagens públicos, sem o diretório `private/`.
- **Android - Personalizado:** acrescenta o atlas de personagens locais e `private/characters/pack.json`, quando presentes. Verifique o conteúdo de `game/private/` antes de exportar. Fotos originais e arquivos auxiliares não devem ficar ali como recursos importáveis.

Ambos exportam todos os recursos do jogo para incluir também dependências carregadas por scripts. O JSON das palavras entra por filtro explícito. Testes e o auxiliar de voz exclusivo do Windows são excluídos.

```powershell
& $Godot --headless --path game --export-debug 'Android - Generico' $DestinoAPK
& $Godot --headless --path game --export-debug 'Android - Personalizado' $DestinoAPK
```

As variáveis representam o executável do Godot e um caminho absoluto para o APK. Crie a pasta de destino antes de exportar. A assinatura usa a chave de depuração das preferências locais, que deve ser preservada para futuras atualizações. Nenhuma chave ou senha particular fica no repositório.

Verificações feitas no primeiro APK: integridade ZIP, assinatura APK v2/v3, alinhamento de bibliotecas para páginas de 16 KB, manifesto, arquiteturas e presença dos recursos de jogo e do pacote local. Não há permissão de internet, câmera ou microfone. A instalação e o desempenho no tablet ficam para o teste físico.

O APK personalizado contém ilustrações familiares: mantenha sua distribuição privada. O arquivo de instalação e os recursos locais não são enviados ao GitHub público.
