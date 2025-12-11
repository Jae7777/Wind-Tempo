extends Node2D

"""
VisualFeedback handles on-screen effects for hits and misses.
Displays judgment popups, hit effects, and visual cues.
"""

var judgment_popup_scene: PackedScene
var lane_hit_effects = [
	preload("res://ui/effects/LaneHitEffect.tscn") if ResourceLoader.exists("res://ui/effects/LaneHitEffect.tscn") else null
]

signal effect_started
signal effect_finished

func _ready() -> void:
	# Optional: load pre-made effect scenes if they exist
	pass

func play_lane_hit_effect(lane: int) -> void:
	"""Play a visual effect for a lane hit."""
	if lane < 0 or lane >= 4:
		return
	
	# Create a simple visual pulse at the lane position
	var lane_positions = [100, 220, 340, 460]
	var effect = ColorRect.new()
	effect.color = Color(1.0, 1.0, 1.0, 0.3)
	effect.size = Vector2(60, 30)
	effect.position = Vector2(lane_positions[lane] - 30, 850)
	add_child(effect)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.2)
	await tween.finished
	effect.queue_free()

func play_judgment_popup(judgment: String, position: Vector2) -> void:
	"""Play a popup showing the judgment (Perfect/Great/Good/Miss)."""
	var label = Label.new()
	label.text = judgment
	label.position = position
	label.add_theme_font_size_override("font_size", 32)
	
	# Color based on judgment
	match judgment:
		"Perfect":
			label.add_theme_color_override("font_color", Color.GOLD)
		"Great":
			label.add_theme_color_override("font_color", Color.GREEN)
		"Good":
			label.add_theme_color_override("font_color", Color.YELLOW)
		"Miss":
			label.add_theme_color_override("font_color", Color.RED)
	
	add_child(label)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", position.y - 80, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	label.queue_free()

func shake_screen(duration: float = 0.1, intensity: float = 5.0) -> void:
	"""Screen shake effect for impactful hits."""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_pos = camera.global_position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(int(duration * 60)):
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "global_position", original_pos + offset, duration / 60.0)
	
	tween.tween_property(camera, "global_position", original_pos, 0.1)
