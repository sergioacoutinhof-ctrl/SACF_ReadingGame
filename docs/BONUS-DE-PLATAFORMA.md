# Bônus de plataforma — v0.4.1

Cada palavra completa libera até 15 segundos de corrida automática. Um toque em qualquer lugar faz pular. As letras da mesma palavra aparecem em ordem no cenário, inclusive letras repetidas e acentuadas; a criança precisa saltar para coletá-las. Cada coleta fala a letra e toca um som, explode partículas em forma de estrela e acende a letra correspondente no painel.

Há até três buracos, visíveis antes da aproximação. Cair encerra a tentativa do bônus. Se todas as letras forem coletadas até o final, o jogo comemora a palavra completa; se faltar alguma, encerra a tentativa sem a vitória. Um resultado breve antecede a próxima palavra. A palavra que já foi formada na corrida de leitura continua concluída, e a queda não altera os registros de leitura.

O responsável pode desligar buracos e quedas na área protegida por PIN. O salto continua sendo necessário para coletar letras. Há tolerância para um toque pouco antes de aterrissar ou logo depois de sair de uma borda, e toques repetidos no ar não causam saltos extras. As animações variam entre os três personagens.

O desenho do curso varia com uma semente, preservando a ordem da grafia. Os testes verificam coleta por salto, vitória, perda por queda, acentos, duração máxima, quadros lentos e a possibilidade de completar palavras curtas e longas. O conforto e o grau de dificuldade precisam ser observados no tablet real.

```text
godot --headless --path game --script res://tests/bonus.gd
godot --headless --path game --script res://tests/smoke.gd
```
