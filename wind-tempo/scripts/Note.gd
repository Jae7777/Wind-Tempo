# scripts/Note.gd
extends Node2D

@export var speed: float = 250.0  # pixels per second

func _process(delta: float) -> void:
	position.y += speed * delta
	# Despawn if it goes off-screen
	if position.y > get_viewport_rect().size.y + 50.0:
		queue_free()
