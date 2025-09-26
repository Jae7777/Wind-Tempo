# Note.gd
extends Node2D

@export var speed: float = 300.0

func _process(delta: float) -> void:
	position.y += speed * delta
	
	var viewport_size = get_viewport_rect().size
	if position.y > viewport_size.y:
		queue_free()
