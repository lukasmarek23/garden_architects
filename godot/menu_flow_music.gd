extends Node
## Autoload: loops `menu_theme.mp3` across main menu and character select.
## `main.gd` calls `stop()` when the match starts so the in-game theme can play.

const STREAM_PATH := "res://audio/menu_theme.mp3"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var stream: AudioStream = load(STREAM_PATH) as AudioStream
	if stream == null:
		push_warning("MenuFlowMusic: could not load " + STREAM_PATH)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_player.stream = stream
	_player.volume_db = -6.0


func ensure_playing() -> void:
	if _player.stream == null:
		return
	if _player.playing:
		return
	_player.play(0.0)


func stop() -> void:
	if _player.playing:
		_player.stop()
