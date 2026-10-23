extends SceneTree

const CONTENT = preload("res://family_content.gd")

class FakeAndroidGuard extends Node:
	var state := 0
	var starts := 0
	var last_error := "Confirme no Android."
	func available() -> bool:
		return true
	func lock_state() -> int:
		return state
	func start_pinning() -> bool:
		starts += 1
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var store = CONTENT.new()
	store.profile_path = "user://tests/family-%d.json" % OS.get_process_id()
	store.load_profile()
	assert(store.entries.size() >= 42 and not store.has_pin())
	assert(store.normalized_word(" mamãe ") == "MAMÃE")
	assert(store.normalized_word("PÉ") == "PÉ")
	assert(store.normalized_word("123").is_empty() and store.normalized_word("<script>").is_empty())
	assert(not store.verify_pin("000000") and not store.set_pin("1234"))
	for entry in store.entries:
		var kind: String = entry["image"]
		assert(kind.begins_with("character:") or ResourceLoader.exists("res://assets/word_images/" + kind + ".svg"))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.content = store
	game.parents.store = store
	game.sound.toggle_mute()
	game._request_parent()
	assert(game.parents.is_open and not game.parents.authorized)
	# Confirmar o PIN é obrigatório antes de salvar.
	game.parents.pin_field.text = "409621"
	game.parents._submit_pin()
	assert(not store.has_pin())
	game.parents.pin_field.text = "409621"
	game.parents._submit_pin()
	assert(store.has_pin() and store.verify_pin("409621") and game.parents.authorized)
	assert(not FileAccess.get_file_as_string(store.profile_path).contains("409621"))
	var restored = CONTENT.new()
	restored.profile_path = store.profile_path
	restored.load_profile()
	assert(restored.verify_pin("409621"), "O PIN deve persistir após reabrir.")
	# Editar palavra com acento e persistir uma foto real pelo mesmo caminho da UI.
	game.parents._show_words()
	game.parents._new_word()
	game.parents.word_field.text = "VOVÓ"
	game.parents._save_word()
	var index: int = game.parents.editing
	assert(index >= 0 and store.entries[index]["word"] == "VOVÓ")
	var source := "user://tests/photo-%d.png" % OS.get_process_id()
	var image := Image.create(30, 50, false, Image.FORMAT_RGB8)
	image.fill(Color("a8d5cd"))
	assert(image.save_png(source) == OK)
	game.parents._photo_selected(source)
	var saved_photo: String = store.entries[index]["photo"]
	assert(not saved_photo.is_empty() and FileAccess.file_exists(saved_photo))
	var decoded := Image.load_from_file(saved_photo)
	assert(decoded.get_width() == 512 and decoded.get_height() == 512)
	restored.load_profile()
	assert(restored.entries[index]["word"] == "VOVÓ" and restored.photo_texture(restored.entries[index]) != null)
	game.parents._remove_photo()
	assert(store.entries[index]["photo"].is_empty() and not FileAccess.file_exists(saved_photo))
	# Sair da tela e voltar exige autenticar outra vez.
	game.parents._close()
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert(game.parents.is_open and not game.parents.authorized)
	game.mode = game.PLAY
	game.words = store.session_words()
	var before: float = game.pair_age
	game._process(3.0)
	assert(game.pair_age == before, "A partida deve parar durante o PIN.")
	for attempt in 5:
		game.parents.pin_field.text = "999999"
		game.parents._submit_pin()
	assert(not game.parents.authorized and game.parents.blocked_until > Time.get_ticks_msec())
	game.parents.pin_field.text = "409621"
	game.parents._submit_pin()
	assert(not game.parents.authorized, "O limite de tentativas deve valer também para o PIN correto.")
	game.parents.blocked_until = 0
	game.parents._submit_pin()
	assert(game.parents.authorized)
	# Rodadas curtas percorrem o catálogo, em vez de ficar nas três mesmas palavras.
	store.cursor = 0
	var first: Array = store.session_words()
	store.advance_session(first.size())
	var second: Array = store.session_words()
	assert(first.size() == 6 and second.size() == 6 and first != second)
	restored.load_profile()
	assert(restored.cursor == store.cursor)
	# A confirmação de configuração e o estado nativo são gates separados.
	var fake := FakeAndroidGuard.new()
	game.add_child(fake)
	game.parents.guard = fake
	store.android_exit_pin_confirmed = false
	game.parents._show_home()
	game.parents._resume_game()
	assert(fake.starts == 0 and game.parents.is_open)
	store.android_exit_pin_confirmed = true
	game.parents._resume_game()
	assert(fake.starts == 1 and game.parents.is_open and game.parents.awaiting_pinning)
	game.parents._process(0.5)
	assert(game.parents.is_open, "Solicitar fixação não significa que o Android aceitou.")
	fake.state = 2
	game.parents._process(0.5)
	assert(not game.parents.is_open and not game.parents.authorized)
	DirAccess.remove_absolute(store.profile_path)
	DirAccess.remove_absolute(source)
	game.free()
	await process_frame
	print("FAMILY_PARENT_OK: 42+ palavras, acentos, PIN confirmado/persistido, bloqueio após tentativas, saída protegida, pausa, edição, foto e rodadas")
	quit()
