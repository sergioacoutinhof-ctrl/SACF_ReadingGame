extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.words.size() == 3, "O pacote genérico deve carregar três palavras.")
	game._start_session()
	assert(game.mode == game.PLAY)
	assert(game.options[0] != game.options[1], "As alternativas precisam ser distintas.")
	assert(game.options[game.correct_lane] == "B", "A primeira letra de BOLA é B.")
	game._choose(1 - game.correct_lane)
	game._finish_choice()
	assert(game.letter_index == 0, "Um erro deve repetir somente a letra atual.")
	game._choose(game.correct_lane)
	game._finish_choice()
	assert(game.letter_index == 1, "Um acerto deve avançar exatamente uma letra.")
	assert(game.options[0] != game.options[1])
	for index in range(1, 4):
		game._choose(game.correct_lane)
		game._finish_choice()
	assert(game.mode == game.WORD_DONE, "A palavra completa deve encerrar a rodada.")
	print("SMOKE_OK: conteúdo, erro, acerto e palavra completa")
	quit()
