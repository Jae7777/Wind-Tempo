extends Node

signal note_spawned(note)

@export var note_scene: PackedScene
@export var hold_note_scene: PackedScene
@export var spawn_y: float = -50.0
@export var lanes_x: Array = [150.0, 300.0, 450.0, 600.0]

var chart: Array = [] # array of dictionaries: {"time":float, "lane":int, "type":"normal"/"hold", "duration":float}
var time_elapsed: float = 0.0
var next_index: int = 0

func _process(delta: float) -> void:
	time_elapsed += delta
	while next_index < chart.size() and chart[next_index]["time"] <= time_elapsed:
		var data = chart[next_index]
		var note = null
		
		# Check if it's a hold note
		if data.has("type") and data["type"] == "hold":
			if hold_note_scene:
				note = hold_note_scene.instantiate()
				if data.has("duration"):
					note.hold_duration = data["duration"]
			else:
				# Fallback to regular note if hold scene not set
				note = note_scene.instantiate()
		else:
			note = note_scene.instantiate()
		
		note.position = Vector2(lanes_x[data["lane"]], spawn_y)
		note.lane = data["lane"]
		get_parent().add_child(note)
		emit_signal("note_spawned", note)
		
		var note_type = "hold" if (data.has("type") and data["type"] == "hold") else "normal"
		print("[NoteSpawner] Spawned %s note lane=%s at pos=%s time=%.2f" % [note_type, str(note.lane), str(note.position), time_elapsed])
		next_index += 1

func reset() -> void:
	time_elapsed = 0.0
	next_index = 0
