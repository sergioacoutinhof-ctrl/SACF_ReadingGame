extends SceneTree

var game: Control
var frames := 0


func _initialize() -> void:
	process_frame.connect(func(): frames += 1)
	call_deferred("_run")


func _tap(point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = point
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = point
	up.pressed = false
	Input.parse_input_event(up)


func _run() -> void:
	assert(OS.get_name() == "Windows" and DisplayServer.get_name() != "headless")
	assert(not ProjectSettings.get_setting_with_override("audio/general/text_to_speech"), "O backend OneCore não deve ser inicializado no Windows.")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var deadline := Time.get_ticks_msec() + 25000
	while game.sound.narrator.worker_pid > 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(game.sound.narrator.worker_pid <= 0, "A geração de voz deve terminar em segundo plano.")
	var status: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.sound.narrator.status_path))
	assert(status is Dictionary and status.get("state") == "ready", "É necessário testar com voz portuguesa real, não apenas sem áudio.")
	# Reproduz interrupções rápidas, incluindo o cancelamento por silêncio.
	for value in ["BOLA", "B", "O", "L", "A", "CASA", "PATO", "B"]:
		game._speak(value)
		await create_timer(0.05).timeout
	game.sound.toggle_mute()
	assert(not game.sound.narrator.player.playing)
	game.sound.toggle_mute()
	var baseline: int = game.sound.narrator.played_count
	var character: int = game.character_roles.find("princess")
	_tap(game._character_rect(character).get_center())
	await process_frame
	assert(game.mode == game.PLAY)
	print("VOICE_RUN: Portuguese audio active; full real-time session started")
	var viewport_size := root.get_visible_rect().size
	for word_number in game.words.size():
		assert(game.word_index == word_number and game.mode == game.PLAY)
		var length: int = game._current_word().length()
		for letter in length:
			var x := viewport_size.x * (0.25 if game.correct_lane == 0 else 0.75)
			_tap(Vector2(x, viewport_size.y * 0.45))
			await create_timer(1.18).timeout
			assert(game.letter_index == letter + 1)
		assert(game.mode == game.WORD_DONE)
		while game.mode == game.WORD_DONE:
			await process_frame
		assert(game.mode == game.BONUS)
		var bonus_started := Time.get_ticks_msec()
		while game.mode == game.BONUS:
			_tap(viewport_size / 2.0)
			await create_timer(0.65).timeout
		assert(Time.get_ticks_msec() - bonus_started >= 14900)
		print("VOICE_RUN: word %d and its 15-second bonus completed" % (word_number + 1))
	assert(game.mode == game.SESSION_DONE and game.star_count == 12)
	await create_timer(2.0).timeout
	var spoken: int = game.sound.narrator.played_count - baseline
	assert(spoken >= 22, "Todas as letras, palavras e transições precisam tocar com voz ligada.")
	print("VOICE_REAL_OK: %d spoken cues, %d responsive frames, complete session and three real-time bonuses" % [spoken, frames])
	game.free()
	await create_timer(0.15).timeout
	quit()
