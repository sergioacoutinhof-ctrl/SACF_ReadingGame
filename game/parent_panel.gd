extends CanvasLayer

signal content_changed
signal resumed
signal exit_requested
signal cancelled
signal security_requested
var store: RefCounted
var guard: Node
var is_open := false
var intent := "menu"
var screen := ""
var exit_busy := false
var authorized := false
var failures := 0
var blocked_until := 0
var pending_pin := ""
var changing_pin := false
var awaiting_pinning := false
var pin_poll := 0.0
var editing := -1
var cover: Control
var card: PanelContainer
var body: VBoxContainer
var message: Label
var pin_field: LineEdit
var word_field: LineEdit
var enabled_field: CheckButton
var word_list: ItemList
var image_preview: TextureRect
var file_dialog: FileDialog


func setup(content_store: RefCounted, android_guard: Node) -> void:
	store = content_store
	guard = android_guard
	layer = 30
	cover = Control.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.18, 0.24, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_child(shade)
	card = PanelContainer.new()
	card.anchor_left = 0.06
	card.anchor_right = 0.94
	card.anchor_top = 0.025
	card.anchor_bottom = 0.975
	cover.add_child(card)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffdf3")
	style.set_corner_radius_all(24)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)
	var theme := Theme.new()
	theme.default_font_size = 22
	theme.default_font = preload("res://assets/fonts/Fredoka.ttf")
	for type in ["Label", "Button", "LineEdit", "ItemList", "CheckButton"]:
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_selected_color"]:
			theme.set_color(color, type, Color("254956"))
	theme.set_color("font_disabled_color", "Button", Color("829088"))
	theme.set_color("caret_color", "LineEdit", Color("188e92"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("d7eee3")
		if state == "hover":
			button_style.bg_color = Color("bfe5d6")
		elif state == "pressed":
			button_style.bg_color = Color("fff0b6")
		elif state == "disabled":
			button_style.bg_color = Color("ebeee8")
		button_style.border_color = Color("8dc7b5")
		button_style.set_border_width_all(2)
		button_style.set_corner_radius_all(12)
		theme.set_stylebox(state, "Button", button_style)
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color("ffffff")
	field_style.border_color = Color("8dc7b5")
	field_style.set_border_width_all(2)
	field_style.set_corner_radius_all(10)
	field_style.content_margin_left = 10
	theme.set_stylebox("normal", "LineEdit", field_style)
	theme.set_stylebox("focus", "LineEdit", field_style)
	theme.set_stylebox("panel", "ItemList", field_style)
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color("bfe5d6")
	selected_style.set_corner_radius_all(8)
	theme.set_stylebox("selected", "ItemList", selected_style)
	theme.set_stylebox("selected_focus", "ItemList", selected_style)
	card.theme = theme
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	card.add_child(body)
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.use_native_dialog = true
	file_dialog.add_filter("*.png,*.jpg,*.jpeg,*.webp", "Fotos", "image/png,image/jpeg,image/webp")
	file_dialog.file_selected.connect(_photo_selected)
	add_child(file_dialog)
	cover.hide()
	guard.status_changed.connect(func():
		if is_open and message != null:
			message.text = guard.last_error
	)


func _process(delta: float) -> void:
	if awaiting_pinning:
		pin_poll += delta
		if pin_poll >= 0.4:
			pin_poll = 0.0
			if guard.lock_state() > 0:
				awaiting_pinning = false
				_close()


func _clear(title: String) -> void:
	screen = title
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 31)
	heading.add_theme_color_override("font_color", Color("188e92"))
	body.add_child(heading)


func _label(text: String, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(parent if parent != null else body).add_child(label)
	return label


func _button(text: String, callback: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 50
	button.pressed.connect(callback)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else body).add_child(button)
	return button


func request_access(reason: String = "menu") -> void:
	if is_open:
		return
	is_open = true
	intent = reason if store.has_pin() else "setup"
	authorized = false
	changing_pin = false
	pending_pin = ""
	cover.show()
	_show_pin()


func _show_pin() -> void:
	_clear("Área dos responsáveis")
	var creating: bool = not store.has_pin() or changing_pin
	_label(("Confirme o novo PIN de 6 números." if not pending_pin.is_empty() else "Crie um PIN de 6 números para configurações e saída.") if creating else "Digite seu PIN de 6 números.")
	pin_field = LineEdit.new()
	pin_field.secret = true
	pin_field.max_length = 6
	pin_field.virtual_keyboard_enabled = false
	pin_field.custom_minimum_size.y = 52
	pin_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_field.add_theme_font_size_override("font_size", 30)
	body.add_child(pin_field)
	var keypad := GridContainer.new()
	keypad.columns = 3
	keypad.add_theme_constant_override("h_separation", 10)
	keypad.add_theme_constant_override("v_separation", 8)
	body.add_child(keypad)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Apagar", "0", "Entrar"]:
		var value: String = key
		_button(value, _pin_key.bind(value), keypad)
	message = _label("")
	message.add_theme_color_override("font_color", Color("8d3455"))
	var cancel := _button("Voltar", _cancel_pin)
	cancel.disabled = not store.has_pin()


func _pin_key(key: String) -> void:
	if Time.get_ticks_msec() < blocked_until:
		message.text = "Aguarde %d segundos para tentar novamente." % ceili((blocked_until - Time.get_ticks_msec()) / 1000.0)
		return
	if key == "Apagar":
		pin_field.text = pin_field.text.left(-1)
	elif key == "Entrar":
		_submit_pin()
	elif pin_field.text.length() < 6:
		pin_field.text += key


func _submit_pin() -> void:
	if Time.get_ticks_msec() < blocked_until:
		message.text = "Aguarde antes de tentar novamente."
		return
	var value := pin_field.text
	if value.length() != 6 or not value.is_valid_int():
		message.text = "Digite os 6 números."
		return
	if not store.has_pin() or changing_pin:
		if pending_pin.is_empty():
			pending_pin = value
			_show_pin()
			return
		if value != pending_pin:
			pending_pin = ""
			_show_pin()
			message.text = "Os PINs não coincidiram. Comece novamente."
			return
		if not store.set_pin(value):
			message.text = store.last_error
			return
	elif not store.verify_pin(value):
		failures += 1
		pin_field.clear()
		if failures >= 5:
			blocked_until = Time.get_ticks_msec() + 30000
			failures = 0
		message.text = "PIN incorreto. Tente novamente." if blocked_until <= Time.get_ticks_msec() else "Aguarde 30 segundos para tentar novamente."
		return
	failures = 0
	authorized = true
	pending_pin = ""
	var needs_setup := changing_pin or intent == "setup"
	changing_pin = false
	if needs_setup:
		_show_home()
	else:
		_show_actions()


func _cancel_pin() -> void:
	if changing_pin and authorized:
		changing_pin = false
		_show_home()
	elif store.has_pin():
		cancelled.emit()
		_close()


func _show_actions() -> void:
	if not authorized:
		return
	_clear("Jogo pausado")
	_label("Escolha o que deseja fazer.")
	_button("Continuar jogando", _resume_game)
	_button("Configurações e fotos", _show_home)
	_button("Sair do jogo", _exit_game)
	message = _label("")


func request_start() -> void:
	if is_open:
		return
	if not store.has_pin() or (_on_android() and (not store.android_exit_pin_confirmed or not guard.device_has_pin())):
		request_access("setup")
		return
	if not _on_android() or guard.lock_state() > 0:
		resumed.emit()
		return
	is_open = true
	authorized = false
	intent = "start"
	cover.show()
	_show_start()
	_begin_pinning()


func _show_start() -> void:
	_clear("Preparando a partida")
	_label("Confirme a fixação no aviso do Android. A partida começa em seguida.")
	message = _label("")
	_button("Fixar e começar", _begin_pinning)
	_button("Voltar", _cancel_start)


func _begin_pinning() -> void:
	if not store.has_pin() or not store.android_exit_pin_confirmed or not guard.device_has_pin():
		message.text = "A proteção do tablet precisa ser configurada na área dos responsáveis."
		return
	awaiting_pinning = guard.start_pinning()
	message.text = guard.last_error


func _cancel_start() -> void:
	cancelled.emit()
	_close()


func _on_android() -> bool:
	return OS.get_name() == "Android" or guard.available()


func _show_home() -> void:
	if not authorized:
		return
	_clear("Configurações da família")
	_label("%d palavras cadastradas • fotos e alterações ficam neste aparelho." % store.entries.size())
	_button("Palavras e fotos da família", _show_words)
	var holes := CheckButton.new()
	holes.text = "Buracos e quedas no bônus"
	holes.button_pressed = store.holes_enabled
	holes.toggled.connect(func(value: bool):
		store.holes_enabled = value
		if not store.save_profile():
			message.text = store.last_error
	)
	body.add_child(holes)
	if _on_android():
		_label("Para impedir a saída pelos botões do tablet: ative Fixação de app e exija o PIN do tablet ao desafixar. Esse PIN é configurado no Android.")
		var row := HBoxContainer.new()
		body.add_child(row)
		_button("Segurança do tablet", _open_security, row)
		_button("Fixar o jogo agora", _pin_now, row)
		_label("Fixação: " + ("ativa" if guard.lock_state() > 0 else "ainda não está ativa"))
		var confirmed := CheckButton.new()
		confirmed.text = "Ativei exigir PIN ao desafixar nas opções do tablet"
		confirmed.button_pressed = store.android_exit_pin_confirmed
		confirmed.toggled.connect(func(value: bool):
			store.android_exit_pin_confirmed = value
			store.save_profile()
		)
		body.add_child(confirmed)
	else:
		_label("No Android, o jogo pede a fixação de tela antes da partida. Configure também a senha ao desafixar nas opções do tablet.")
	_button("Trocar o PIN do jogo", func():
		changing_pin = true
		pending_pin = ""
		_show_pin()
	)
	message = _label("")
	var row := HBoxContainer.new()
	body.add_child(row)
	_button("Voltar ao menu", _show_actions, row)
	_button("Brincar", _resume_game, row)


func _pin_now() -> void:
	if not authorized:
		return
	guard.start_pinning()
	message.text = guard.last_error


func _open_security() -> void:
	if authorized:
		security_requested.emit()


func show_status(value: String) -> void:
	if is_open and is_instance_valid(message):
		message.text = value


func _resume_game() -> void:
	if not authorized:
		return
	if _on_android() and (not store.android_exit_pin_confirmed or not guard.device_has_pin()):
		_show_home()
		message.text = "Ative exigir PIN ao desafixar nas opções do tablet e confirme a opção acima."
		return
	if _on_android() and guard.lock_state() == 0:
		intent = "start"
		authorized = false
		_show_start()
		_begin_pinning()
		return
	_close()


func _close() -> void:
	awaiting_pinning = false
	is_open = false
	authorized = false
	exit_busy = false
	cover.hide()
	resumed.emit()


func _exit_game() -> void:
	if not authorized or exit_busy:
		return
	exit_busy = true
	message.text = "Liberando a tela para sair…"
	exit_requested.emit()


func exit_failed() -> void:
	exit_busy = false
	message.text = "O Android ainda não liberou a tela. Toque em Sair do jogo para tentar novamente."


func _show_words() -> void:
	if not authorized:
		return
	_clear("Palavras e fotos")
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	word_list = ItemList.new()
	word_list.custom_minimum_size.x = 285
	word_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	word_list.item_selected.connect(_select_word)
	columns.add_child(word_list)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_constant_override("separation", 8)
	columns.add_child(editor)
	_label("Palavra (até 14 letras, com acentos)", editor)
	word_field = LineEdit.new()
	word_field.max_length = 14
	word_field.custom_minimum_size.y = 50
	editor.add_child(word_field)
	enabled_field = CheckButton.new()
	enabled_field.text = "Usar nas partidas"
	editor.add_child(enabled_field)
	image_preview = TextureRect.new()
	image_preview.custom_minimum_size = Vector2(130, 130)
	image_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	editor.add_child(image_preview)
	var row := HBoxContainer.new()
	editor.add_child(row)
	_button("Escolher foto", _choose_photo, row)
	_button("Imagem padrão", _remove_photo, row)
	_button("Salvar palavra", _save_word, editor)
	var actions := HBoxContainer.new()
	editor.add_child(actions)
	_button("Nova palavra", _new_word, actions)
	_button("Excluir", _delete_word, actions)
	message = _label("Selecione uma palavra para editar. As fotos são recortadas no centro.")
	_button("Voltar às configurações", _show_home)
	_refresh_list()
	if not store.entries.is_empty():
		_select_word(0)


func _refresh_list() -> void:
	word_list.clear()
	for entry in store.entries:
		word_list.add_item(("✓ " if entry["enabled"] else "○ ") + entry["word"])


func _select_word(index: int) -> void:
	editing = index
	var entry: Dictionary = store.entries[index]
	word_field.text = entry["word"]
	enabled_field.button_pressed = entry["enabled"]
	image_preview.texture = store.photo_texture(entry)
	if image_preview.texture == null:
		var path := "res://assets/word_images/" + str(entry["image"]) + ".svg"
		if ResourceLoader.exists(path):
			image_preview.texture = load(path)
	word_list.select(index)


func _new_word() -> void:
	editing = -1
	word_list.deselect_all()
	word_field.clear()
	enabled_field.button_pressed = true
	image_preview.texture = null
	message.text = "Digite a palavra e salve. Depois escolha uma foto."
	word_field.grab_focus()


func _save_word() -> void:
	if not authorized:
		return
	var word: String = store.normalized_word(word_field.text)
	if word.is_empty():
		message.text = "Use de 1 a 14 letras, com acentos se necessário."
		return
	for index in store.entries.size():
		if index != editing and store.entries[index]["word"] == word:
			message.text = "Essa palavra já está cadastrada."
			return
	var previous: Array = store.entries.duplicate(true)
	if editing < 0:
		store.entries.append({"word": word, "image": "sparkle", "photo": "", "enabled": enabled_field.button_pressed})
		editing = store.entries.size() - 1
	else:
		store.entries[editing]["word"] = word
		store.entries[editing]["enabled"] = enabled_field.button_pressed
	if store.session_words().is_empty():
		store.entries.assign(previous)
		message.text = "Mantenha pelo menos uma palavra habilitada."
		return
	if not store.save_profile():
		store.entries.assign(previous)
		message.text = store.last_error
		return
	_refresh_list()
	_select_word(editing)
	message.text = "Palavra salva."
	content_changed.emit()


func _choose_photo() -> void:
	if not authorized:
		return
	if editing < 0:
		message.text = "Salve a palavra antes de escolher a foto."
		return
	file_dialog.popup_centered_ratio(0.8)


func _photo_selected(path: String) -> void:
	if not authorized or editing < 0:
		return
	if store.import_photo(editing, path):
		_select_word(editing)
		message.text = "Foto salva neste aparelho."
		content_changed.emit()
	else:
		message.text = store.last_error


func _remove_photo() -> void:
	if not authorized or editing < 0:
		return
	var old: String = store.entries[editing].get("photo", "")
	store.entries[editing]["photo"] = ""
	if not store.save_profile():
		store.entries[editing]["photo"] = old
		message.text = store.last_error
		return
	if not old.is_empty():
		DirAccess.remove_absolute(old)
		store.textures.erase(old)
	_select_word(editing)
	message.text = "Imagem padrão restaurada."
	content_changed.emit()


func _delete_word() -> void:
	if not authorized or editing < 0:
		return
	var previous: Array = store.entries.duplicate(true)
	var old: String = store.entries[editing].get("photo", "")
	store.entries.remove_at(editing)
	if store.session_words().is_empty() or not store.save_profile():
		store.entries.assign(previous)
		message.text = "Mantenha pelo menos uma palavra habilitada. Não foi excluída."
		return
	if not old.is_empty():
		DirAccess.remove_absolute(old)
	_refresh_list()
	_select_word(mini(editing, store.entries.size() - 1))
	message.text = "Palavra excluída."
	content_changed.emit()
