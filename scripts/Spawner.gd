extends Node

"""
Legacy Spawner for manual note spawning.
Kept for backward compatibility; ChartSpawner is the primary spawner for chart-based gameplay.
"""

@export var note_scene: PackedScene
@export var lanes := [100, 220, 340, 460]

func spawn(lane_index: int) -> void:
	"""Manually spawn a note at a specific lane."""
	if not note_scene:
		return
	var note = note_scene.instantiate()
	note.lane = lane_index
	note.position = Vector2(lanes[lane_index], -120)
	
	var highway = get_parent().get_node_or_null("Highway")
	if highway:
		highway.add_child(note)
	else:
		get_parent().add_child(note)

func _ready() -> void:
	pass
