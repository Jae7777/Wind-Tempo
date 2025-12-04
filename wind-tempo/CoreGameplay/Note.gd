extends Node2D

class_name Note

signal hit(note)

@export var lane: int = 0
@export var speed: float = 400.0

func _process(delta: float) -> void:
	# simple downward movement
	position.y += speed * delta

func is_hittable(hit_y: float, tolerance: float) -> bool:
	return abs(position.y - hit_y) <= tolerance

func on_hit() -> void:
	emit_signal("hit", self)
	queue_free()
