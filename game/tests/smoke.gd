extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.voice_id = ""
	game.set_process(false)
	game.sound.toggle_mute()
	assert(game.words.size() == 3)
	assert(game.sprites.size() == 3)
	for sprite in game.sprites:
		assert(sprite.get_width() > 0 and sprite.get_height() > 0)
	# Mouse e toque: cantos, cabeçalho, centro e margem inferior são alvos.
	var viewport_size := root.get_visible_rect().size
	for touch in [false, true]:
		for point in [Vector2(2, 2), Vector2(2, viewport_size.y - 2),
				Vector2(viewport_size.x - 2, 2), viewport_size - Vector2(2, 2),
				viewport_size / 2.0]:
			game._start_session()
			var event: InputEvent
			if touch:
				event = InputEventScreenTouch.new()
			else:
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			event.position = point
			game._input(event)
			var expected := 0 if point.x < viewport_size.x / 2.0 else 1
			assert(game.selected_lane == (-1 if point.x == viewport_size.x / 2.0 else expected), "As metades respondem; a linha central evita escolhas ambíguas.")
			var stars: int = game.star_count
			game._input(event)
			assert(game.star_count == stars, "Toques repetidos não devem avançar durante a animação.")
	game._start_session()
	assert(game.options[0] != game.options[1])
	assert(game.options[game.correct_lane] == "B")
	var start_y: float = game._letter_y()
	game.pair_age = 2.8
	assert(game._letter_y() > start_y, "As letras devem descer verticalmente.")
	game._process(9.1)
	assert(game.no_response_count == 1)
	assert(game.wrong_choice_count == 0 and game.letter_index == 0)
	game._choose(1 - game.correct_lane)
	game._finish_choice()
	assert(game.letter_index == 0 and game.star_count == 0)
	game._choose(game.correct_lane)
	assert(game.particles.size() > 0, "O acerto deve gerar partículas.")
	assert(game.sound.collect.get_length() > 0.0)
	game._finish_choice()
	assert(game.letter_index == 1 and game.star_count == 1)
	for index in range(1, 4):
		game._choose(game.correct_lane)
		game._finish_choice()
	assert(game.mode == game.WORD_DONE and game.star_count == 4)
	assert(game.sound.complete.get_length() > game.sound.collect.get_length())
	game._process(3.3)
	assert(game.mode == game.PLAY and game.word_index == 1)
	assert(game.letter_index == 0)
	game.free()
	await process_frame
	print("SMOKE_OK: metades completas, mouse/toque, proteção contra repetição, corrida vertical, áudio, partículas e progressão")
	quit()
