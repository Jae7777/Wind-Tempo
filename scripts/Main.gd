extends Node2D

@onready var highway = $Highway
@onready var spawner = $Spawner
@onready var input_handler = $InputHandler
@onready var hud = $HUD
@onready var hit_detector = $HitDetector
@onready var judgment_system = $JudgmentSystem
@onready var chart_loader = $ChartLoader
@onready var chart_spawner = $ChartSpawner

var is_playing: bool = false

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
	
	if chart_loader and chart_loader.has_signal("chart_loaded"):
		chart_loader.connect("chart_loaded", self, "_on_chart_loaded")

func _input(event: InputEvent) -> void:
	"""Handle game state input."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				toggle_playback()
				get_tree().root.set_input_as_handled()
			KEY_R:
				reset_game()
				get_tree().root.set_input_as_handled()

func toggle_playback() -> void:
	"""Start or stop song playback and note spawning."""
	is_playing = !is_playing
	
	if is_playing:
		print("Game started")
		chart_spawner.start_spawning()
	else:
		print("Game paused")
		chart_spawner.stop_spawning()

func reset_game() -> void:
	"""Reset game state."""
	is_playing = false
	chart_spawner.reset()
	judgment_system.reset()
	print("Game reset")

func _on_hit_result(judgment: String, lane: int) -> void:
	"""Handle the result of a hit detection."""
	# HUD will show judgment via signal from judgment_system
	# This can be extended for additional logic (animations, sounds, etc.)
	print("Hit! Judgment: %s, Lane: %d" % [judgment, lane])

func _on_chart_loaded(chart: Node) -> void:
	"""Handle chart loaded event."""
	print("Chart ready: %s" % chart.get_title())

func get_game_state() -> Dictionary:
	"""Return current game state."""
	return {
		"is_playing": is_playing,
		"stats": judgment_system.get_stats()
	}
