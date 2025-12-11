extends Node2D

@onready var highway = $Highway
@onready var spawner = $Spawner
@onready var input_handler = $InputHandler
@onready var hud = $HUD
@onready var hit_detector = $HitDetector
@onready var judgment_system = $JudgmentSystem

func _ready() -> void:
	# Wire up signal connections
	if input_handler.has_signal("note_hit"):
		input_handler.connect("note_hit", hit_detector, "process_input_hit")
	
	if hit_detector.has_signal("note_hit_result"):
		hit_detector.connect("note_hit_result", self, "_on_hit_result")
	
	if judgment_system.has_signal("score_changed"):
		judgment_system.connect("score_changed", hud, "set_score")
	
	if judgment_system.has_signal("combo_changed"):
		judgment_system.connect("combo_changed", hud, "set_combo")
	
	if judgment_system.has_signal("judgment_received"):
		judgment_system.connect("judgment_received", hud, "show_judgment")

func _on_hit_result(judgment: String, lane: int) -> void:
	"""Handle the result of a hit detection."""
	# HUD will show judgment via signal from judgment_system
	# This can be extended for additional logic (animations, sounds, etc.)
	print("Hit! Judgment: %s, Lane: %d" % [judgment, lane])
