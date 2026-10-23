extends Control

const WIDTH := 1280.0
const HEIGHT := 720.0
const SELECT := 0
const PLAY := 1
const WORD_DONE := 2
const SESSION_DONE := 3
const BONUS := 4
const WORD_CELEBRATION := 1.8
const BONUS_RUN = preload("res://bonus_run.gd")
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const FEEDBACK_TIME := 1.1
const INK := Color("254956")
const TEAL := Color("188e92")
const PURPLE := Color("8662b6")
const GOLD := Color("ffcf59")
const BACKGROUND = preload("res://assets/art/meadow.png")
const FRIENDS = preload("res://assets/art/friends.png")
const TITLE_FONT = preload("res://assets/fonts/Fredoka.ttf")
const SOUNDS = preload("res://sound.gd")

var mode := SELECT
var character_index := 0
var words: Array = []
var word_index := 0
var letter_index := 0
var correct_lane := 0
var options := ["A", "B"]
var pair_age := 0.0
var feedback_age := 0.0
var word_done_age := 0.0
var elapsed := 0.0
var scroll_offset := 0.0
var selected_lane := -1
var runner_lane := -1
var runner_x := WIDTH / 2.0
var last_choice_correct := false
var no_response_count := 0
var wrong_choice_count := 0
var star_count := 0
var rng := RandomNumberGenerator.new()
var effect_rng := RandomNumberGenerator.new()
var voice_id := ""
var font: Font
var title_font: Font
var sprites: Array[AtlasTexture] = []
var character_names: Array[String] = []
var character_roles: Array[String] = []
var particles: Array[Dictionary] = []
var panels: Dictionary = {}
var sound: Node
var bonus := BONUS_RUN.new()
var bonus_total_stars := 0


func _ready() -> void:
	rng.randomize()
	effect_rng.randomize()
	font = ThemeDB.fallback_font
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/words.json"))
	if typeof(parsed) == TYPE_ARRAY:
		words = parsed
	var rounded_font := FontVariation.new()
	rounded_font.base_font = TITLE_FONT
	rounded_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600.0}
	title_font = rounded_font
	_load_default_characters()
	_load_private_characters()
	sound = SOUNDS.new()
	add_child(sound)
	sound.prepare_voice(words)
	if DisplayServer.get_name() != "headless" and OS.get_name() != "Windows":
		var voices := DisplayServer.tts_get_voices_for_language("pt")
		if not voices.is_empty():
			voice_id = voices[0]
	queue_redraw()


func _load_default_characters() -> void:
	sprites.clear()
	character_names.assign(["Princesa", "Ursinho", "Cavaleiro"])
	character_roles.assign(["princess", "bear", "knight"])
	for region in [Rect2(17, 96, 511, 845), Rect2(559, 202, 441, 731), Rect2(1040, 82, 479, 860)]:
		var atlas := AtlasTexture.new()
		atlas.atlas = FRIENDS
		atlas.region = region
		sprites.append(atlas)


