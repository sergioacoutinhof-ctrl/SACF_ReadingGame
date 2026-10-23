extends SceneTree

class PreviewAndroidGuard extends Node:
	var last_error := ""
	func available() -> bool:
		return true
	func lock_state() -> int:
		return 0
	func device_has_pin() -> bool:
		return true
	func start_pinning() -> bool:
		return false
	func stop_pinning() -> void:
		pass
	func security_settings() -> void:
		pass

var output_dir := ""
var generic_characters := false


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
		if argument == "--generic-characters":
			generic_characters = true
	call_deferred("_run")


func _capture(name: String) -> void:
	root.get_child(root.get_child_count() - 1).queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output_dir.path_join(name + ".png"))
	assert(error == OK)


func _run() -> void:
	assert(not output_dir.is_empty())
	DirAccess.make_dir_recursive_absolute(output_dir)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.parents.is_open = false
	game.parents.cover.hide()
	game.voice_id = ""
	if generic_characters:
		game._load_default_characters()
		game.content.entries = game.content.entries.filter(func(entry: Dictionary): return not str(entry["image"]).begins_with("character:"))
		game.words = game.content.session_words()
	game.elapsed = 0.2
	await _capture("selection")
	game._start_session()
	game.pair_age = 2.8
	await _capture("vertical-runner")
	game._choose(game.correct_lane)
	game._process(0.25)
	await _capture("collect")
	game._finish_choice()
	game.pair_age = 2.8
	await _capture("progress")
	game.mode = game.WORD_DONE
	game.word_done_age = 0.7
	await _capture("word-complete")
	for index in 3:
		game.character_index = index
		game.mode = game.WORD_DONE
		game._start_bonus()
		game._process(1.0)
		game.bonus.request_jump()
		game._process(0.30)
		await _capture("bonus-" + game.character_roles[index])
	game.mode = game.WORD_DONE
	game._start_bonus()
	game.bonus.distance = 270
	game.bonus.feet_y = 470
	game.bonus.grounded = false
	await _capture("bonus-letters-holes")
	game.bonus.failed = true
	game.mode = game.BONUS_RESULT
	await _capture("bonus-fall-result")
	game._process(2.01)
	await _capture("back-to-letters")
	game._request_parent()
	await _capture("parent-pin")
	# Prévia pública da configuração, sem criar PIN nem editar perfil real.
	game.parents.authorized = true
	game.parents._show_words()
	await _capture("word-photo-settings")
	var preview_guard := PreviewAndroidGuard.new()
	game.add_child(preview_guard)
	game.parents.guard = preview_guard
	game.parents._show_home()
	await _capture("parent-android-settings")
	game.free()
	await create_timer(0.15).timeout
	print("VISUAL_OK: letras, três personagens no bônus e retorno renderizados pelo Godot")
	quit()
