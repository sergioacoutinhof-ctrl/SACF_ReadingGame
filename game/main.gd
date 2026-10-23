extends Control

# Primeiro protótipo: arte vetorial provisória e conteúdo público genérico.
# Fotos, gravações e nomes particulares serão carregados apenas do armazenamento local.

const WIDTH := 1280.0
const HEIGHT := 720.0
const LANE_Y := [335.0, 465.0]
const SELECT := 0
const PLAY := 1
const WORD_DONE := 2
const SESSION_DONE := 3
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

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
var scroll_offset := 0.0
var selected_lane := -1
var last_choice_correct := false
var no_response_count := 0
var wrong_choice_count := 0
var rng := RandomNumberGenerator.new()
var voice_id := ""
var font: Font


func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/words.json"))
	if typeof(parsed) == TYPE_ARRAY:
		words = parsed
	var voices := DisplayServer.tts_get_voices_for_language("pt")
	if not voices.is_empty():
		voice_id = voices[0]
	queue_redraw()


func _process(delta: float) -> void:
	scroll_offset = fmod(scroll_offset + delta * 130.0, 110.0)
	if mode == PLAY:
		if feedback_age > 0.0:
			feedback_age -= delta
			if feedback_age <= 0.0:
				_finish_choice()
		else:
			pair_age += delta
			if pair_age > 9.0:
				no_response_count += 1
				_make_pair()
	elif mode == WORD_DONE:
		word_done_age += delta
		if word_done_age >= 2.4:
			word_index += 1
			if word_index >= words.size():
				mode = SESSION_DONE
				_speak("Muito bem! Partida completa.")
			else:
				letter_index = 0
				mode = PLAY
				_make_pair()
				_speak(_current_word())
	queue_redraw()


func _input(event: InputEvent) -> void:
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
	var point := _to_design(screen_position)
	if point.x < 0.0 or point.x > WIDTH or point.y < 0.0 or point.y > HEIGHT:
		return
	if mode == SELECT:
		for i in 3:
			if _character_rect(i).has_point(point):
				character_index = i
				_start_session()
				return
	elif mode == SESSION_DONE:
		if Rect2(390, 500, 500, 150).has_point(point):
			mode = SELECT
	elif mode == PLAY and feedback_age <= 0.0:
		if point.y >= 545.0:
			_choose(0 if point.x < WIDTH / 2.0 else 1)


func _start_session() -> void:
	if words.is_empty():
		return
	word_index = 0
	letter_index = 0
	no_response_count = 0
	wrong_choice_count = 0
	selected_lane = -1
	mode = PLAY
	_make_pair()
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
	selected_lane = lane
	last_choice_correct = lane == correct_lane
	feedback_age = 0.65
	if last_choice_correct:
		# A pronúncia provisória do nome da letra será trocada por som gravado
		# ou validado com educadores na etapa de conteúdo e áudio.
		_speak(options[lane])
	else:
		wrong_choice_count += 1


func _finish_choice() -> void:
	selected_lane = -1
	if last_choice_correct:
		letter_index += 1
		if letter_index >= _current_word().length():
			mode = WORD_DONE
			word_done_age = 0.0
			_speak(_current_word())
		else:
			_make_pair()
	else:
		# Erro motor ou de leitura: repetir somente a letra atual.
		_make_pair()


func _speak(text: String) -> void:
	if voice_id != "":
		DisplayServer.tts_speak(text.to_lower(), voice_id, 75, 1.0, 0.85, 0, true)


func _to_design(screen_position: Vector2) -> Vector2:
	var screen_size := get_viewport_rect().size
	var scale_factor: float = minf(screen_size.x / WIDTH, screen_size.y / HEIGHT)
	var origin := (screen_size - Vector2(WIDTH, HEIGHT) * scale_factor) / 2.0
	return (screen_position - origin) / scale_factor