func _load_private_characters() -> bool:
	for manifest_path in ["user://characters/pack.json", "res://private/characters/pack.json"]:
		if not FileAccess.file_exists(manifest_path):
			continue
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not manifest is Dictionary:
			continue
		var filename := str(manifest.get("atlas", "friends.png"))
		if filename != filename.get_file() or filename.contains(":") or filename.contains("\\"):
			continue
		var image_path: String = manifest_path.get_base_dir().path_join(filename)
		var texture: Texture2D
		if ResourceLoader.exists(image_path, "Texture2D"):
			texture = load(image_path) as Texture2D
		elif FileAccess.file_exists(image_path):
			var image := Image.load_from_file(image_path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
		if texture != null and _apply_character_pack(manifest, texture):
			return true
	return false


func _apply_character_pack(manifest: Dictionary, texture: Texture2D) -> bool:
	var entries: Variant = manifest.get("characters", [])
	if not entries is Array or entries.size() != 3:
		return false
	var next_sprites: Array[AtlasTexture] = []
	var next_names: Array[String] = []
	var next_roles: Array[String] = []
	var bounds := Rect2(Vector2.ZERO, texture.get_size())
	for entry in entries:
		if not entry is Dictionary:
			return false
		var region: Variant = entry.get("region", [])
		var display_name := str(entry.get("name", "")).strip_edges().left(24)
		var role := str(entry.get("role", ""))
		if not region is Array or region.size() != 4 or display_name.is_empty():
			return false
		if role not in ["princess", "bear", "knight"]:
			return false
		for coordinate in region:
			if typeof(coordinate) != TYPE_INT and typeof(coordinate) != TYPE_FLOAT:
				return false
		var rectangle := Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
		if rectangle.size.x <= 0 or rectangle.size.y <= 0 or not bounds.encloses(rectangle):
			return false
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = rectangle
		next_sprites.append(atlas)
		next_names.append(display_name)
		next_roles.append(role)
	# Só trocar o conjunto depois de validar as três entradas.
	sprites = next_sprites
	character_names = next_names
	character_roles = next_roles
	return true


func _process(delta: float) -> void:
	elapsed += delta
	scroll_offset = fmod(scroll_offset + delta * 0.25, 1.0)
	var goal_x := WIDTH / 2.0 if runner_lane < 0 else _lane_x(runner_lane, 650.0)
	runner_x = lerpf(runner_x, goal_x, 1.0 - exp(-delta * 10.0))
	for index in range(particles.size() - 1, -1, -1):
		particles[index]["age"] += delta
		particles[index]["position"] += particles[index]["velocity"] * delta
		particles[index]["velocity"].y += delta * 160.0
		if particles[index]["age"] >= particles[index]["life"]:
			particles.remove_at(index)
	if mode == PLAY:
		if feedback_age > 0.0:
			feedback_age = maxf(0.0, feedback_age - delta)
			if feedback_age <= 0.0:
				_finish_choice()
		else:
			pair_age += delta
			if pair_age > 9.0:
				no_response_count += 1
				_make_pair()
	elif mode == WORD_DONE:
		word_done_age += delta
		if word_done_age >= WORD_CELEBRATION:
			_start_bonus()
	elif mode == BONUS:
		_process_bonus(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			sound.toggle_mute()
			return
		if mode == BONUS and event.keycode == KEY_SPACE:
			bonus.request_jump()
			return
	var pressed := false
	var screen_position := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		screen_position = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		screen_position = event.position
	if not pressed:
		return
	if mode == BONUS:
		bonus.request_jump()
		return
	# TODA a metade da tela é alvo, inclusive cabeçalho e margens.
	if mode == PLAY:
		var middle := get_viewport_rect().size.x / 2.0
		if absf(screen_position.x - middle) <= get_viewport_rect().size.x / WIDTH * 4.0:
			return
		_choose(0 if screen_position.x < middle else 1)
		return
	var point := _to_design(screen_position)
	if mode == SELECT:
		for index in 3:
			if _character_rect(index).has_point(point):
				character_index = index
				_start_session()
				return
	elif mode == SESSION_DONE:
		if Rect2(390, 510, 500, 112).has_point(point):
			mode = SELECT


func _start_session() -> void:
	if words.is_empty():
		return
	word_index = 0
	letter_index = 0
	no_response_count = 0
	wrong_choice_count = 0
	star_count = 0
	bonus_total_stars = 0
	bonus.reset()
	feedback_age = 0.0
	selected_lane = -1
	runner_lane = -1
	runner_x = WIDTH / 2.0
	particles.clear()
	mode = PLAY
	_make_pair()
	sound.set_bonus(false)
	sound.start_music()
	_speak(_current_word())


func _current_word() -> String:
	return str(words[word_index].get("word", ""))


func _make_pair() -> void:
	if mode != PLAY or words.is_empty():
		return
	var word := _current_word()
	if letter_index >= word.length():
		return
	var correct := word.substr(letter_index, 1)
	var wrong := correct
	while wrong == correct:
		wrong = ALPHABET.substr(rng.randi_range(0, ALPHABET.length() - 1), 1)
	correct_lane = rng.randi_range(0, 1)
	options[correct_lane] = correct
	options[1 - correct_lane] = wrong
	pair_age = 0.0
	selected_lane = -1


func _choose(lane: int) -> void:
	if mode != PLAY or feedback_age > 0.0 or lane < 0 or lane > 1:
		return
	selected_lane = lane
	runner_lane = lane
	last_choice_correct = lane == correct_lane
	feedback_age = FEEDBACK_TIME
	if last_choice_correct:
		star_count += 1
		_burst(Vector2(_lane_x(lane, 440.0), 440.0), 26)
		sound.play_collect()
		# TTS ainda é nome de letra; fonemas gravados vêm na etapa de conteúdo.
		_speak(options[lane])
	else:
		wrong_choice_count += 1
		sound.play_retry()


func _finish_choice() -> void:
	if selected_lane < 0:
		return
	feedback_age = 0.0
	selected_lane = -1
	if last_choice_correct:
		letter_index += 1
		if letter_index >= _current_word().length():
			mode = WORD_DONE
			word_done_age = 0.0
			_burst(Vector2(640, 300), 70)
			sound.play_word_complete()
			_speak(_current_word())
		else:
			_make_pair()
	else:
		_make_pair()


func _start_bonus() -> void:
	if mode != WORD_DONE:
		return
	mode = BONUS
	bonus.reset(effect_rng.randi())
	particles.clear()
	selected_lane = -1
	feedback_age = 0.0
	sound.set_bonus(true)
	_speak("Hora de brincar! Toque para pular.")


func _process_bonus(delta: float) -> void:
	var previous_jumps: int = bonus.total_jumps
	var pickups: Array[Vector2] = bonus.advance(delta)
	if bonus.total_jumps > previous_jumps:
		sound.play_jump()
		_burst(Vector2(bonus.RUNNER_X - 15.0, bonus.feet_y), 5)
	for point in pickups:
		_burst(point, 12)
	if not pickups.is_empty():
		bonus_total_stars += pickups.size()
		sound.play_bonus_star()
	if bonus.is_finished():
		_advance_word()


func _advance_word() -> void:
	sound.set_bonus(false)
	particles.clear()
	word_index += 1
	if word_index >= words.size():
		mode = SESSION_DONE
		_speak("Muito bem! Você completou as palavras.")
	else:
		letter_index = 0
		selected_lane = -1
		runner_lane = -1
		runner_x = WIDTH / 2.0
		mode = PLAY
		_make_pair()
		_speak(_current_word())


func _speak(value: String) -> void:
	if sound.muted:
		return
	if OS.get_name() == "Windows":
		sound.narrator.speak(value)
	elif DisplayServer.get_name() != "headless":
		# A síntese de fala do Android pode terminar de iniciar depois de _ready().
		if voice_id.is_empty():
			var voices := DisplayServer.tts_get_voices_for_language("pt")
			if not voices.is_empty():
				voice_id = voices[0]
		if not voice_id.is_empty():
			DisplayServer.tts_speak(value.to_lower(), voice_id, 75, 1.0, 0.85, 0, true)


func _to_design(screen_position: Vector2) -> Vector2:
	var screen_size := get_viewport_rect().size
	var factor: float = minf(screen_size.x / WIDTH, screen_size.y / HEIGHT)
	return (screen_position - (screen_size - Vector2(WIDTH, HEIGHT) * factor) / 2.0) / factor


func _draw() -> void:
	var screen_size := get_viewport_rect().size
	var factor: float = minf(screen_size.x / WIDTH, screen_size.y / HEIGHT)
	var origin := (screen_size - Vector2(WIDTH, HEIGHT) * factor) / 2.0
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("b9e4cf"))
	if mode == PLAY:
		draw_rect(Rect2(0, 0, screen_size.x / 2.0, screen_size.y), Color("bce6df"))
		draw_rect(Rect2(screen_size.x / 2.0, 0, screen_size.x / 2.0, screen_size.y), Color("ddd1ee"))
	draw_set_transform(origin, 0.0, Vector2(factor, factor))
	_draw_background()
	match mode:
		SELECT:
			_draw_select()
		PLAY:
			_draw_play()
		WORD_DONE:
			_draw_word_done()
		SESSION_DONE:
			_draw_session_done()
		BONUS:
			_draw_bonus()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_background() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, WIDTH, HEIGHT), false)
	for index in 12:
		var x := fmod(105.0 + index * 137.0, WIDTH)
		var y := 260.0 + fmod(index * 59.0 - elapsed * 11.0 + 4600.0, 430.0)
		var alpha := 0.18 + 0.18 * sin(elapsed * 1.2 + index)
		_star(Vector2(x, y), 3.0 + index % 3, Color(1, 1, 0.8, alpha))


