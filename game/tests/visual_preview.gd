extends SceneTree

var output_dir := ""


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
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
	game.voice_id = ""
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
	game.free()
	await create_timer(0.15).timeout
	print("VISUAL_OK: five screenshots rendered by Godot")
	quit()
