extends Node

@export var note_scene: PackedScene
@export var spawn_y: float = -50.0
@export var hit_line_y: float = 600.0
@export var note_speed: float = 300.0
@export var lanes: Array[float] = [300.0, 400.0, 500.0] # x positions of lanes
@export var chart_file: String = "res://charts/song1.json"

@onready var music_player: AudioStreamPlayer2D = $"../Music"

var chart: Array = []
var note_index: int = 0
var travel_time: float

func _ready():
	travel_time = (hit_line_y - spawn_y) / note_speed
	_load_chart(chart_file)
	music_player.play()

func _process(delta: float) -> void:
	if music_player.playing and note_index < chart.size():
		var song_time = music_player.get_playback_position()
		var next_note = chart[note_index]

		# Spawn early so the note reaches hit line exactly on time
		if song_time >= next_note.time - travel_time:
			spawn_note(next_note.lane)
			note_index += 1

func spawn_note(lane: int):
	if note_scene and lane >= 0 and lane < lanes.size():
		var note = note_scene.instantiate()
		note.position = Vector2(lanes[lane], spawn_y)
		add_child(note)

func _load_chart(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY and data.has("notes"):
			chart = data["notes"]
		else:
			push_error("Invalid chart file format")
	else:
		push_error("Could not load chart file: %s" % path)