func _draw_select() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.91, 0.98, 0.95, 0.2))
	_text("Aventura das Letras", Vector2(640, 98), 62, INK, true, true)
	_text("Escolha quem vai brincar com você", Vector2(640, 146), 25, INK, true)
	var colors_by_role := {"princess": Color("f5e8fb"), "bear": Color("e2f7ec"), "knight": Color("e4f1ff")}
	for index in 3:
		var tile := _character_rect(index)
		_panel(tile, colors_by_role[character_roles[index]], Color.WHITE, 30, 4)
		_star(tile.position + Vector2(37, 38), 11, GOLD)
		_star(tile.position + Vector2(277, 65), 7, Color(1, 1, 1, 0.9))
		var bob := sin(elapsed * 2.4 + index * 0.8) * 5.0
		_character(index, Vector2(tile.get_center().x, 486.0 + bob), 268.0)
		_text(character_names[index], Vector2(tile.get_center().x, 543), 35, INK, true, true)
		_text("TOQUE PARA BRINCAR", Vector2(tile.get_center().x, 581), 16, TEAL, true)
	_panel(Rect2(340, 645, 600, 45), Color(1, 1, 1, 0.88), Color.TRANSPARENT, 22)
	_text("Uma aventura, uma letrinha de cada vez", Vector2(640, 675), 22, INK, true, true)


