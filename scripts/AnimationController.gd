extends Node

"""
AnimationController manages UI animations and transitions.
Handles screen transitions, button animations, and visual feedback.
"""

var animation_speed: float = 0.3

signal animation_started
signal animation_finished

func _ready() -> void:
	pass

func fade_in(target: Control, duration: float = animation_speed) -> void:
	"""Fade in a control."""
	target.modulate.a = 0.0
	target.show()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, duration)

func fade_out(target: Control, duration: float = animation_speed) -> void:
	"""Fade out a control."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, duration)
	await tween.finished
	target.hide()

func slide_in(target: Control, from_dir: String = "left", duration: float = animation_speed) -> void:
	"""Slide in a control from specified direction."""
	var start_pos = target.position
	match from_dir:
		"left":
			target.position.x -= 300
		"right":
			target.position.x += 300
		"top":
			target.position.y -= 300
		"bottom":
			target.position.y += 300
	
	target.show()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", start_pos, duration)

func pulse(target: Control, duration: float = 0.2) -> void:
	"""Pulse animation for emphasis."""
	var original_scale = target.scale
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale * 1.2, duration / 2)
	tween.tween_property(target, "scale", original_scale, duration / 2)

func shake(target: Control, intensity: float = 5.0, duration: float = 0.2) -> void:
	"""Screen shake animation."""
	var original_pos = target.position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(int(duration * 30)):
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(target, "position", original_pos + offset, duration / 30.0)
	
	tween.tween_property(target, "position", original_pos, 0.1)

func bounce(target: Control, distance: float = 20.0, duration: float = 0.4) -> void:
	"""Bounce animation."""
	var original_pos = target.position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position:y", original_pos.y + distance, duration)
	tween.tween_property(target, "position:y", original_pos.y, duration / 2)

func scale_to(target: Control, scale: Vector2, duration: float = animation_speed) -> void:
	"""Scale to target size."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", scale, duration)

func rotate_to(target: Control, angle: float, duration: float = animation_speed) -> void:
	"""Rotate to target angle."""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "rotation", angle, duration)
