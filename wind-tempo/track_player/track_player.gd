extends Node2D

const NOTE_SCENE = preload("res://note/note.tscn")

@onready var audio_player = $AudioStreamPlayer

var track_data: Dictionary

var current_bpm: float = 120.0
var song_position_sec: float = 0.0
var song_position_beat: float = 0.0

# This will store note instances and their data
var notes_on_screen: Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	load_track("res://workshop/example_track.json")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if audio_player.playing:
		# Update song position in seconds
		song_position_sec = audio_player.get_playback_position()
		
		# Convert seconds to beats
		# This is a simplified calculation. It will be more complex with multiple BPMs.
		song_position_beat = song_position_sec * (current_bpm / 60.0)

		# Update note positions
		for note in notes_on_screen:
			# The note's beat determines where it *should* be.
			# The song's current beat determines where the "now" line is.
			# The difference is how far the note is from the target.
			var beat_difference = note.beat - song_position_beat
			
			# Let's say 1 beat = 200 pixels
			note.instance.position.y = beat_difference * -200


func load_track(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		print("Error parsing JSON: ", json.get_error_message(), " at line ", json.get_error_line())
		return

	track_data = json.get_data()

	if track_data:
		# --- Load Audio ---
		var audio_path = track_data.audio.filePath
		var audio_file = load(audio_path)
		if audio_file:
			audio_player.stream = audio_file
			audio_player.play()
		else:
			print("Error loading audio file: ", audio_path)

		# --- Set Initial BPM ---
		if track_data.sync.timingPoints.size() > 0:
			current_bpm = track_data.sync.timingPoints[0].bpm
		
		_spawn_notes()
	else:
		print("Failed to parse track data.")


func _spawn_notes():
	if not track_data.has("notes"):
		return

	for note_info in track_data.notes:
		var note_instance = NOTE_SCENE.instantiate()
		
		var lane_width = 110 #pixels
		note_instance.position.x = note_info.lane * lane_width
		
		add_child(note_instance)
		
		# Store the instance and its beat information
		notes_on_screen.append({
			"instance": note_instance,
			"beat": note_info.beat
		})