func _character_rect(index: int) -> Rect2:
	return Rect2(145 + index * 337, 199, 316, 411)


func _lane_x(lane: int, y: float) -> float:
	var offset := 124.0 + (y - 210.0) * 0.22
	return WIDTH / 2.0 + (-offset if lane == 0 else offset)


func _draw_road() -> void:
	# As marcas crescem e se deslocam de cima para baixo.
	_polygon([Vector2(386, 190), Vector2(894, 190), Vector2(1165, 720), Vector2(115, 720)], Color("f4e6bf"))
	_polygon([Vector2(401, 190), Vector2(879, 190), Vector2(1137, 720), Vector2(143, 720)], Color("fff4d8"))
	_polygon([Vector2(401, 190), Vector2(640, 190), Vector2(640, 720), Vector2(143, 720)], Color("d6efde"))
	_polygon([Vector2(640, 190), Vector2(879, 190), Vector2(1137, 720), Vector2(640, 720)], Color("e9def2"))
	for index in 10:
		var depth := fmod(index / 10.0 + scroll_offset, 1.0)
		var y := lerpf(190.0, 765.0, pow(depth, 1.7))
		var dash := 7.0 + depth * 25.0
		_panel(Rect2(637.0 - depth, y, 6.0 + depth * 2.0, dash), Color(1, 1, 1, 0.8), Color.TRANSPARENT, 4)
		for side in 2:
			var x := lerpf(395.0, 130.0, (y - 190.0) / 530.0)
			if side == 1:
				x = WIDTH - x
			_star(Vector2(x, y), 3.0 + depth * 4.0, Color("fff7dc"))


func _draw_play() -> void:
	_draw_road()
	draw_rect(Rect2(0, 0, 640, HEIGHT), Color(0.2, 0.8, 0.72, 0.065))
	draw_rect(Rect2(640, 0, 640, HEIGHT), Color(0.65, 0.4, 0.88, 0.065))
	var left_alpha := 0.42 if selected_lane == 0 else 0.22
	var right_alpha := 0.42 if selected_lane == 1 else 0.22
	draw_rect(Rect2(3, 3, 635, 714), Color(0.1, 0.64, 0.61, left_alpha), false, 5)
	draw_rect(Rect2(642, 3, 635, 714), Color(0.55, 0.34, 0.76, right_alpha), false, 5)
	var letter_y := _letter_y()
	var depth := clampf(pair_age / 2.8, 0.0, 1.0)
	var card_size := lerpf(92.0, 132.0, 1.0 - pow(1.0 - depth, 3.0))
	for lane in 2:
		var chosen := selected_lane == lane
		if chosen and last_choice_correct and feedback_age < FEEDBACK_TIME * 0.72:
			continue
		var center := Vector2(_lane_x(lane, letter_y), letter_y)
		if chosen and not last_choice_correct:
			center.x += sin((FEEDBACK_TIME - feedback_age) * 18.0) * 5.0
		var accent := TEAL if lane == 0 else PURPLE
		draw_circle(center, card_size * 0.67, Color(accent, 0.10))
		_panel(Rect2(center - Vector2.ONE * card_size / 2.0, Vector2.ONE * card_size), Color("fffcf5"), accent, 26, 4)
		_text(options[lane], center + Vector2(0, card_size * 0.25), int(card_size * 0.67), INK, true)
		_star(center + Vector2(card_size * 0.39, -card_size * 0.41), 9, GOLD)
	var jump := 0.0
	if selected_lane >= 0:
		var fraction := 1.0 - feedback_age / FEEDBACK_TIME
		jump = sin(minf(fraction / 0.8, 1.0) * PI) * (107.0 if last_choice_correct else 22.0)
	var bob := absf(sin(elapsed * 7.0)) * 6.0 if selected_lane < 0 else 0.0
	_character(character_index, Vector2(runner_x, 651.0 - jump - bob), 182.0, jump)
	_draw_particles()
	_draw_hud()
	if feedback_age > 0.0:
		var message := "Muito bem!" if last_choice_correct else "Vamos tentar de novo"
		_panel(Rect2(420, 222, 440, 51), Color("fffbed"), Color.TRANSPARENT, 25)
		_text(message, Vector2(640, 257), 30, TEAL if last_choice_correct else PURPLE, true, true)
		if last_choice_correct:
			var travel := clampf((1.0 - feedback_age / FEEDBACK_TIME) / 0.85, 0.0, 1.0)
			var start := Vector2(_lane_x(selected_lane, 435.0), 435.0)
			var end := _slot_rect(letter_index).get_center()
			var pos := start.lerp(end, travel) + Vector2(0, -sin(travel * PI) * 65.0)
			_star(pos, lerpf(25.0, 12.0, travel), GOLD, elapsed * 2.0)
	else:
		_panel(Rect2(420, 222, 440, 44), Color(1, 1, 1, 0.88), Color.TRANSPARENT, 22)
		_text("Qual letra vem agora?", Vector2(640, 252), 24, INK, true, true)
	_draw_zone_labels()


