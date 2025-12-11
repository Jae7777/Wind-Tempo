extends Node

"""
PracticeMode provides isolated practice environment with advanced features.
Supports slow-down, looping, hitbox visualization, and detailed feedback.
"""

class PracticeSession:
	var chart_path: String
	var current_section: int = 0
	var playback_speed: float = 1.0
	var loop_section: bool = false
	var section_start: float = 0.0
	var section_end: float = 0.0
	var show_hitboxes: bool = true
	var show_timing_window: bool = true
	var auto_play: bool = false
	
	func _init(p_chart_path: String) -> void:
		chart_path = p_chart_path

var current_session: PracticeSession = null
var practice_stats: Dictionary = {}

signal practice_started(chart_path: String)
signal practice_ended(stats: Dictionary)
signal speed_changed(speed: float)
signal section_changed(section: int)
signal hitbox_visibility_changed(visible: bool)
signal stats_updated(stats: Dictionary)

func _ready() -> void:
	"""Initialize practice mode."""
	pass

func start_practice(chart_path: String) -> void:
	"""Start a practice session."""
	current_session = PracticeSession.new(chart_path)
	practice_stats = {
		"chart": chart_path,
		"start_time": Time.get_ticks_msec(),
		"total_plays": 0,
		"best_accuracy": 0.0,
		"average_accuracy": 0.0,
		"attempt_history": []
	}
	
	emit_signal("practice_started", chart_path)

func end_practice(session_stats: Dictionary) -> void:
	"""End the practice session."""
	if current_session == null:
		return
	
	practice_stats["end_time"] = Time.get_ticks_msec()
	practice_stats["duration"] = (practice_stats["end_time"] - practice_stats["start_time"]) / 1000.0
	practice_stats["total_plays"] += 1
	
	var accuracy = session_stats.get("accuracy", 0.0)
	practice_stats["attempt_history"].append({
		"accuracy": accuracy,
		"score": session_stats.get("score", 0),
		"combo": session_stats.get("max_combo", 0),
		"timestamp": Time.get_ticks_msec()
	})
	
	if accuracy > practice_stats["best_accuracy"]:
		practice_stats["best_accuracy"] = accuracy
	
	if practice_stats["total_plays"] > 0:
		var total_accuracy = 0.0
		for attempt in practice_stats["attempt_history"]:
			total_accuracy += attempt["accuracy"]
		practice_stats["average_accuracy"] = total_accuracy / practice_stats["attempt_history"].size()
	
	emit_signal("stats_updated", practice_stats)
	emit_signal("practice_ended", practice_stats)

func set_playback_speed(speed: float) -> void:
	"""Set playback speed multiplier (0.5x to 1.5x)."""
	if current_session == null:
		return
	
	speed = clamp(speed, 0.5, 1.5)
	current_session.playback_speed = speed
	emit_signal("speed_changed", speed)

func get_playback_speed() -> float:
	"""Get current playback speed."""
	return current_session.playback_speed if current_session else 1.0

func set_loop_section(enabled: bool) -> void:
	"""Enable/disable looping for a section."""
	if current_session == null:
		return
	
	current_session.loop_section = enabled

func is_loop_enabled() -> bool:
	"""Check if section looping is enabled."""
	return current_session.loop_section if current_session else false

func set_section_bounds(start: float, end: float) -> void:
	"""Set the start and end time for a practice section."""
	if current_session == null:
		return
	
	current_session.section_start = start
	current_session.section_end = end

func get_section_bounds() -> Dictionary:
	"""Get current section bounds."""
	if current_session == null:
		return {"start": 0.0, "end": 0.0}
	
	return {
		"start": current_session.section_start,
		"end": current_session.section_end
	}

func toggle_hitbox_visibility() -> void:
	"""Toggle hitbox visualization."""
	if current_session == null:
		return
	
	current_session.show_hitboxes = not current_session.show_hitboxes
	emit_signal("hitbox_visibility_changed", current_session.show_hitboxes)

func is_hitbox_visible() -> bool:
	"""Check if hitboxes are visible."""
	return current_session.show_hitboxes if current_session else true

func toggle_timing_window_display() -> void:
	"""Toggle timing window visualization."""
	if current_session == null:
		return
	
	current_session.show_timing_window = not current_session.show_timing_window

func is_timing_window_visible() -> bool:
	"""Check if timing windows are visible."""
	return current_session.show_timing_window if current_session else true

func enable_auto_play(enabled: bool) -> void:
	"""Enable/disable automatic note hitting for learning."""
	if current_session == null:
		return
	
	current_session.auto_play = enabled

func is_auto_play_enabled() -> bool:
	"""Check if auto-play is enabled."""
	return current_session.auto_play if current_session else false

func get_practice_stats() -> Dictionary:
	"""Get statistics from current practice session."""
	return practice_stats.duplicate()

func get_improvement_stats() -> Dictionary:
	"""Get improvement data from attempts."""
	if practice_stats.get("attempt_history", []).is_empty():
		return {}
	
	var history = practice_stats["attempt_history"]
	var accuracies = []
	
	for attempt in history:
		accuracies.append(attempt["accuracy"])
	
	if accuracies.is_empty():
		return {}
	
	accuracies.sort()
	
	var improvement = 0.0
	if history.size() > 1:
		improvement = history[-1]["accuracy"] - history[0]["accuracy"]
	
	return {
		"first_attempt_accuracy": history[0]["accuracy"] if history.size() > 0 else 0.0,
		"last_attempt_accuracy": history[-1]["accuracy"] if history.size() > 0 else 0.0,
		"best_accuracy": practice_stats.get("best_accuracy", 0.0),
		"average_accuracy": practice_stats.get("average_accuracy", 0.0),
		"improvement": improvement,
		"total_attempts": history.size(),
		"median_accuracy": accuracies[accuracies.size() / 2] if not accuracies.is_empty() else 0.0
	}

func reset_session() -> void:
	"""Reset the current practice session."""
	current_session = null
	practice_stats.clear()

func export_practice_data() -> Dictionary:
	"""Export practice session data for analysis."""
	return {
		"session_info": {
			"chart": current_session.chart_path if current_session else "",
			"start_time": practice_stats.get("start_time", 0),
			"duration": practice_stats.get("duration", 0)
		},
		"statistics": get_improvement_stats(),
		"attempts": practice_stats.get("attempt_history", [])
	}

func get_practice_tips() -> Array:
	"""Get practice tips based on performance."""
	var tips = []
	var stats = get_improvement_stats()
	
	if stats.is_empty():
		return ["Start your first attempt to get tips!"]
	
	var accuracy = stats.get("last_attempt_accuracy", 0.0)
	
	if accuracy < 0.60:
		tips.append("Try slowing down the playback speed to improve timing")
		tips.append("Use the hitbox visualization to see timing windows")
	elif accuracy < 0.80:
		tips.append("You're making progress! Keep practicing")
		tips.append("Focus on consistent timing between attempts")
	elif accuracy < 0.95:
		tips.append("Great! You're nearly there")
		tips.append("Try looping difficult sections for targeted practice")
	else:
		tips.append("Excellent accuracy! You've mastered this chart")
		tips.append("Try a harder difficulty to challenge yourself")
	
	if stats.get("improvement", 0.0) > 0.05:
		tips.append("You're showing improvement - keep it up!")
	
	return tips
