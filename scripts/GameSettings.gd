extends Node

"""
GameSettings manages user preferences and game configuration.
Persists settings to disk and provides configuration options.
"""

var settings: Dictionary = {
	"master_volume": 0.0,
	"music_volume": -5.0,
	"sfx_volume": -5.0,
	"audio_latency_offset": 0.0,
	"hit_feedback_enabled": true,
	"visual_effects_enabled": true,
	"combo_particles": true,
	"fullscreen": false,
	"target_fps": 60,
	"difficulty_preset": "Normal"
}

var settings_file: String = "user://wind_tempo_settings.cfg"

signal setting_changed(key: String, value)

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	"""Load settings from file."""
	var file = ConfigFile.new()
	var error = file.load(settings_file)
	
	if error != OK:
		print("No settings file found, using defaults")
		return
	
	# Load settings from file
	for key in settings.keys():
		if file.has_section_key("settings", key):
			settings[key] = file.get_value("settings", key)
	
	print("Settings loaded from: %s" % settings_file)

func save_settings() -> void:
	"""Save settings to file."""
	var file = ConfigFile.new()
	
	for key in settings.keys():
		file.set_value("settings", key, settings[key])
	
	var error = file.save(settings_file)
	if error != OK:
		push_error("Failed to save settings")
	else:
		print("Settings saved to: %s" % settings_file)

func set_setting(key: String, value) -> void:
	"""Set a setting value and save."""
	if key not in settings:
		push_warning("Unknown setting: %s" % key)
		return
	
	settings[key] = value
	emit_signal("setting_changed", key, value)
	save_settings()

func get_setting(key: String):
	"""Get a setting value."""
	if key not in settings:
		push_warning("Unknown setting: %s" % key)
		return null
	return settings[key]

func get_all_settings() -> Dictionary:
	"""Get all settings as dictionary."""
	return settings.duplicate()

func reset_to_defaults() -> void:
	"""Reset all settings to defaults."""
	settings = {
		"master_volume": 0.0,
		"music_volume": -5.0,
		"sfx_volume": -5.0,
		"audio_latency_offset": 0.0,
		"hit_feedback_enabled": true,
		"visual_effects_enabled": true,
		"combo_particles": true,
		"fullscreen": false,
		"target_fps": 60,
		"difficulty_preset": "Normal"
	}
	save_settings()
	print("Settings reset to defaults")

# Volume helpers
func set_master_volume(db: float) -> void:
	"""Set master volume in dB."""
	set_setting("master_volume", clamp(db, -80.0, 0.0))

func set_music_volume(db: float) -> void:
	"""Set music volume in dB."""
	set_setting("music_volume", clamp(db, -80.0, 0.0))

func set_sfx_volume(db: float) -> void:
	"""Set SFX volume in dB."""
	set_setting("sfx_volume", clamp(db, -80.0, 0.0))

func set_latency_offset(ms: float) -> void:
	"""Set audio latency offset in milliseconds."""
	set_setting("audio_latency_offset", ms)

func print_settings() -> void:
	"""Print current settings."""
	print("\n=== Game Settings ===")
	for key in settings.keys():
		print("%s: %s" % [key, settings[key]])