func _letter_y() -> float:
	var fraction := clampf(pair_age / 2.8, 0.0, 1.0)
	return lerpf(325.0, 428.0, 1.0 - pow(1.0 - fraction, 3.0))


func _slot_rect(index: int) -> Rect2:
	var word_length := _current_word().length()
	var slot_width := minf(68.0, 690.0 / maxf(word_length, 1.0) - 9.0)
	var full_width := word_length * (slot_width + 9.0) - 9.0
	return Rect2(610.0 - full_width / 2.0 + index * (slot_width + 9.0), 86, slot_width, 66)


func _draw_hud() -> void:
	_panel(Rect2(32, 21, 1216, 158), Color("fffdf6"), Color.WHITE, 28, 3)
	_panel(Rect2(53, 41, 116, 116), Color("e7f3e6"), Color.TRANSPARENT, 24)
	_word_image(Vector2(111, 100), str(words[word_index].get("image", "ball")), 0.58)
	_text("VAMOS FORMAR A PALAVRA", Vector2(610, 65), 17, TEAL, true, true)
	var word := _current_word()
	for index in word.length():
		var slot := _slot_rect(index)
		var done := index < letter_index
		var active := index == letter_index
		var fill := Color("c9eee0") if done else Color("f0f0e8")
		if active:
			fill = Color("fff0b6")
		_panel(slot, fill, Color("e9ba4a") if active else Color.TRANSPARENT, 14, 2)
		_text(word.substr(index, 1), slot.get_center() + Vector2(0, 18), 43, TEAL if done else INK, true)
		if done:
			draw_circle(Vector2(slot.end.x - 7, slot.position.y + 7), 9, TEAL)
			_polyline([Vector2(slot.end.x - 11, slot.position.y + 7), Vector2(slot.end.x - 8, slot.position.y + 10), Vector2(slot.end.x - 3, slot.position.y + 4)], Color.WHITE, 2)
	_panel(Rect2(1048, 40, 166, 58), Color("fff0bf"), Color.TRANSPARENT, 24)
	_star(Vector2(1080, 69), 16, Color("e4aa26"))
	_text(str(star_count), Vector2(1142, 83), 35, INK, true, true)
	_text("PALAVRA %d DE %d" % [word_index + 1, words.size()], Vector2(1130, 132), 15, INK, true)
	for index in words.size():
		draw_circle(Vector2(1108 + index * 23, 151), 5, TEAL if index <= word_index else Color("d6ded8"))


func _draw_zone_labels() -> void:
	# Legendas de orientação, sem retângulos clicáveis.
	_text("TOQUE À ESQUERDA", Vector2(250, 698), 20, Color("24656c"), true, true)
	_text("TOQUE À DIREITA", Vector2(1030, 698), 20, Color("674b87"), true, true)
	_polyline([Vector2(74, 681), Vector2(64, 689), Vector2(74, 697)], TEAL, 4)
	_polyline([Vector2(1206, 681), Vector2(1216, 689), Vector2(1206, 697)], PURPLE, 4)


func _draw_word_done() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.1, 0.25, 0.24, 0.23))
	_panel(Rect2(288, 74, 704, 565), Color("fffdf2"), Color.WHITE, 38, 4)
	_text("Você conseguiu!", Vector2(640, 148), 49, TEAL, true, true)
	var pulse := 1.0 + sin(word_done_age * 3.0) * 0.025
	_word_image(Vector2(640, 292), str(words[word_index].get("image", "ball")), pulse)
	_text(_current_word(), Vector2(640, 463), 77, INK, true, true)
	for index in 3:
		_star(Vector2(555 + index * 85, 534), 27 + sin(word_done_age * 3.0 + index) * 3.0, GOLD)
	_text("Você ganhou 15 segundos para brincar!", Vector2(640, 597), 23, TEAL, true, true)
	_draw_particles()


