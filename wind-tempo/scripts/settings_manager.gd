# scripts/settings_manager.gd
extends Node

# Settings values
var note_travel_time: float = 2.0
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var window_mode: int = 0 # 0: Windowed, 1: Fullscreen
var vsync_enabled: bool = true
var msaa_value: int = 0 # 0: Disabled, 1: 2x, 2: 4x, 3: 8x

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		# Gameplay
		note_travel_time = config.get_value("gameplay", "note_travel_time", 2.0)
		
		# Audio
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		
		# Graphics
		window_mode = config.get_value("graphics", "window_mode", 0)
		vsync_enabled = config.get_value("graphics", "vsync", true)
		msaa_value = config.get_value("graphics", "msaa", 0)
	
	# Apply loaded settings
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
	
	config.save("user://settings.cfg")
	
	# Apply settings
	apply_settings()

func apply_settings() -> void:
	_apply_audio_settings()
	_apply_graphics_settings()
	
	# Sync with SongManager if it exists
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
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
