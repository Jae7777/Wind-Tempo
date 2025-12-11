extends Node

"""
StatisticsTracker collects and aggregates game statistics for analytics and progression.
Tracks performance across multiple games.
"""

class GameSession:
	var date: String
	var chart_title: String
	var score: int
	var accuracy: float
	var max_combo: int
	var rank: String
	var total_notes: int
	var hit_notes: int
	var missed_notes: int
	var duration: float
	
	func _init(
		_date: String,
		_chart: String,
		_score: int,
		_acc: float,
		_combo: int,
		_rank: String,
		_total: int,
		_hits: int,
		_misses: int,
		_dur: float
	) -> void:
		date = _date
		chart_title = _chart
		score = _score
		accuracy = _acc
		max_combo = _combo
		rank = _rank
		total_notes = _total
		hit_notes = _hits
		missed_notes = _misses
		duration = _dur
	
	func to_string() -> String:
		return "%s | %s | Score: %d | Accuracy: %.1f%% | Rank: %s" % [
			date, chart_title, score, accuracy, rank
		]

var sessions: Array = []
var session_file: String = "user://wind_tempo_stats.json"
var max_sessions_stored: int = 100

signal session_recorded(session: GameSession)
signal stats_loaded

func _ready() -> void:
	load_statistics()

func record_session(
	chart_title: String,
	score: int,
	accuracy: float,
	max_combo: int,
	rank: String,
	total_notes: int,
	hit_notes: int,
	missed_notes: int,
	duration: float
) -> void:
	"""Record a completed game session."""
	var date_str = Time.get_datetime_string_from_system()
	var session = GameSession.new(
		date_str, chart_title, score, accuracy, max_combo, rank,
		total_notes, hit_notes, missed_notes, duration
	)
	
	sessions.append(session)
	
	# Keep only most recent sessions
	if sessions.size() > max_sessions_stored:
		sessions.pop_front()
	
	save_statistics()
	emit_signal("session_recorded", session)
	print("Session recorded: %s" % session.to_string())

func save_statistics() -> void:
	"""Save statistics to file."""
	var data = []
	for session in sessions:
		data.append({
			"date": session.date,
			"chart": session.chart_title,
			"score": session.score,
			"accuracy": session.accuracy,
			"combo": session.max_combo,
			"rank": session.rank,
			"total_notes": session.total_notes,
			"hit_notes": session.hit_notes,
			"missed_notes": session.missed_notes,
			"duration": session.duration
		})
	
	var file = FileAccess.open(session_file, FileAccess.WRITE)
	if file:
		file.store_var(data)
		print("Statistics saved")

func load_statistics() -> void:
	"""Load statistics from file."""
	if not ResourceLoader.exists(session_file):
		print("No statistics file found")
		return
	
	var file = FileAccess.open(session_file, FileAccess.READ)
	if not file:
		return
	
	var data = file.get_var()
	sessions.clear()
	
	for session_data in data:
		var session = GameSession.new(
			session_data["date"],
			session_data["chart"],
			session_data["score"],
			session_data["accuracy"],
			session_data["combo"],
			session_data["rank"],
			session_data["total_notes"],
			session_data["hit_notes"],
			session_data["missed_notes"],
			session_data["duration"]
		)
		sessions.append(session)
	
	emit_signal("stats_loaded")
	print("Loaded %d sessions" % sessions.size())

func get_best_score(chart_title: String = "") -> int:
	"""Get best score for a chart (or overall if empty)."""
	var best = 0
	for session in sessions:
		if chart_title == "" or session.chart_title == chart_title:
			best = max(best, session.score)
	return best

func get_best_accuracy(chart_title: String = "") -> float:
	"""Get best accuracy for a chart (or overall if empty)."""
	var best = 0.0
	for session in sessions:
		if chart_title == "" or session.chart_title == chart_title:
			best = max(best, session.accuracy)
	return best

func get_average_score(chart_title: String = "") -> float:
	"""Get average score for a chart (or overall if empty)."""
	var total = 0
	var count = 0
	for session in sessions:
		if chart_title == "" or session.chart_title == chart_title:
			total += session.score
			count += 1
	return float(total) / float(count) if count > 0 else 0.0

func get_total_plays(chart_title: String = "") -> int:
	"""Get total play count for a chart (or overall if empty)."""
	var count = 0
	for session in sessions:
		if chart_title == "" or session.chart_title == chart_title:
			count += 1
	return count

func print_statistics() -> void:
	"""Print statistics summary."""
	print("\n=== Statistics Summary ===")
	print("Total Sessions: %d" % sessions.size())
	
	if sessions.is_empty():
		return
	
	print("\nBest Scores:")
	for session in sessions.slice(-5, sessions.size()):
		print("  %s" % session.to_string())
	
	print("\nOverall Stats:")
	print("Best Score: %d" % get_best_score())
	print("Best Accuracy: %.1f%%" % get_best_accuracy())
	print("Average Score: %.0f" % get_average_score())