func _draw_bonus() -> void:
	# Parallax e cenário próprio deixam claro que este é o prêmio da palavra.
	var drift := fmod(bonus.distance * 0.035, 120.0)
	draw_texture_rect(BACKGROUND, Rect2(-drift, -4, WIDTH + 140, HEIGHT + 8), false)
	for index in 5:
		var x := fposmod(index * 370.0 - bonus.distance * 0.28, 1680.0) - 150.0
		draw_circle(Vector2(x, 581), 84, Color("b2d5a7"))
		draw_circle(Vector2(x + 70, 591), 63, Color("c6dfae"))
	draw_rect(Rect2(0, 600, WIDTH, 120), Color("dcad84"))
	draw_rect(Rect2(0, 624, WIDTH, 96), Color("edc69c"))
	draw_rect(Rect2(0, 596, WIDTH, 24), Color("6eb582"))
	draw_rect(Rect2(0, 596, WIDTH, 8), Color("a8d891"))
	for index in range(-1, 16):
		var x := index * 96.0 - fposmod(bonus.distance, 96.0)
		draw_circle(Vector2(x + 25, 615), 9, Color("6eb582"))
		draw_circle(Vector2(x + 76, 618), 7, Color("6eb582"))
		_panel(Rect2(x + 5, 645, 52, 12), Color("d9aa81"), Color.TRANSPARENT, 6)
		_panel(Rect2(x + 51, 681, 30, 9), Color("e0b68d"), Color.TRANSPARENT, 4)
	for platform in bonus.platforms:
		var screen := Rect2(platform.position - Vector2(bonus.distance, 0), platform.size)
		if screen.end.x < -20 or screen.position.x > WIDTH + 20:
			continue
		_panel(screen, Color("e9c79b"), Color("d8b184"), 12, 2)
		_panel(Rect2(screen.position - Vector2(3, 8), Vector2(screen.size.x + 6, 16)), Color("9acd8a"), Color.TRANSPARENT, 8)
		for step in 4:
			draw_circle(screen.position + Vector2(20 + step * 49, 8), 5, Color("80ba7d"))
		_polyline([screen.position + Vector2(27, 27), screen.position + Vector2(29, 44), screen.position + Vector2(35, 49)], Color("a1c590"), 3)
	for star in bonus.stars:
		var position: Vector2 = star["position"] - Vector2(bonus.distance, 0)
		if star["collected"] or position.x < -30 or position.x > WIDTH + 30:
			continue
		position.y += sin(bonus.age * 3.5 + position.x * 0.01) * 4.0
		draw_circle(position, 27, Color(1.0, 0.94, 0.61, 0.22))
		_star(position + Vector2(0, 2), 19, Color("d99830"))
		_star(position, 18, GOLD, -PI / 2.0 + sin(bonus.age * 2.0) * 0.08)
		draw_circle(position + Vector2(-4, -6), 3, Color("fff7ca"))
	_draw_bonus_character()
	_draw_particles()
	_panel(Rect2(25, 20, 1230, 112), Color("fffdf3"), Color.WHITE, 26, 3)
	_text("Hora de brincar!", Vector2(59, 66), 37, TEAL, false, true)
	_text("Você completou: " + _current_word(), Vector2(60, 98), 22, INK, false, true)
	_panel(Rect2(882, 40, 157, 59), Color("fff0bf"), Color.TRANSPARENT, 24)
	_star(Vector2(913, 69), 16, Color("e4aa26"))
	_text(str(bonus.collected), Vector2(982, 83), 33, INK, true, true)
	_panel(Rect2(1058, 40, 162, 59), Color("eee2f7"), Color.TRANSPARENT, 24)
	draw_arc(Vector2(1088, 69), 13, 0, TAU, 32, PURPLE, 2.5, true)
	_polyline([Vector2(1088, 59), Vector2(1088, 69), Vector2(1095, 73)], PURPLE, 2.5)
	_text("%d s" % ceili(bonus.remaining()), Vector2(1157, 82), 29, INK, true, true)
	_panel(Rect2(59, 115, 1161, 7), Color("e4ece2"), Color.TRANSPARENT, 3)
	var bar_width: float = 1161.0 * clampf(bonus.remaining() / bonus.DURATION, 0, 1)
	if bar_width > 1:
		_panel(Rect2(59, 115, bar_width, 7), Color("86c9b4"), Color.TRANSPARENT, 3)
	_panel(Rect2(280, 653, 720, 48), Color("fff9e9"), Color.TRANSPARENT, 23)
	var caption := "TOQUE EM QUALQUER LUGAR PARA PULAR"
	if bonus.remaining() < 2.2:
		caption = "JÁ VAMOS PARA A PRÓXIMA PALAVRA"
		if word_index + 1 >= words.size():
			caption = "QUE AVENTURA! VOCÊ CONSEGUIU!"
	_text(caption, Vector2(640, 684), 23, INK, true, true)


