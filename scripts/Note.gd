extends Node2D

# Note properties
var lane: int = 0
var spawn_time: float = 0.0  # Time in song when this note should be hit (seconds)
var is_hit: bool = false
var visual_size = Vector2(60, 20)

@export var speed := 600.0  # pixels per second
@export var hit_zone_y := 900.0  # Y position of the hit zone (bottom of screen)

var hit_zone_tolerance = 80  # pixels above/below hit zone for detection

func _ready() -> void:
	# Draw a simple rectangle for the note
	custom_minimum_size = visual_size
	add_child(_create_visual())

func _process(delta: float) -> void:
	if is_hit:
		return
	
	position.y += speed * delta
	
	# Auto-miss if note passes hit zone by too much
	if position.y > hit_zone_y + 200:
		is_hit = true
		queue_free()

func _create_visual() -> ColorRect:
	"""Create a simple colored rectangle for the note."""
	var rect = ColorRect.new()
	rect.color = Color.CYAN
	rect.size = visual_size
	rect.position = -visual_size / 2
	return rect

func get_time_offset(current_time: float) -> float:
	"""
	Calculate timing offset in milliseconds.
	Negative = early, Positive = late.
	"""
	return (current_time - spawn_time) * 1000.0

func is_in_hit_zone(current_time: float) -> bool:
	"""Check if note is within hit zone tolerance."""
	var offset = get_time_offset(current_time)
	return abs(offset) <= 300.0  # Within 300ms is hittable

func mark_as_hit() -> void:
	"""Mark note as hit and play feedback."""
	is_hit = true
	# Create a simple hit effect
	_play_hit_effect()

func _play_hit_effect() -> void:
	"""Play visual feedback when hit."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()

func get_lane() -> int:
	return lane

func get_spawn_time() -> float:
	return spawn_time
