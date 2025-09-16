# Note.gd
extends Node2D

@export var speed: float = 300.0  # pixels per second

func _process(delta: float) -> void:
	position.y += speed * delta
