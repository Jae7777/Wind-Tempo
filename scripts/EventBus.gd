extends Node

"""
EventBus provides a centralized event system for game-wide communication.
Decouples systems through signal broadcasting.
"""

signal game_started
signal game_paused
signal game_resumed
signal game_ended
signal note_spawned(note: Node2D, lane: int)
signal note_hit(judgment: String, lane: int)
signal note_missed(lane: int)
signal score_changed(score: int)
signal combo_changed(combo: int)
signal accuracy_updated(accuracy: float)
signal settings_changed(key: String, value)
signal chart_loaded(chart: Node)
signal difficulty_changed(difficulty: String)

var _instance: Node = null

func _ready() -> void:
	pass

func emit_game_started() -> void:
	emit_signal("game_started")

func emit_game_paused() -> void:
	emit_signal("game_paused")

func emit_game_resumed() -> void:
	emit_signal("game_resumed")

func emit_game_ended() -> void:
	emit_signal("game_ended")

func emit_note_spawned(note: Node2D, lane: int) -> void:
	emit_signal("note_spawned", note, lane)

func emit_note_hit(judgment: String, lane: int) -> void:
	emit_signal("note_hit", judgment, lane)

func emit_note_missed(lane: int) -> void:
	emit_signal("note_missed", lane)

func emit_score_changed(score: int) -> void:
	emit_signal("score_changed", score)

func emit_combo_changed(combo: int) -> void:
	emit_signal("combo_changed", combo)

func emit_accuracy_updated(accuracy: float) -> void:
	emit_signal("accuracy_updated", accuracy)

func emit_settings_changed(key: String, value) -> void:
	emit_signal("settings_changed", key, value)

func emit_chart_loaded(chart: Node) -> void:
	emit_signal("chart_loaded", chart)

func emit_difficulty_changed(difficulty: String) -> void:
	emit_signal("difficulty_changed", difficulty)

func subscribe(signal_name: String, target: Node, callback: String) -> void:
	"""Subscribe to a bus signal."""
	if has_signal(signal_name):
		connect(signal_name, Callable(target, callback))

func unsubscribe(signal_name: String, target: Node, callback: String) -> void:
	"""Unsubscribe from a bus signal."""
	if has_signal(signal_name) and is_connected(signal_name, Callable(target, callback)):
		disconnect(signal_name, Callable(target, callback))
