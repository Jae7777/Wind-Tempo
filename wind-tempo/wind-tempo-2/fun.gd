# FeedbackManager.gd
extends Node

@onready var camera_ref: Camera2D = get_viewport().get_camera_2d()
@onready var ui_manager = $"../UIManager"

# --- Shake Variables ---
const SHAKE_INTENSITY_PERFECT: float = 10.0
const SHAKE_DURATION: float = 0.1

# --- Called by HitDetector.gd ---
func trigger_hit_feedback(quality: String, lane_index: int):
	
	# 1. Screen Shake
	match quality:
		"PERFECT":
			start_shake(SHAKE_INTENSITY_PERFECT, SHAKE_DURATION)
		"GREAT":
			start_shake(SHAKE_INTENSITY_PERFECT / 2.0, SHAKE_DURATION)

func start_shake(intensity: float, duration: float):
	if not is_instance_valid(camera_ref):
		return
		
	var tween = create_tween()
	# Shake camera position randomly for the duration
	tween.tween_property(camera_ref, "offset", Vector2.ZERO, 0.0).from(Vector2.ZERO) # Reset first
	tween.tween_property(camera_ref, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), duration)
	tween.tween_property(camera_ref, "offset", Vector2.ZERO, duration) # Smooth back to center
