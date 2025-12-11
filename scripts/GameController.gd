extends Node

"""
GameController manages overall game flow, state transitions, and coordination
between chart selection, playback, and scoring systems.
"""

enum GameState { MENU, PLAYING, PAUSED, RESULTS }

var current_state: GameState = GameState.MENU
var chart_library: Node
var chart_spawner: Node
var chart_loader: Node
var judgment_system: Node
var input_handler: Node

var current_chart_index: int = 0
var session_stats: Dictionary = {}

signal state_changed(new_state: GameState)
signal chart_selected(chart_entry: Node)
signal results_ready(stats: Dictionary)

func _ready() -> void:
	var parent = get_parent()
	chart_library = parent.get_node_or_null("ChartLibrary")
	chart_spawner = parent.get_node_or_null("ChartSpawner")
	chart_loader = parent.get_node_or_null("ChartLoader")
	judgment_system = parent.get_node_or_null("JudgmentSystem")
	input_handler = parent.get_node_or_null("InputHandler")
	
	if chart_library:
		chart_library.print_library()

func select_chart(index: int) -> bool:
	"""Select a chart for playback."""
	if not chart_library:
		return false
	
	var entry = chart_library.get_chart_by_index(index)
	if not entry:
		return false
	
	current_chart_index = index
	if chart_spawner:
		var success = chart_spawner.load_chart(entry.file_path)
		if success:
			emit_signal("chart_selected", entry)
			print("Selected: %s" % entry.get_title())
			return true
	
	return false

func start_game() -> void:
	"""Start gameplay with currently selected chart."""
	if chart_spawner:
		set_state(GameState.PLAYING)
		chart_spawner.start_spawning()
		print("Game started")

func pause_game() -> void:
	"""Pause current game."""
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
		if chart_spawner:
			chart_spawner.stop_spawning()
		print("Game paused")

func resume_game() -> void:
	"""Resume paused game."""
	if current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)
		if chart_spawner:
			chart_spawner.start_spawning()
		print("Game resumed")

func end_game() -> void:
	"""End current game and show results."""
	set_state(GameState.RESULTS)
	if chart_spawner:
		chart_spawner.stop_spawning()
	
	if judgment_system:
		session_stats = judgment_system.get_stats()
		emit_signal("results_ready", session_stats)
		_print_results()

func return_to_menu() -> void:
	"""Return to menu."""
	set_state(GameState.MENU)
	if judgment_system:
		judgment_system.reset()
	if chart_spawner:
		chart_spawner.reset()
	print("Returned to menu")

func set_state(new_state: GameState) -> void:
	"""Set game state."""
	current_state = new_state
	emit_signal("state_changed", new_state)

func get_state() -> GameState:
	"""Get current game state."""
	return current_state

func get_state_string() -> String:
	"""Get readable state name."""
	match current_state:
		GameState.MENU:
			return "MENU"
		GameState.PLAYING:
			return "PLAYING"
		GameState.PAUSED:
			return "PAUSED"
		GameState.RESULTS:
			return "RESULTS"
	return "UNKNOWN"

func _print_results() -> void:
	"""Print game results to console."""
	print("\n=== GAME RESULTS ===")
	print("Score: %d" % session_stats.get("score", 0))
	print("Accuracy: %.1f%%" % session_stats.get("accuracy", 0))
	print("Combo: %d / %d" % [
		session_stats.get("combo", 0),
		session_stats.get("max_combo", 0)
	])
	print("Notes: %d / %d" % [
		session_stats.get("hit_notes", 0),
		session_stats.get("total_notes", 0)
	])
