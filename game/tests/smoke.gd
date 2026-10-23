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
	assert(game.content.entries.size() >= 42 and game.words.size() == 6)
	game.content.profile_path = "user://tests/smoke-%d.json" % OS.get_process_id()
	game.content.entries.assign([{"word": "BOLA", "image": "ball", "enabled": true}, {"word": "CASA", "image": "house", "enabled": true}, {"word": "PATO", "image": "duck", "enabled": true}])
	game.content.cursor = 0
	game.content.holes_enabled = false
	game.words = game.content.session_words()
	assert(game.sprites.size() == 3)
	assert(game.character_names.size() == 3 and game.character_roles.size() == 3)
	var original_sprites = game.sprites.duplicate()
	var original_names = game.character_names.duplicate()
	var original_roles = game.character_roles.duplicate()
	assert(not game._apply_character_pack({"characters": []}, game.FRIENDS))
	assert(game.character_names == original_names, "Um pacote incompleto não pode substituir os personagens.")
	var pack := {"characters": [
		{"name": "Hero 1", "role": "bear", "region": [559, 202, 441, 731]},
		{"name": "Hero 2", "role": "princess", "region": [17, 96, 511, 845]},
		{"name": "Hero 3", "role": "knight", "region": [1040, 82, 479, 860]}]}
	assert(game._apply_character_pack(pack, game.FRIENDS))
	assert(game.character_roles == ["bear", "princess", "knight"])
	assert(game.character_names == ["Hero 1", "Hero 2", "Hero 3"])
	pack["characters"][1]["region"] = [-10, 0, 100, 100]
	assert(not game._apply_character_pack(pack, game.FRIENDS))
	assert(game.character_names == ["Hero 1", "Hero 2", "Hero 3"], "Falha de validação não pode aplicar uma troca parcial.")
	game._load_default_characters()
	assert(game.character_names == ["Princesa", "Ursinho", "Cavaleiro"])
	game.sprites = original_sprites
	game.character_names = original_names
	game.character_roles = original_roles
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
	var errors_before_bonus: int = game.wrong_choice_count
	var missed_before_bonus: int = game.no_response_count
	game._process(game.WORD_CELEBRATION + 0.01)
	assert(game.mode == game.BONUS and game.word_index == 0)
	# O centro da tela e o cabeçalho também comandam o salto.
	var bonus_touch := InputEventScreenTouch.new()
	bonus_touch.pressed = true
	bonus_touch.position = viewport_size / 2.0
	game._input(bonus_touch)
	game._process(0.05)
	assert(game.bonus.total_jumps == 1 and game.bonus.feet_y < game.bonus.GROUND_Y)
	game._process(14.94)
	assert(game.mode == game.BONUS, "O prêmio deve durar os 15 segundos completos.")
	game._process(0.02)
	assert(game.mode == game.BONUS_RESULT)
	game._process(2.01)
	assert(game.mode == game.PLAY and game.word_index == 1)
	assert(game.letter_index == 0 and game.star_count == 4)
	assert(game.wrong_choice_count == errors_before_bonus and game.no_response_count == missed_before_bonus)
	assert(game._bonus_animation_profile("bear") != game._bonus_animation_profile("princess"))
	assert(game._bonus_animation_profile("knight") != game._bonus_animation_profile("princess"))
	# Toda palavra, inclusive a última, deve conceder o bônus antes de avançar.
	for word_number in range(1, game.words.size()):
		for letter in game._current_word().length():
			game._choose(game.correct_lane)
			game._finish_choice()
		assert(game.mode == game.WORD_DONE)
		game._process(game.WORD_CELEBRATION + 0.01)
		assert(game.mode == game.BONUS and game.bonus.age == 0)
		game._process(15.0)
		assert(game.mode == game.BONUS_RESULT)
		game._process(2.01)
	assert(game.mode == game.SESSION_DONE)
	assert(game.star_count == 12)
	DirAccess.remove_absolute(game.content.profile_path)
	game.free()
	await process_frame
	print("SMOKE_OK: metades completas, mouse/toque, proteção contra repetição, corrida vertical, áudio, partículas e palavra → bônus → próxima palavra")
	quit()