func _draw_bonus_character() -> void:
	var sprite := sprites[character_index]
	var role := character_roles[character_index]
	var profile := _bonus_animation_profile(role)
	var phase := bonus.age * profile.x
	var floor_y: float = bonus.feet_y if bonus.grounded else bonus.GROUND_Y
	var shadow_radius := 46.0 - minf(18.0, (bonus.GROUND_Y - bonus.feet_y) * 0.08)
	var shadow := PackedVector2Array()
	for step in 28:
		var angle := TAU * step / 28.0
		shadow.append(Vector2(bonus.RUNNER_X + cos(angle) * shadow_radius, floor_y - 1.0 + sin(angle) * 7))
	draw_colored_polygon(shadow, Color(0.14, 0.30, 0.24, 0.17))
	var feet := Vector2(bonus.RUNNER_X, bonus.feet_y)
	for index in 3:
		var trail_x := feet.x - 65.0 - index * 25.0 - fmod(bonus.age * 70.0, 22.0)
		var trail_y := feet.y - 12.0 - index * 4.0
		if role == "princess":
			_star(Vector2(trail_x, trail_y), 5.0 - index, Color(1, 0.84, 0.51, 0.5 - index * 0.1))
		elif role == "bear":
			draw_circle(Vector2(trail_x, trail_y), 5.0 - index, Color(1, 0.96, 0.82, 0.45 - index * 0.1))
		else:
			draw_line(Vector2(trail_x - 12, trail_y), Vector2(trail_x + 5, trail_y), Color(0.95, 1, 1, 0.55 - index * 0.1), 3, true)
	var height := bonus.PLAYER_HEIGHT
	var width := height * sprite.get_width() / sprite.get_height()
	# Malha simples: rosto estável, corpo inclinado e passos alternados.
	# Usa o mesmo atlas, inclusive quando há um pacote local personalizado.
	for row in 8:
		for column in 2:
			var u0 := column / 2.0
			var u1 := (column + 1) / 2.0
			var v0 := row / 8.0
			var v1 := (row + 1) / 8.0
			var coordinates := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			for uv in coordinates:
				points.append(_bonus_vertex(uv, feet, Vector2(width, height), profile, phase))
				uvs.append((sprite.region.position + uv * sprite.region.size) / sprite.atlas.get_size())
			draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, sprite.atlas)


func _bonus_animation_profile(role: String) -> Vector3:
	match role:
		"bear":
			return Vector3(13.5, 7.5, 8.5)
		"princess":
			return Vector3(10.5, 4.5, 4.5)
		_:
			return Vector3(11.5, 3.0, 6.0)


func _bonus_vertex(uv: Vector2, feet: Vector2, dimensions: Vector2, profile: Vector3, phase: float) -> Vector2:
	var ground_motion: float = 1.0 if bonus.grounded else 0.15
	var leg := pow(clampf((uv.y - 0.59) / 0.41, 0.0, 1.0), 1.4)
	var side := uv.x * 2.0 - 1.0
	var lift := maxf(0, sin(phase + (PI if side < 0 else 0)))
	var stride := sin(phase) * side * profile.z * leg * ground_motion
	var bob := absf(sin(phase)) * profile.y * ground_motion
	var local := Vector2((uv.x - 0.5) * dimensions.x, (uv.y - 1.0) * dimensions.y)
	local.x += (1.0 - uv.y) * 10.0 + stride
	local.y -= bob + lift * 7.0 * leg * ground_motion
	if not bonus.grounded:
		local.x *= 1.04
		local.y *= 0.98
	return feet + local


func _draw_session_done() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.1, 0.25, 0.24, 0.16))
	_panel(Rect2(260, 75, 760, 577), Color("fffdf2"), Color.WHITE, 38, 4)
	_text("Que aventura linda!", Vector2(640, 156), 51, TEAL, true, true)
	_character(character_index, Vector2(640, 379 + sin(elapsed * 3.0) * 6), 185)
	_text("Você completou todas as palavras", Vector2(640, 433), 28, INK, true, true)
	_star(Vector2(565, 477), 19, GOLD)
	_text("%d estrelinhas!" % star_count, Vector2(665, 487), 28, INK, true, true)
	_panel(Rect2(390, 510, 500, 112), Color("bfeadc"), Color("89cfbb"), 27, 3)
	_text("BRINCAR DE NOVO", Vector2(640, 580), 35, INK, true, true)
	_draw_particles()


func _panel(rect: Rect2, color: Color, border := Color.TRANSPARENT, radius := 20, border_width := 0) -> void:
	var key := "%s:%s:%d:%d" % [color.to_html(), border.to_html(), radius, border_width]
	if not panels.has(key):
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.border_color = border
		box.set_border_width_all(border_width)
		box.set_corner_radius_all(radius)
		box.corner_detail = 12
		box.anti_aliasing = true
		box.shadow_color = Color(0.11, 0.25, 0.25, 0.12)
		box.shadow_size = 5
		box.shadow_offset = Vector2(0, 4)
		panels[key] = box
	draw_style_box(panels[key], rect)


