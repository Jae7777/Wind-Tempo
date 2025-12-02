# scripts/Note.gd
extends Node2D

@export var speed: float = 250.0
var lane: int = 0  # <- set by the spawner
var note_name: String = ""  # <- set by the spawner (e.g., "C4")

@onready var note_label: Label = $NoteLabel

func _ready() -> void:
	if note_label and note_name != "":
		note_label.text = note_name

func set_note_name(name: String) -> void:
	note_name = name
	if note_label:
		note_label.text = name

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 50.0:
		queue_free()
