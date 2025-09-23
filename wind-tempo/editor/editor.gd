extends Control

@onready var audio_player = $AudioStreamPlayer
@onready var file_dialog = $FileDialog
@onready var load_audio_button = $VBoxContainer/MenuBar/LoadAudioButton
@onready var load_track_button = $VBoxContainer/MenuBar/LoadTrackButton
@onready var save_track_button = $VBoxContainer/MenuBar/SaveTrackButton
@onready var play_button = $VBoxContainer/Playback/PlayButton
@onready var pause_button = $VBoxContainer/Playback/PauseButton
@onready var timeline_slider = $VBoxContainer/Playback/TimelineSlider
@onready var title_edit = $VBoxContainer/Metadata/TitleEdit
@onready var artist_edit = $VBoxContainer/Metadata/ArtistEdit
@onready var bpm_edit = $VBoxContainer/Metadata/BPMEdit
@onready var timeline = $VBoxContainer/TimelineContainer/Timeline


var current_bpm: float = 120.0
var pixels_per_beat: float = 50.0
var num_lanes: int = 4
var lane_width: float = 100.0

var track_notes: Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	load_audio_button.pressed.connect(_on_load_audio_pressed)
	load_track_button.pressed.connect(_on_load_track_pressed)
	save_track_button.pressed.connect(_on_save_track_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	play_button.pressed.connect(audio_player.play)
	pause_button.pressed.connect(audio_player.stop)
	timeline_slider.value_changed.connect(_on_timeline_slider_changed)
	bpm_edit.text_submitted.connect(_on_bpm_changed)
	timeline.draw.connect(_on_timeline_draw)
	timeline.gui_input.connect(_on_timeline_gui_input)

	bpm_edit.text = str(current_bpm)


var current_mode = "" # "load_audio", "load_track", "save_track"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if audio_player.stream and audio_player.playing:
		timeline_slider.value = audio_player.get_playback_position()


func _on_load_audio_pressed():
	current_mode = "load_audio"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.ogg ; Ogg Vorbis"])
	file_dialog.popup_centered()


func _on_load_track_pressed():
	current_mode = "load_track"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.json ; Track File"])
	file_dialog.popup_centered()


func _on_save_track_pressed():
	current_mode = "save_track"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.filters = PackedStringArray(["*.json ; Track File"])
	file_dialog.popup_centered()


func _on_file_selected(path: String):
	match current_mode:
		"load_audio":
			var audio_file = load(path)
			if audio_file and audio_file is AudioStream:
				audio_player.stream = audio_file
				timeline_slider.max_value = audio_file.get_length()
				print("Successfully loaded audio: ", path)
				timeline.queue_redraw()
			else:
				print("Failed to load audio file: ", path)
		"load_track":
			_load_track_data(path)
		"save_track":
			_save_track_data(path)


func _save_track_data(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Error saving file: ", FileAccess.get_open_error())
		return

	var track_data = {
		"metadata": {
			"title": title_edit.text,
			"artist": artist_edit.text
		},
		"audio": {
			"filePath": audio_player.stream.resource_path if audio_player.stream else ""
		},
		"sync": {
			"offset": 0.0,
			"timingPoints": [
				{"beat": 0, "bpm": current_bpm}
			]
		},
		"notes": track_notes
	}

	var json_string = JSON.stringify(track_data, "\t")
	file.store_string(json_string)
	file.close()
	print("Track saved successfully to: ", path)


func _load_track_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		print("Error parsing JSON: ", json.get_error_message())
		return

	var data = json.get_data()

	# Populate UI
	title_edit.text = data.metadata.title
	artist_edit.text = data.metadata.artist
	bpm_edit.text = str(data.sync.timingPoints[0].bpm)
	_on_bpm_changed(bpm_edit.text)

	# Load Audio
	var audio_path = data.audio.filePath
	if not audio_path.is_empty():
		_on_file_selected(audio_path) # Recursively call to load audio
	
	# Load Notes
	track_notes = data.notes
	timeline.queue_redraw()
	print("Track loaded successfully from: ", path)


func _on_timeline_slider_changed(value: float):
	if audio_player.stream:
		audio_player.seek(value)


func _on_bpm_changed(new_text: String):
	if new_text.is_valid_float():
		current_bpm = new_text.to_float()
		timeline.queue_redraw()
	else:
		bpm_edit.text = str(current_bpm) # Revert if input is invalid


func _on_timeline_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var lane = floor(event.position.x / lane_width)
		if lane < 0 or lane >= num_lanes:
			return

		# Snap to the nearest 1/4 beat
		var beat = round((event.position.y / pixels_per_beat) * 4.0) / 4.0

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Add note
			var new_note = {"beat": beat, "lane": lane, "duration": 0}
			track_notes.append(new_note)
			timeline.queue_redraw()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Remove note (find the closest one within a small threshold)
			for i in range(track_notes.size() - 1, -1, -1):
				var note = track_notes[i]
				if note.lane == lane and abs(note.beat - beat) < 0.25:
					track_notes.remove_at(i)
					timeline.queue_redraw()
					break # Remove one at a time


func _on_timeline_draw():
	if not audio_player.stream:
		return

	var song_length_sec = audio_player.stream.get_length()
	var total_beats = song_length_sec * (current_bpm / 60.0)

	var beat_color = Color(0.5, 0.5, 0.5, 0.5)
	var measure_color = Color(0.8, 0.8, 0.8, 0.8)

	for i in range(int(total_beats) + 1):
		var y_pos = i * pixels_per_beat
		var color = measure_color if i % 4 == 0 else beat_color
		
		draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), color, 1.0)

	# --- Draw Notes ---
	var note_color = Color.PALE_VIOLET_RED
	for note in track_notes:
		var x_pos = note.lane * lane_width
		var y_pos = note.beat * pixels_per_beat
		var note_rect = Rect2(x_pos, y_pos - 5, lane_width, 10) # Centered on the beat line
		draw_rect(note_rect, note_color)
