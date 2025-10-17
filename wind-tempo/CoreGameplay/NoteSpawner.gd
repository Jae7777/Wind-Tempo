extends Node

# --- CONFIGURABLE VARIABLES ---
@export var note_scene: PackedScene
@export var spawn_y: float = -50.0
@export var hit_line_y: float = 600.0
@export var note_speed: float = 300.0
@export var lanes: Array[float] = [300.0, 400.0, 500.0]
@export var song_name: String = "song1" # Base name for .ogg + .json files

# --- INTERNALS ---
@onready var music_player: AudioStreamPlayer2D = $"../Music"

var chart: Array = []
var note_index: int = 0
var travel_time: float = 0.0
var is_chart_loaded: bool = false

func _ready() -> void:
	# Compute how long a note takes to reach hit line
	travel_time = (hit_line_y - spawn_y) / note_speed

	var chart_path = "res://charts/%s.json" % song_name
	var song_path = "res://songs/%s.ogg" % song_name

	print("\n[NoteSpawner] Initializing song:", song_name)
	print("[NoteSpawner] Travel time:", travel_time)

	# Load data
	_load_chart(chart_path)
	_load_song(song_path)

	# Only start playback if everything loaded correctly
	if is_chart_loaded and music_player.stream:
		print("[NoteSpawner] Starting song after delay of %.2f s" % travel_time)
		music_player.play(travel_time)
	else:
		push_error("Cannot start song — chart or audio missing.")


func _process(delta: float) -> void:
	if not is_chart_loaded or note_index >= chart.size():
		return

	var song_time := music_player.get_playback_position()
	var next_note: Dictionary = chart[note_index]

	var note_time: float = float(next_note.get("time", 0.0))
	var lane: int = int(next_note.get("lane", 0))

	# Spawn early so note reaches hit line on beat
	if song_time >= note_time - travel_time:
		spawn_note(lane)
		note_index += 1


func spawn_note(lane: int) -> void:
	if not note_scene:
		push_error("Note scene not assigned.")
		return

	if lane < 0 or lane >= lanes.size():
		push_warning("Invalid lane index: %d" % lane)
		return

	var note := note_scene.instantiate()
	note.position = Vector2(lanes[lane], spawn_y)
	note.add_to_group("note")
	add_child(note)

	print("[NoteSpawner] Spawned note at lane %d (y = %.1f)" % [lane, spawn_y])


func _load_chart(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Chart file not found: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open chart file: %s" % path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("notes"):
		chart = parsed["notes"]
		is_chart_loaded = true
		print("[NoteSpawner] Loaded chart '%s' with %d notes" % [path, chart.size()])
	else:
		push_error("Invalid chart format in: %s" % path)


func _load_song(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("Song file not found: %s" % path)
		return

	var song := load(path)
	music_player.stream = song
	print("[NoteSpawner] Loaded song:", path)
