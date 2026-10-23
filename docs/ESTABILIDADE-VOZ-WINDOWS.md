# Correção do travamento de voz no Windows

## Problema observado

A janela deixou de responder durante a primeira palavra, depois da primeira letra. O registro do jogo não continha erro de GDScript. O processo continuava aberto, com pouco uso de CPU; o diagnóstico local da thread principal apontava para o reprodutor de mídia do Windows.

O [backend OneCore do Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/tts_driver_onecore.cpp) reproduz a síntese por `Windows.Media.Playback.MediaPlayer` e fecha esse reprodutor ao finalizar ou interromper a fala. Esse caminho correspondia ao componente encontrado no bloqueio. Os testes anteriores de fluxo silenciavam a voz e não cobriam essa integração nativa.

## Mudança

No Windows, `audio/general/text_to_speech.windows=false` evita inicializar esse backend. A fala permanece ativa por outro caminho:

1. Um processo separado do Windows PowerShell gera arquivos PCM WAV usando a voz portuguesa instalada e `System.Speech`.
2. Os arquivos são preparados em segundo plano e publicados somente depois de completos.
3. O jogo reproduz a voz com `AudioStreamPlayer`, como faz com os efeitos e a música.
4. A geração tem limite de 30 segundos. Esperas por uma fala ainda não pronta expiram em 4 segundos, mantendo a tela e os controles ativos.
5. Silenciar ou interromper uma fala para somente o áudio do próprio jogo. Encerrar o aplicativo cancela o processo auxiliar que ele criou.

Nenhum comando de voz é enviado à internet. Textos de conteúdo personalizado e WAVs ficam em `user://speech-cache-v1/`; seus nomes de arquivo usam SHA-256. O código do auxiliar é público, enquanto o cache e os diagnósticos da execução são locais.

O auxiliar recebe textos por JSON, sem interpolá-los como código. O lançamento não altera a política de execução do Windows nem abre console. Ele somente escreve áudio em cache e não usa o reprodutor de mídia que bloqueou.

Android e demais plataformas continuam usando a voz nativa disponível no aparelho. A validação no tablet permanece uma etapa própria.

## Verificação

- `tests/smoke.gd`: fluxo de letras, controles, bônus e retorno.
- `tests/voice_windows.gd`: Windows com janela gráfica e **voz portuguesa real ligada**, incluindo interrupções rápidas, silêncio, uma partida completa, as 12 letras e os três bônus de 15 segundos em tempo real.
- O teste de voz precisa de uma voz portuguesa instalada. Ele verifica a geração e a reprodução dos áudios e não pode passar apenas por desativar a fala.
- O teste deve ser supervisionado externamente, com limite de tempo e observação de resposta da janela. Um bloqueio nativo impediria o próprio script de encerrar.

Comando do teste gráfico:

```text
godot --path game --script res://tests/voice_windows.gd --minimized
```

Para uma exportação Windows, incluir `platform/windows/speech_cache.ps1` nos filtros de arquivos do pacote. O instalador e a exportação ainda não fazem parte desta versão.

Referências de implementação: [processos independentes no Godot](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-create-process) e [síntese para WAV da Microsoft](https://learn.microsoft.com/en-us/dotnet/api/system.speech.synthesis.speechsynthesizer.setoutputtowavefile?view=netframework-4.8.1).
