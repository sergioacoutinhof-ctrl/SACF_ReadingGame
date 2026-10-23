extends Node

var muted := false
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var collect := preload("res://assets/audio/collect.wav")
var complete := preload("res://assets/audio/complete.wav")
var retry := preload("res://assets/audio/retry.wav")
var soundtrack := preload("res://assets/audio/meadow.wav")
var jump := preload("res://assets/audio/jump.wav")
var bonus_track := preload("res://assets/audio/bonus.wav")
var bonus_active := false


func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.stream = soundtrack
	music.volume_db = -17.0
	add_child(music)
	music.finished.connect(_on_music_finished)
	effects = AudioStreamPlayer.new()
	effects.volume_db = -4.0
	add_child(effects)


func start_music() -> void:
	if not muted and not music.playing:
		music.play()


func toggle_mute() -> void:
	muted = not muted
	if muted:
		music.stop()
		effects.stop()
		DisplayServer.tts_stop()
	else:
		start_music()


func play_collect() -> void:
	_play(collect)


func play_word_complete() -> void:
	_play(complete)


func play_retry() -> void:
	_play(retry)


func set_bonus(active: bool) -> void:
	if active == bonus_active:
		return
	bonus_active = active
	var resume := music.playing
	music.stop()
	music.stream = bonus_track if active else soundtrack
	if resume and not muted:
		music.play()


func play_jump() -> void:
	_play(jump)


func play_bonus_star() -> void:
	_play(collect)


func _play(stream: AudioStream, pitch: float = 1.0) -> void:
	if muted:
		return
	effects.stream = stream
	effects.pitch_scale = pitch
	effects.play()


func _on_music_finished() -> void:
	if not muted:
		music.play()


func _exit_tree() -> void:
	music.stop()
	effects.stop()