func _draw() -> void:
	var screen_size := get_viewport_rect().size
	var scale_factor: float = minf(screen_size.x / WIDTH, screen_size.y / HEIGHT)
	var origin := (screen_size - Vector2(WIDTH, HEIGHT) * scale_factor) / 2.0
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("e8f5f8"))
	draw_set_transform(origin, 0.0, Vector2(scale_factor, scale_factor))
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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("dff7fa"))
	for x in [135.0, 545.0, 1000.0]:
		_draw_cloud(Vector2(x - scroll_offset * 0.15, 80), 1.0)
	draw_circle(Vector2(1160, 108), 54, Color("ffe5a1"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 305), Vector2(260, 210), Vector2(490, 310), Vector2(770, 205), Vector2(1050, 305), Vector2(1280, 225), Vector2(1280, 545), Vector2(0, 545)]), Color("b9e8c5"))
	draw_rect(Rect2(0, 273, WIDTH, 260), Color("87cbaa"))
	draw_rect(Rect2(0, 290, WIDTH, 260), Color("6b9c8b"))
	for i in 14:
		var x := fmod(i * 110.0 - scroll_offset + WIDTH, WIDTH + 110.0)
		draw_rect(Rect2(x, 400, 55, 9), Color("fff3cb"))
	draw_rect(Rect2(0, 540, WIDTH, 180), Color("d7e3dd"))


func _draw_cloud(center: Vector2, factor: float) -> void:
	for offset in [Vector2(-40, 7), Vector2(0, -12), Vector2(37, 9)]:
		draw_circle(center + offset * factor, 32 * factor, Color("ffffff"))


func _draw_select() -> void:
	_draw_panel(Rect2(178, 78, 924, 115), Color("ffffff"))
	_text("Escolha um personagem", Vector2(640, 140), 49, Color("274d59"), true)
	var names := ["PRINCESA", "URSINHO", "CAVALEIRO"]
	for i in 3:
		var tile := _character_rect(i)
		_draw_panel(tile, Color("fffaf0"))
		_draw_character(i, tile.position + Vector2(135, 142), 1.25)
		_text(names[i], tile.position + Vector2(135, 265), 28, Color("274d59"), true)
		_text("TOQUE PARA JOGAR", tile.position + Vector2(135, 309), 19, Color("567d87"), true)
	_text("Toque em qualquer personagem para começar", Vector2(640, 652), 26, Color("274d59"), true)


func _character_rect(index: int) -> Rect2:
	return Rect2(160 + index * 330, 215, 300, 355)


func _draw_play() -> void:
	_draw_panel(Rect2(65, 27, 1150, 235), Color("fffbf3"))
	_draw_word_image(Vector2(165, 143), str(words[word_index].get("image", "ball")))
	_text("PALAVRA", Vector2(320, 82), 19, Color("63848b"), false)
	_text(_current_word(), Vector2(320, 142), 48, Color("3b7180"), false)
	var progress := ""
	var word := _current_word()
	for i in word.length():
		progress += word.substr(i, 1) if i < letter_index else "_"
		progress += " "
	_text(progress, Vector2(320, 225), 56, Color("174950"), false)
	var x := _letter_x()
	for lane in 2:
		var center := Vector2(x, LANE_Y[lane])
		var card_color := Color("ffdaaa") if lane == selected_lane else Color("fff8e9")
		_draw_panel(Rect2(center - Vector2(65, 54), Vector2(130, 108)), card_color)
		_text(options[lane], center + Vector2(0, 16), 66, Color("294f60"), true)
	_draw_character(character_index, Vector2(235, LANE_Y[selected_lane] if selected_lane >= 0 else 400.0), 0.8)
	if feedback_age > 0.0:
		_text("★" if last_choice_correct else "TENTE DE NOVO", Vector2(690, 355), 48 if last_choice_correct else 33, Color("ffe071") if last_choice_correct else Color("fff3da"), true)
	_draw_targets()


func _letter_x() -> float:
	# Aproximação rápida seguida de grande janela de escolha.
	var fraction: float = clampf(pair_age / 2.8, 0.0, 1.0)
	var ease_out: float = 1.0 - pow(1.0 - fraction, 3.0)
	return lerpf(1120.0, 545.0, ease_out)


func _draw_targets() -> void:
	draw_rect(Rect2(0, 545, 638, 175), Color("a6d8ed"))
	draw_rect(Rect2(642, 545, 638, 175), Color("f8c6bf"))
	draw_rect(Rect2(638, 545, 4, 175), Color("ffffff"))
	_text("◀  ESCOLHER", Vector2(319, 640), 42, Color("254f63"), true)
	_text("ESCOLHER  ▶", Vector2(961, 640), 42, Color("6c3d46"), true)
	_text("TOQUE EM UMA DAS ÁREAS GRANDES", Vector2(640, 693), 19, Color("345760"), true)


