# scenes/SongSelect.gd
extends Control

@onready var song_list: ItemList = $VBoxContainer/SongList
@onready var song_info: Label = $VBoxContainer/InfoPanel/SongInfo
@onready var play_button: Button = $VBoxContainer/ButtonRow/PlayButton
@onready var back_button: Button = $VBoxContainer/ButtonRow/BackButton
@onready var midi_status: Label = $VBoxContainer/MidiStatus

var songs: Array[Dictionary] = []
var selected_index: int = -1

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)
	song_list.item_selected.connect(_on_song_selected)
	song_list.item_activated.connect(_on_song_activated)
	
	# Update MIDI status
	_update_midi_status()
	
	# Scan for songs
	_refresh_song_list()

func _update_midi_status() -> void:
	var midi_input = get_node_or_null("/root/MidiInput")
	if midi_input and midi_input.is_midi_enabled:
		var device_count: int = midi_input.available_devices.size()
		midi_status.text = "🎹 MIDI: %d device(s) connected" % device_count
		midi_status.modulate = Color(0.3, 1.0, 0.3)
	else:
		midi_status.text = "⚠️ MIDI: No devices found (keyboard controls available)"
		midi_status.modulate = Color(1.0, 0.8, 0.3)

func _refresh_song_list() -> void:
	song_list.clear()
	songs.clear()
	
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		songs = song_manager.scan_songs()
	
	# Add demo song option
	song_list.add_item("🎵 Demo Song (Practice)")
	
	# Add found songs with type indicators
	for song_data in songs:
		var type_icon := "🎹" if song_data.get("type", "midi") == "wtrack" else "🎵"
		song_list.add_item("%s %s" % [type_icon, song_data["name"]])
	
	# Update info
	if songs.size() == 0:
		song_info.text = "No songs found.\n\nPlace files in:\n• res://songs/ (.mid files)\n• res://tracks/ (.wtrack files)\n• user://songs/ or user://tracks/\n\nOr use the Workshop to create tracks!\n\nSelect Demo Song to practice."
	else:
		var midi_count := 0
		var track_count := 0
		for s in songs:
			if s.get("type", "midi") == "wtrack":
				track_count += 1
			else:
				midi_count += 1
		song_info.text = "Select a song to play.\n\nFound:\n• %d MIDI file(s)\n• %d custom track(s)" % [midi_count, track_count]

func _on_song_selected(index: int) -> void:
	selected_index = index
	
	if index == 0:
		# Demo song
		song_info.text = "🎵 Demo Song\n\nA simple practice song with\nC major scale patterns.\n\nGreat for testing your setup!\n\nDifficulty: Easy"
	elif index > 0 and index - 1 < songs.size():
		var song_data: Dictionary = songs[index - 1]
		var song_type := "Custom Track" if song_data.get("type", "midi") == "wtrack" else "MIDI File"
		song_info.text = "🎵 %s\n\nType: %s\nPath: %s" % [song_data["name"], song_type, song_data["path"]]
	
	play_button.disabled = false

func _on_song_activated(index: int) -> void:
	# Double-click to play
	_on_song_selected(index)
	_on_play_pressed()

func _on_play_pressed() -> void:
	if selected_index < 0:
		return
	
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager == null:
		push_error("SongManager not found!")
		return
	
	if selected_index == 0:
		# Load demo song
		song_manager.load_demo_song()
	else:
		# Load selected song
		var song_data: Dictionary = songs[selected_index - 1]
		if not song_manager.load_song(song_data["path"]):
			song_info.text = "Failed to load song:\n%s" % song_data["path"]
			return
	
	# Switch to game scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
