extends Control

# UI Nodes
@export_group("Navigation")
@export var gameplay_btn: Button
@export var graphics_btn: Button
@export var audio_btn: Button
@export var input_btn: Button
@export var back_button: Button

@export_group("Containers")
@export var gameplay_container: Control
@export var graphics_container: Control
@export var audio_container: Control
@export var input_container: Control

@export_group("Input Settings")
@export var midi_device_list: ItemList
@export var refresh_button: Button 

@export_group("Gameplay Settings")
@export var note_speed_slider: HSlider
@export var note_speed_label: Label

@export_group("Audio Settings")
@export var master_volume_slider: HSlider
@export var master_volume_label: Label
@export var music_volume_slider: HSlider
@export var music_volume_label: Label
@export var sfx_volume_slider: HSlider
@export var sfx_volume_label: Label

@export_group("Graphics Settings")
@export var window_mode_btn: OptionButton
@export var vsync_btn: CheckButton
@export var msaa_btn: OptionButton

func _ready() -> void:
	# Navigation connections
	gameplay_btn.pressed.connect(func(): _show_category(gameplay_container))
	graphics_btn.pressed.connect(func(): _show_category(graphics_container))
	audio_btn.pressed.connect(func(): _show_category(audio_container))
	input_btn.pressed.connect(func(): _show_category(input_container))
	back_button.pressed.connect(_on_back_pressed)
	
	# Input connections
	refresh_button.pressed.connect(_on_refresh_pressed)
	
	# Gameplay connections
	note_speed_slider.value_changed.connect(_on_note_speed_changed)
	
	# Audio connections
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Graphics connections
	window_mode_btn.item_selected.connect(_on_window_mode_selected)
	vsync_btn.toggled.connect(_on_vsync_toggled)
	msaa_btn.item_selected.connect(_on_msaa_selected)
	
	# Initialize UI from SettingsManager
	_refresh_midi_devices()
	_update_ui()
	
	# Show default category
	_show_category(gameplay_container)

func _show_category(category: Control) -> void:
	gameplay_container.visible = false
	graphics_container.visible = false
	audio_container.visible = false
	input_container.visible = false
	
	category.visible = true

func _update_ui() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if not sm:
		push_warning("Settings: SettingsManager not found")
		return
	
	# Gameplay
	note_speed_slider.value = sm.note_travel_time
	note_speed_label.text = "%.1fs" % sm.note_travel_time
	
	# Audio
	master_volume_slider.value = sm.master_volume
	master_volume_label.text = "%d%%" % int(sm.master_volume * 100)
	
	music_volume_slider.value = sm.music_volume
	music_volume_label.text = "%d%%" % int(sm.music_volume * 100)
	
	sfx_volume_slider.value = sm.sfx_volume
	sfx_volume_label.text = "%d%%" % int(sm.sfx_volume * 100)
	
	# Graphics
	window_mode_btn.selected = sm.window_mode
	vsync_btn.button_pressed = sm.vsync_enabled
	msaa_btn.selected = sm.msaa_value

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
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.note_travel_time = value
		note_speed_label.text = "%.1fs" % value
		sm.save_settings()

func _on_master_volume_changed(value: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.master_volume = value
		master_volume_label.text = "%d%%" % int(value * 100)
		sm.save_settings()

func _on_music_volume_changed(value: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.music_volume = value
		music_volume_label.text = "%d%%" % int(value * 100)
		sm.save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.sfx_volume = value
		sfx_volume_label.text = "%d%%" % int(value * 100)
		sm.save_settings()

func _on_window_mode_selected(index: int) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.window_mode = index
		sm.save_settings()

func _on_vsync_toggled(toggled_on: bool) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.vsync_enabled = toggled_on
		sm.save_settings()

func _on_msaa_selected(index: int) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.msaa_value = index
		sm.save_settings()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
