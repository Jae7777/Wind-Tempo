extends Node

"""
AudioManager handles music playback and synchronization with note spawning.
Provides audio control and timing utilities for the game.
"""

var audio_player: AudioStreamPlayer
var is_ready: bool = false

signal music_started
signal music_stopped
signal music_paused
signal music_resumed

func _ready() -> void:
	# Create AudioStreamPlayer if it doesn't exist
	var parent = get_parent()
	audio_player = parent.get_node_or_null("AudioPlayer")
	
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioPlayer"
		audio_player.bus = "Master"
		parent.add_child(audio_player)
	
	is_ready = true

func load_music(file_path: String) -> bool:
	"""Load an audio file for playback."""
	if not is_ready:
		return false
	
	var audio_stream = load(file_path)
	if not audio_stream:
		push_error("Failed to load audio: %s" % file_path)
		return false
	
	audio_player.stream = audio_stream
	print("Audio loaded: %s" % file_path)
	return true

func play_music() -> void:
	"""Start music playback."""
	if not is_ready or not audio_player.stream:
		return
	
	audio_player.play()
	emit_signal("music_started")
	print("Music started")

func stop_music() -> void:
	"""Stop music playback."""
	if not is_ready:
		return
	
	audio_player.stop()
	emit_signal("music_stopped")
	print("Music stopped")

func pause_music() -> void:
	"""Pause music playback."""
	if not is_ready:
		return
	
	audio_player.stream_paused = true
	emit_signal("music_paused")
	print("Music paused")

func resume_music() -> void:
	"""Resume paused music."""
	if not is_ready:
		return
	
	audio_player.stream_paused = false
	emit_signal("music_resumed")
	print("Music resumed")

func is_playing() -> bool:
	"""Check if music is currently playing."""
	if not is_ready:
		return false
	return audio_player.playing

func get_playback_position() -> float:
	"""Get current playback position in seconds."""
	if not is_ready:
		return 0.0
	return audio_player.get_playback_position()

func set_playback_position(position: float) -> void:
	"""Set playback position to specific time."""
	if not is_ready:
		return
	audio_player.seek(position)

func get_duration() -> float:
	"""Get total duration of loaded audio."""
	if not is_ready or not audio_player.stream:
		return 0.0
	return audio_player.stream.get_length()

func set_volume(db: float) -> void:
	"""Set volume in decibels."""
	if not is_ready:
		return
	audio_player.volume_db = db
	print("Volume set to: %.1f dB" % db)

func get_volume() -> float:
	"""Get current volume in decibels."""
	if not is_ready:
		return 0.0
	return audio_player.volume_db

func seek(position: float) -> void:
	"""Seek to specific time in audio."""
	if not is_ready:
		return
	if position >= 0.0 and position <= get_duration():
		audio_player.seek(position)
