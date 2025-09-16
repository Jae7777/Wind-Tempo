extends Node

@export var note_scene: PackedScene
@export var spawn_x: float = 400.0  # x position of the note lane
@export var spawn_y: float = -50.0  # spawn above screen
@export var spawn_interval: float = 1.0  # seconds between spawns

var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_note()

func spawn_note() -> void:
	if note_scene:
		var note = note_scene.instantiate()
		note.position = Vector2(spawn_x, spawn_y)
		add_child(note)