func _draw_word_done() -> void:
	_draw_panel(Rect2(170, 125, 940, 440), Color("fff8e4"))
	_draw_word_image(Vector2(640, 275), str(words[word_index].get("image", "ball")))
	_text(_current_word(), Vector2(640, 435), 78, Color("285f69"), true)
	_text("MUITO BEM!  ★ ★ ★", Vector2(640, 515), 38, Color("db9d3e"), true)


func _draw_session_done() -> void:
	_draw_panel(Rect2(165, 125, 950, 510), Color("fff8e4"))
	_text("PARABÉNS!", Vector2(640, 245), 72, Color("285f69"), true)
	_text("Você completou as palavras!", Vector2(640, 325), 37, Color("315f68"), true)
	_text("★  ★  ★", Vector2(640, 420), 74, Color("e6ad45"), true)
	_draw_panel(Rect2(390, 500, 500, 120), Color("a6d8ed"))
	_text("JOGAR DE NOVO", Vector2(640, 575), 41, Color("254f63"), true)


func _draw_panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(6), Color("426b68", 0.2))
	draw_rect(rect, color)
	draw_rect(rect, Color("88aaa0"), false, 3.0)


func _text(value: String, baseline: Vector2, size: int, color: Color, centered: bool) -> void:
	var x := baseline.x
	if centered:
		x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	draw_string(font, Vector2(x, baseline.y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_word_image(center: Vector2, kind: String) -> void:
	_draw_panel(Rect2(center - Vector2(84, 84), Vector2(168, 168)), Color("e8f5e9"))
	match kind:
		"ball":
			draw_circle(center, 57, Color("f6a858"))
			draw_arc(center, 42, 0.4, 3.6, 25, Color("ffffff"), 6)
			draw_arc(center, 42, 3.6, 6.6, 25, Color("ffffff"), 6)
		"house":
			draw_rect(Rect2(center + Vector2(-54, -13), Vector2(108, 80)), Color("f9d58f"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-72, -12), center + Vector2(0, -75), center + Vector2(72, -12)]), Color("d77d6b"))
			draw_rect(Rect2(center + Vector2(-15, 20), Vector2(30, 47)), Color("6d9db6"))
		"duck":
			draw_circle(center + Vector2(-8, 16), 49, Color("f7d277"))
			draw_circle(center + Vector2(30, -24), 30, Color("f7d277"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(51, -18), center + Vector2(80, -8), center + Vector2(51, 2)]), Color("ea9e61"))
			draw_circle(center + Vector2(40, -32), 4, Color("2d4d55"))
		_:
			draw_circle(center, 55, Color("a6d8ed"))
			_text("?", center + Vector2(0, 25), 76, Color("285f69"), true)


func _draw_character(index: int, center: Vector2, factor: float) -> void:
	var c := center
	var f := factor
	match index:
		0: # Princesa provisória.
			draw_circle(c + Vector2(0, 25) * f, 58 * f, Color("c8a2d7"))
			draw_circle(c + Vector2(0, -18) * f, 44 * f, Color("8f6a4c"))
			draw_circle(c + Vector2(0, -12) * f, 37 * f, Color("f3c8a2"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-36, -55) * f, c + Vector2(-18, -90) * f, c + Vector2(0, -60) * f, c + Vector2(18, -90) * f, c + Vector2(36, -55) * f]), Color("f7d36b"))
		1: # Ursinho provisório.
			draw_circle(c + Vector2(0, 24) * f, 58 * f, Color("b98562"))
			draw_circle(c + Vector2(-34, -45) * f, 21 * f, Color("a97858"))
			draw_circle(c + Vector2(34, -45) * f, 21 * f, Color("a97858"))
			draw_circle(c + Vector2(0, -20) * f, 45 * f, Color("b98562"))
			draw_circle(c + Vector2(0, 0) * f, 20 * f, Color("e6c09b"))
		2: # Cavaleiro provisório.
			draw_circle(c + Vector2(0, 25) * f, 58 * f, Color("8cb7cc"))
			draw_circle(c + Vector2(0, -20) * f, 45 * f, Color("94aab5"))
			draw_rect(Rect2(c + Vector2(-38, -40) * f, Vector2(76, 18) * f), Color("c0d3db"))
			draw_circle(c + Vector2(0, -72) * f, 17 * f, Color("d47f74"))
	draw_circle(c + Vector2(-15, -21) * f, 4 * f, Color("263e48"))
	draw_circle(c + Vector2(15, -21) * f, 4 * f, Color("263e48"))
	draw_arc(c + Vector2(0, -12) * f, 13 * f, 0.2, 2.9, 12, Color("a45558"), 2.5 * f)
