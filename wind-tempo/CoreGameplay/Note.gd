# Note.gd
extends Node2D

@export var speed: float = 300.0
var can_be_hit: bool = false

func _process(delta: float) -> void:
	position.y += speed * delta
	
	# Check if note is within hit window
	var hit_line_y = 600.0
	var hit_window = 30.0         # how many pixels above/below counts as a hit
	
	can_be_hit = abs(position.y - hit_line_y) <= hit_window

	# If it falls past the screen, remove
	var viewport_size = get_viewport_rect().size
	if position.y > viewport_size.y:
		queue_free()
