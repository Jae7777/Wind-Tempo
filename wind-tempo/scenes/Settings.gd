# scenes/Settings.gd
extends Control

@export var midi_device_list: ItemList
@export var refresh_button: Button 
@export var back_button: Button
@export var note_speed_slider: HSlider
@export var note_speed_label: Label
@export var volume_slider: HSlider 
@export var volume_label: Label 

# Settings values
var note_travel_time: float = 2.0
var master_volume: float = 1.0

func _ready() -> void:
	refresh_button.pressed.connect(_on_refresh_pressed)
	back_button.pressed.connect(_on_back_pressed)
	note_speed_slider.value_changed.connect(_on_note_speed_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Load current settings
	_load_settings()
	_refresh_midi_devices()
	_update_ui()

func _load_settings() -> void:
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		note_travel_time = song_manager.note_travel_time
	
	# Load from config if exists
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		note_travel_time = config.get_value("gameplay", "note_travel_time", 2.0)
		master_volume = config.get_value("audio", "master_volume", 1.0)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("gameplay", "note_travel_time", note_travel_time)
	config.set_value("audio", "master_volume", master_volume)
	config.save("user://settings.cfg")
	
	# Apply to SongManager
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		song_manager.note_travel_time = note_travel_time
	
	# Apply volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func _update_ui() -> void:
	note_speed_slider.value = note_travel_time
	note_speed_label.text = "%.1fs" % note_travel_time
	
	volume_slider.value = master_volume
	volume_label.text = "%d%%" % int(master_volume * 100)

func _refresh_midi_devices() -> void:
	midi_device_list.clear()
	
	var midi_input = get_node_or_null("/root/MidiInput")
	if midi_input:
		midi_input.refresh_midi_devices()
		
		if midi_input.available_devices.size() == 0:
			midi_device_list.add_item("No MIDI devices found")
			midi_device_list.set_item_disabled(0, true)
		else:
			for device_name in midi_input.available_devices:
				midi_device_list.add_item("🎹 " + device_name)
	else:
		midi_device_list.add_item("MIDI system not available")
		midi_device_list.set_item_disabled(0, true)

func _on_refresh_pressed() -> void:
	_refresh_midi_devices()

func _on_note_speed_changed(value: float) -> void:
	note_travel_time = value
	note_speed_label.text = "%.1fs" % note_travel_time
	_save_settings()

func _on_volume_changed(value: float) -> void:
	master_volume = value
	volume_label.text = "%d%%" % int(master_volume * 100)
	_save_settings()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
