extends SceneTree

var completions := 0
var frames := 0


func _initialize() -> void:
	process_frame.connect(func(): frames += 1)
	call_deferred("_run")


func _run() -> void:
	assert(OS.get_name() == "Windows" and DisplayServer.get_name() != "headless")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.parents.is_open = false
	game.parents.cover.hide()
	game.sound.prepare_voice([{"word": "BOLA"}])
	var deadline := Time.get_ticks_msec() + 25000
	while game.sound.narrator.worker_pid > 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(game.sound.narrator.worker_pid <= 0)
	game.sound.narrator.cancel()
	game.mode = game.BONUS
	game.bonus.reset(0, "BOLA", false)
	game.bonus.platforms.clear()
	game.bonus_voice_started = false
	for token in game.bonus.stars:
		token["position"] = Vector2(game.bonus.RUNNER_X + 8, 432)
	var before: int = game.sound.narrator.played_count
	game.sound.narrator.player.finished.connect(func(): completions += 1)
	game.bonus.request_jump()
	game._process_bonus(0.05)
	assert(game.bonus.pickup_letters == ["B", "O", "L", "A"])
	deadline = Time.get_ticks_msec() + 15000
	while game.sound.narrator.is_speaking() and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	assert(game.sound.narrator.played_count - before == 4)
	assert(completions == 4, "As quatro falas devem terminar, sem uma cortar a outra.")
	assert(not game.sound.narrator.is_speaking())
	print("BONUS_VOICE_REAL_OK: quatro letras coletadas no mesmo quadro, quatro áudios completos; %d quadros responsivos" % frames)
	game.free()
	await process_frame
	quit()
