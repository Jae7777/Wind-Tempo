# scripts/Note.gd
extends Node2D

@export var speed: float = 250.0
var lane: int = 0  # <- set by the spawner

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 50.0:
		queue_free()