func _text(value: String, baseline: Vector2, size: int, color: Color, centered: bool, rounded := false) -> void:
	var face: Font = title_font if rounded else font
	var x := baseline.x
	if centered:
		x -= face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	draw_string(face, Vector2(x, baseline.y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _character(index: int, feet: Vector2, height: float, jump := 0.0) -> void:
	if sprites.is_empty():
		return
	var sprite := sprites[index]
	var width := height * sprite.get_width() / sprite.get_height()
	var floor_y := feet.y + jump
	var shadow_width := height * 0.42 - jump * 0.12
	var shadow := PackedVector2Array()
	for step in 32:
		var angle := TAU * step / 32.0
		shadow.append(Vector2(feet.x + cos(angle) * shadow_width, floor_y - 3.0 + sin(angle) * 8.0))
	draw_colored_polygon(shadow, Color(0.12, 0.28, 0.25, 0.13))
	draw_texture_rect(sprite, Rect2(feet - Vector2(width / 2.0, height), Vector2(width, height)), false)


func _star(center: Vector2, radius: float, color: Color, rotation := -PI / 2.0) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle := rotation + index * PI / 5.0
		var length := radius if index % 2 == 0 else radius * 0.47
		points.append(center + Vector2(cos(angle), sin(angle)) * length)
	draw_colored_polygon(points, color)


func _polygon(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _polyline(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)


func _burst(center: Vector2, count: int) -> void:
	var colors := [GOLD, Color("fff4bc"), Color("72d9c6"), Color("d4a6eb"), Color("ffb79b")]
	for index in count:
		var angle := effect_rng.randf_range(-PI, 0.0)
		var speed := effect_rng.randf_range(70.0, 260.0)
		particles.append({"position": center, "velocity": Vector2(cos(angle), sin(angle)) * speed,
			"age": 0.0, "life": effect_rng.randf_range(0.65, 1.6), "size": effect_rng.randf_range(4.0, 12.0),
			"color": colors[index % colors.size()], "star": index % 3 != 0, "angle": angle})


func _draw_particles() -> void:
	for particle in particles:
		var color: Color = particle["color"]
		color.a = clampf((particle["life"] - particle["age"]) * 2.0, 0.0, 1.0)
		if particle["star"]:
			_star(particle["position"], particle["size"], color, particle["angle"] + particle["age"] * 2.0)
		else:
			draw_circle(particle["position"], particle["size"] * 0.45, color, true, -1.0, true)


func _word_image(center: Vector2, kind: String, factor: float) -> void:
	var f := factor
	match kind:
		"ball":
			draw_circle(center + Vector2(3, 5) * f, 74 * f, Color(0.15, 0.33, 0.3, 0.12))
			draw_circle(center, 72 * f, Color("f58c6b"))
			draw_arc(center, 55 * f, -1.2, 1.9, 48, Color("ffe7a5"), 17 * f, true)
			draw_arc(center, 49 * f, 1.95, 4.2, 48, Color("86d6cf"), 17 * f, true)
			draw_circle(center + Vector2(-24, -30) * f, 14 * f, Color(1, 1, 1, 0.45))
		"house":
			_panel(Rect2(center + Vector2(-59, -10) * f, Vector2(118, 89) * f), Color("ffdda0"), Color.TRANSPARENT, int(12 * f))
			_polygon([center + Vector2(-82, -7) * f, center + Vector2(0, -80) * f, center + Vector2(82, -7) * f], Color("df827c"))
			_panel(Rect2(center + Vector2(-14, 28) * f, Vector2(31, 51) * f), Color("78bcb8"), Color.TRANSPARENT, int(7 * f))
			draw_circle(center + Vector2(0, -18) * f, 17 * f, Color("eaf9ed"))
			draw_line(center + Vector2(-16, -18) * f, center + Vector2(16, -18) * f, Color("7caaa7"), 3 * f, true)
			draw_line(center + Vector2(0, -34) * f, center + Vector2(0, -2) * f, Color("7caaa7"), 3 * f, true)
		"duck":
			draw_circle(center + Vector2(-12, 22) * f, 54 * f, Color("ffcc63"))
			draw_circle(center + Vector2(31, -26) * f, 34 * f, Color("ffdc7a"))
			draw_circle(center + Vector2(-19, 28) * f, 25 * f, Color("f5b34d"))
			_polygon([center + Vector2(54, -21) * f, center + Vector2(84, -10) * f, center + Vector2(54, 1) * f], Color("ed925b"))
			draw_circle(center + Vector2(39, -34) * f, 5 * f, INK)
			draw_circle(center + Vector2(40, -36) * f, 1.5 * f, Color.WHITE)
