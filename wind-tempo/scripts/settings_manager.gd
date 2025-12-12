# scripts/settings_manager.gd
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# Settings values
var note_travel_time: float = 2.0

# Audio
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Graphics
var window_mode: int = 0 # 0: Windowed, 1: Fullscreen
var vsync_enabled: bool = true
var msaa_value: int = 0 # 0: Disabled, 1: 2x, 2: 4x, 3: 8x

# Input (NEW)
var mouse_sensitivity: float = 1.0 # 0.1 = slow, 3.0 = fast

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		# Gameplay
		note_travel_time = float(config.get_value("gameplay", "note_travel_time", 2.0))

		# Audio
		master_volume = float(config.get_value("audio", "master_volume", 1.0))
		music_volume = float(config.get_value("audio", "music_volume", 1.0))
		sfx_volume = float(config.get_value("audio", "sfx_volume", 1.0))

		# Graphics
		window_mode = int(config.get_value("graphics", "window_mode", 0))
		vsync_enabled = bool(config.get_value("graphics", "vsync", true))
		msaa_value = int(config.get_value("graphics", "msaa", 0))

		# Input (NEW)
		mouse_sensitivity = float(config.get_value("input", "mouse_sensitivity", 1.0))

	apply_settings()

func save_settings() -> void:
	var config := ConfigFile.new()

	# Gameplay
	config.set_value("gameplay", "note_travel_time", note_travel_time)

	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)

	# Graphics
	config.set_value("graphics", "window_mode", window_mode)
	config.set_value("graphics", "vsync", vsync_enabled)
	config.set_value("graphics", "msaa", msaa_value)

	# Input (NEW)
	config.set_value("input", "mouse_sensitivity", mouse_sensitivity)

	config.save(SETTINGS_PATH)
	apply_settings()

func apply_settings() -> void:
	# Clamp sanity
	note_travel_time = clampf(note_travel_time, 0.2, 10.0)
	master_volume = clampf(master_volume, 0.0, 1.0)
	music_volume = clampf(music_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	mouse_sensitivity = clampf(mouse_sensitivity, 0.1, 3.0) # NEW

	_apply_audio_settings()
	_apply_graphics_settings()

	# Sync with SongManager if it exists
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager and "note_travel_time" in song_manager:
		song_manager.note_travel_time = note_travel_time

func _apply_audio_settings() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))

	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))

	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func _apply_graphics_settings() -> void:
	# Window Mode
	var mode = DisplayServer.WINDOW_MODE_WINDOWED
	if window_mode == 1:
		mode = DisplayServer.WINDOW_MODE_FULLSCREEN

	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

	# VSync
	var vsync_mode = DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

	# MSAA
	var viewport = get_viewport()
	if viewport:
		match msaa_value:
			0: viewport.msaa_3d = Viewport.MSAA_DISABLED
			1: viewport.msaa_3d = Viewport.MSAA_2X
			2: viewport.msaa_3d = Viewport.MSAA_4X
			3: viewport.msaa_3d = Viewport.MSAA_8X
