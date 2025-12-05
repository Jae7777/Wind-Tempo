extends Node2D

class_name HoldNote

signal hit_start(note)
signal hit_end(note)
signal missed(note)

@export var lane: int = 0
@export var speed: float = 400.0
@export var hold_duration: float = 1.0

var is_holding: bool = false
var hold_start_time: float = 0.0
var visual_length: float = 0.0

@onready var head_sprite = $Head
@onready var body_sprite = $Body
@onready var tail_sprite = $Tail

func _ready() -> void:
	# Calculate visual length based on duration and speed
	visual_length = hold_duration * speed
	
	# Position body and tail
	if body_sprite:
		body_sprite.scale.y = visual_length / 32.0  # Adjust based on sprite size
		body_sprite.position.y = visual_length / 2.0
	
	if tail_sprite:
		tail_sprite.position.y = visual_length

func _process(delta: float) -> void:
	# Move downward
	position.y += speed * delta
	
	# Check if note passed without being hit
	if not is_holding and position.y > get_viewport().get_visible_rect().size.y + 100:
		emit_signal("missed", self)
		queue_free()

func is_hittable_start(hit_y: float, tolerance: float) -> bool:
	# Check if head is within hit tolerance
	return abs(position.y - hit_y) <= tolerance

func is_hittable_end(hit_y: float, tolerance: float) -> bool:
	# Check if tail is within hit tolerance
	var tail_y = position.y + visual_length
	return abs(tail_y - hit_y) <= tolerance

func on_hit_start() -> void:
	is_holding = true
	hold_start_time = Time.get_ticks_msec() / 1000.0
	emit_signal("hit_start", self)
	# Visual feedback for holding
	if head_sprite:
		head_sprite.modulate = Color(0.2, 1.0, 0.2, 1.0)

func on_hit_end() -> void:
	emit_signal("hit_end", self)
	queue_free()

func on_release_early() -> void:
	# Player released too early
	emit_signal("missed", self)
	queue_free()

func update_hold_visual(current_y: float) -> void:
	# Shrink the body as the hold progresses
	if is_holding and body_sprite:
		var consumed_length = max(0, current_y - position.y)
		var remaining_length = max(0, visual_length - consumed_length)
		body_sprite.scale.y = remaining_length / 32.0
		body_sprite.position.y = consumed_length + remaining_length / 2.0
