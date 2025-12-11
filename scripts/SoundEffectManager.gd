extends Node

"""
SoundEffectManager handles UI and gameplay audio effects.
Provides sound cues for hits, misses, and UI interactions.
"""

var sfx_player: AudioStreamPlayer
var master_bus_index: int = AudioServer.get_bus_index("Master")
var sfx_bus_index: int = AudioServer.get_bus_index("SFX") if AudioServer.get_bus_index("SFX") >= 0 else master_bus_index

var sfx_enabled: bool = true
var volume_db: float = 0.0

signal sfx_played(effect_name: String)

func _ready() -> void:
	# Create SFX player if it doesn't exist
	var parent = get_parent()
	sfx_player = parent.get_node_or_null("SFXPlayer")
	
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		parent.add_child(sfx_player)

func play_hit_sound(judgment: String) -> void:
	"""Play sound for hit judgment."""
	if not sfx_enabled:
		return
	
	match judgment:
		"Perfect":
			_play_sfx("perfect_hit")
		"Great":
			_play_sfx("great_hit")
		"Good":
			_play_sfx("good_hit")
		"Miss":
			_play_sfx("miss_sound")

func play_combo_milestone(combo: int) -> void:
	"""Play sound at combo milestones."""
	if not sfx_enabled or combo < 10:
		return
	
	if combo % 50 == 0:
		_play_sfx("combo_milestone_50")
	elif combo % 25 == 0:
		_play_sfx("combo_milestone_25")
	elif combo % 10 == 0:
		_play_sfx("combo_milestone_10")

func play_ui_click() -> void:
	"""Play UI click sound."""
	if sfx_enabled:
		_play_sfx("ui_click")

func play_ui_hover() -> void:
	"""Play UI hover sound."""
	if sfx_enabled:
		_play_sfx("ui_hover")

func play_menu_select() -> void:
	"""Play menu selection sound."""
	if sfx_enabled:
		_play_sfx("menu_select")

func play_game_start() -> void:
	"""Play game start sound."""
	if sfx_enabled:
		_play_sfx("game_start")

func play_game_over() -> void:
	"""Play game over sound."""
	if sfx_enabled:
		_play_sfx("game_over")

func _play_sfx(effect_name: String) -> void:
	"""Play a sound effect."""
	var audio_path = "res://assets/sfx/%s.wav" % effect_name
	
	# Try to load the audio file
	if ResourceLoader.exists(audio_path):
		var audio_stream = load(audio_path)
		if audio_stream:
			sfx_player.stream = audio_stream
			sfx_player.play()
			emit_signal("sfx_played", effect_name)
	else:
		# Fallback: generate a simple beep tone
		_generate_beep_tone(effect_name)

func _generate_beep_tone(effect_name: String) -> void:
	"""Generate a simple beep tone as placeholder."""
	var frequency = 440.0
	match effect_name:
		"perfect_hit":
			frequency = 880.0  # High pitch
		"great_hit":
			frequency = 660.0
		"good_hit":
			frequency = 440.0
		"miss_sound":
			frequency = 220.0  # Low pitch
		"ui_click":
			frequency = 800.0
	
	# Note: Would need AudioStreamGenerator to create dynamic tones
	# For now, this is a placeholder

func set_volume(db: float) -> void:
	"""Set SFX volume in dB."""
	volume_db = clamp(db, -80.0, 0.0)
	AudioServer.set_bus_mute(sfx_bus_index, false)
	AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)

func enable_sfx(enabled: bool) -> void:
	"""Enable/disable sound effects."""
	sfx_enabled = enabled

func is_sfx_enabled() -> bool:
	"""Check if SFX is enabled."""
	return sfx_enabled
