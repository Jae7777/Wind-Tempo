extends Node

@export var note_scene: PackedScene
@export var lanes := [100, 220, 340, 460]

func spawn(lane_index: int) -> void:
    if not note_scene:
        return
    var note = note_scene.instantiate()
    note.lane = lane_index
    note.position = Vector2(lanes[lane_index], -120)
    get_parent().add_child(note)

func _ready() -> void:
    pass
