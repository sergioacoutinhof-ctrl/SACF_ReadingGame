extends Node

const HELPER_PATH := "res://platform/windows/speech_cache.ps1"
const WORKER_TIMEOUT_MS := 30000
const PENDING_TIMEOUT_MS := 4000

var player: AudioStreamPlayer
var cache_dir := ""
var status_path := ""
var worker_pid := -1
var worker_started := 0
var pending := ""
var pending_started := 0
var enabled := false
var cached_streams: Dictionary = {}
var played_count := 0
var poll_age := 0.0


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -2.5
	add_child(player)
	enabled = OS.get_name() == "Windows" and DisplayServer.get_name() != "headless"


func prepare(words: Array) -> void:
	if not enabled:
		return
	_stop_worker()
	cache_dir = ProjectSettings.globalize_path("user://speech-cache-v1")
	if DirAccess.make_dir_recursive_absolute(cache_dir) != OK:
		enabled = false
		return
	var texts: Array[String] = []
	# Palavras primeiro: a primeira pista pode ficar pronta antes do restante.
	for entry in words:
		_add_text(texts, str(entry.get("word", "")))
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		_add_text(texts, letter)
	for entry in words:
		for letter in str(entry.get("word", "")):
			_add_text(texts, letter)
	for phrase in ["Hora de brincar! Toque para pular.", "Muito bem! Você completou as palavras."]:
		_add_text(texts, phrase)
	var request_path := cache_dir.path_join("request-%d.json" % OS.get_process_id())
	status_path = cache_dir.path_join("status-%d.json" % OS.get_process_id())
	var request := FileAccess.open(request_path, FileAccess.WRITE)
	if request == null:
		enabled = false
		return
	request.store_string(JSON.stringify({"cache_dir": cache_dir, "status_path": status_path, "texts": texts}))
	request.close()
	var script := FileAccess.get_file_as_string(HELPER_PATH)
	if script.is_empty():
		enabled = false
		return
	# A única substituição é um caminho local escapado como literal PowerShell.
	script = script.replace("__REQUEST_PATH__", request_path.replace("'", "''"))
	var encoded := Marshalls.raw_to_base64(script.to_utf16_buffer())
	var executable := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	worker_pid = OS.create_process(executable, ["-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded], false)
	worker_started = Time.get_ticks_msec()
	print("VOICE_CACHE: background worker started")


func _add_text(texts: Array[String], value: String) -> void:
	var normalized := value.strip_edges().to_lower()
	if not normalized.is_empty() and normalized not in texts:
		texts.append(normalized)


func speak(value: String) -> void:
	if not enabled or cache_dir.is_empty():
		return
	player.stop()
	pending = value.strip_edges().to_lower()
	pending_started = Time.get_ticks_msec()
	_try_pending()


func cancel() -> void:
	pending = ""
	if player != null:
		player.stop()


func _process(delta: float) -> void:
	if not enabled:
		return
	poll_age += delta
	if poll_age < 0.05:
		return
	poll_age = 0.0
	if worker_pid > 0:
		if not OS.is_process_running(worker_pid):
			worker_pid = -1
			print("VOICE_CACHE: worker finished")
		elif Time.get_ticks_msec() - worker_started > WORKER_TIMEOUT_MS:
			_stop_worker()
			print("VOICE_CACHE: worker timeout; game remains active")
	if not pending.is_empty():
		if Time.get_ticks_msec() - pending_started > PENDING_TIMEOUT_MS:
			pending = ""
		else:
			_try_pending()


func _try_pending() -> void:
	if pending.is_empty():
		return
	var key := pending.sha256_text()
	if not cached_streams.has(key):
		var path := cache_dir.path_join(key + ".wav")
		if not FileAccess.file_exists(path):
			return
		var stream := AudioStreamWAV.load_from_file(path)
		if stream == null:
			pending = ""
			return
		cached_streams[key] = stream
	player.stream = cached_streams[key]
	player.play()
	played_count += 1
	pending = ""


func _stop_worker() -> void:
	if worker_pid > 0 and OS.is_process_running(worker_pid):
		OS.kill(worker_pid)
	worker_pid = -1


func _exit_tree() -> void:
	cancel()
	_stop_worker()
