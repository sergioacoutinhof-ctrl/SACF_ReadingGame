extends RefCounted

const ALLOWED := "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÃÉÊÍÓÔÕÚÜÇ"
const MAX_LENGTH := 14
var profile_path := "user://family/profile.json"
var entries: Array[Dictionary] = []
var pin_salt := ""
var pin_digest := ""
var holes_enabled := true
var android_exit_pin_confirmed := false
var cursor := 0
var last_error := ""
var textures: Dictionary = {}


func load_profile() -> void:
	entries.clear()
	var defaults: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/words.json"))
	var private_path := "res://private/content/words.json"
	if FileAccess.file_exists(private_path):
		var personal: Variant = JSON.parse_string(FileAccess.get_file_as_string(private_path))
		if personal is Array:
			for entry in personal:
				_append_valid(entry)
	if defaults is Array:
		for entry in defaults:
			_append_valid(entry)
	if not FileAccess.file_exists(profile_path):
		return
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
	if not saved is Dictionary:
		last_error = "O perfil não pôde ser lido. O conteúdo inicial foi carregado."
		return
	pin_salt = str(saved.get("pin_salt", ""))
	pin_digest = str(saved.get("pin_digest", ""))
	holes_enabled = bool(saved.get("holes_enabled", true))
	android_exit_pin_confirmed = bool(saved.get("android_exit_pin_confirmed", false))
	cursor = maxi(0, int(saved.get("cursor", 0)))
	var loaded: Variant = saved.get("entries", [])
	if loaded is Array and not loaded.is_empty():
		var previous := entries.duplicate(true)
		entries.clear()
		for entry in loaded:
			_append_valid(entry)
		if entries.is_empty():
			entries = previous


func normalized_word(value: String) -> String:
	var word := value.strip_edges().to_upper()
	if word.is_empty() or word.length() > MAX_LENGTH:
		return ""
	for letter in word:
		if not ALLOWED.contains(letter):
			return ""
	return word


func _append_valid(value: Variant) -> void:
	if not value is Dictionary:
		return
	var word := normalized_word(str(value.get("word", "")))
	if word.is_empty():
		return
	for current in entries:
		if current["word"] == word:
			return
	var photo := str(value.get("photo", ""))
	if not photo.begins_with("user://family/photos/") or photo.contains(".."):
		photo = ""
	entries.append({"word": word, "image": str(value.get("image", "sparkle")), "photo": photo, "enabled": bool(value.get("enabled", true))})


func has_pin() -> bool:
	return not pin_salt.is_empty() and pin_digest.length() == 64


func set_pin(value: String) -> bool:
	if value.length() != 6 or not value.is_valid_int() or value.begins_with("-") or value.begins_with("+"):
		last_error = "Escolha um PIN com 6 números."
		return false
	var old_salt := pin_salt
	var old_digest := pin_digest
	pin_salt = Crypto.new().generate_random_bytes(24).hex_encode()
	pin_digest = (pin_salt + value).sha256_text()
	if save_profile():
		return true
	pin_salt = old_salt
	pin_digest = old_digest
	return false


func verify_pin(value: String) -> bool:
	return has_pin() and (pin_salt + value).sha256_text() == pin_digest


func save_profile() -> bool:
	var folder := profile_path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		last_error = "Não foi possível criar a pasta do perfil."
		return false
	var temporary := profile_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível salvar as alterações."
		return false
	file.store_string(JSON.stringify({"version": 1, "entries": entries, "pin_salt": pin_salt, "pin_digest": pin_digest, "holes_enabled": holes_enabled, "android_exit_pin_confirmed": android_exit_pin_confirmed, "cursor": cursor}))
	file.flush()
	file.close()
	var result := DirAccess.rename_absolute(temporary, profile_path)
	if result != OK:
		last_error = "Não foi possível concluir o salvamento."
		return false
	last_error = ""
	return true


func session_words() -> Array:
	var active: Array = []
	for entry in entries:
		if entry["enabled"]:
			active.append(entry.duplicate(true))
	if active.is_empty():
		return []
	var start := cursor % active.size()
	var result: Array = []
	for index in mini(6, active.size()):
		result.append(active[(start + index) % active.size()])
	return result


func advance_session(count: int) -> void:
	cursor += count
	save_profile()


func import_photo(index: int, path: String) -> bool:
	if index < 0 or index >= entries.size():
		return false
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		last_error = "Não consegui abrir a foto. Escolha uma imagem JPG, PNG ou WebP."
		return false
	# Guardar somente uma cópia recortada, sem o original nem seus metadados.
	var side := mini(image.get_width(), image.get_height())
	image = image.get_region(Rect2i((image.get_width() - side) / 2, (image.get_height() - side) / 2, side, side))
	image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	var folder := "user://family/photos"
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		last_error = "Não consegui criar a pasta de fotos."
		return false
	var destination := folder.path_join(Crypto.new().generate_random_bytes(12).hex_encode() + ".jpg")
	if image.save_jpg(destination, 0.90) != OK:
		last_error = "Não consegui salvar a foto."
		return false
	var old := str(entries[index].get("photo", ""))
	entries[index]["photo"] = destination
	if not save_profile():
		entries[index]["photo"] = old
		DirAccess.remove_absolute(destination)
		return false
	textures.erase(old)
	if not old.is_empty():
		DirAccess.remove_absolute(old)
	return true


func photo_texture(entry: Dictionary) -> Texture2D:
	var path := str(entry.get("photo", ""))
	if path.is_empty() or not path.begins_with("user://family/photos/") or path.contains(".."):
		return null
	if not textures.has(path):
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			return null
		textures[path] = ImageTexture.create_from_image(image)
	return textures[path]
