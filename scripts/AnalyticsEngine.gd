extends Node

"""
AnalyticsEngine tracks gameplay statistics and provides insights.
Collects data for leaderboards, trends, and performance analysis.
"""

const ANALYTICS_PATH = "user://analytics.json"

class GameplayMetrics:
	var timestamp: int
	var song_title: String
	var difficulty: String
	var score: int
	var accuracy: float
	var max_combo: int
	var perfect_count: int
	var great_count: int
	var good_count: int
	var miss_count: int
	var play_duration: float
	var rank: String
	
	func _init() -> void:
		timestamp = Time.get_ticks_msec()

var metrics_history: Array = []
var session_start_time: int = 0

signal metrics_recorded(metrics: GameplayMetrics)
signal stats_updated
signal milestone_reached(milestone: String)

func _ready() -> void:
	"""Initialize analytics engine."""
	_load_metrics()
	session_start_time = Time.get_ticks_msec()

func record_gameplay(song_title: String, difficulty: String, score: int, accuracy: float, 
					 max_combo: int, perfect: int, great: int, good: int, misses: int, 
					 play_duration: float, rank: String) -> void:
	"""Record a complete gameplay session."""
	var metrics = GameplayMetrics.new()
	metrics.song_title = song_title
	metrics.difficulty = difficulty
	metrics.score = score
	metrics.accuracy = accuracy
	metrics.max_combo = max_combo
	metrics.perfect_count = perfect
	metrics.great_count = great
	metrics.good_count = good
	metrics.miss_count = misses
	metrics.play_duration = play_duration
	metrics.rank = rank
	
	metrics_history.append(metrics)
	_save_metrics()
	
	emit_signal("metrics_recorded", metrics)
	_check_milestones()
	emit_signal("stats_updated")

func get_total_plays() -> int:
	"""Get total number of plays."""
	return metrics_history.size()

func get_average_score() -> float:
	"""Get average score across all plays."""
	if metrics_history.is_empty():
		return 0.0
	
	var total = 0
	for metrics in metrics_history:
		total += metrics.score
	
	return float(total) / metrics_history.size()

func get_average_accuracy() -> float:
	"""Get average accuracy across all plays."""
	if metrics_history.is_empty():
		return 0.0
	
	var total = 0.0
	for metrics in metrics_history:
		total += metrics.accuracy
	
	return total / metrics_history.size()

func get_best_score() -> int:
	"""Get the highest score achieved."""
	if metrics_history.is_empty():
		return 0
	
	var best = 0
	for metrics in metrics_history:
		best = max(best, metrics.score)
	
	return best

func get_best_accuracy() -> float:
	"""Get the highest accuracy achieved."""
	if metrics_history.is_empty():
		return 0.0
	
	var best = 0.0
	for metrics in metrics_history:
		best = max(best, metrics.accuracy)
	
	return best

func get_most_played_song() -> String:
	"""Get the most frequently played song."""
	if metrics_history.is_empty():
		return "None"
	
	var song_count = {}
	for metrics in metrics_history:
		if metrics.song_title not in song_count:
			song_count[metrics.song_title] = 0
		song_count[metrics.song_title] += 1
	
	var most_played = ""
	var max_count = 0
	for song in song_count:
		if song_count[song] > max_count:
			max_count = song_count[song]
			most_played = song
	
	return most_played

func get_difficulty_stats(difficulty: String) -> Dictionary:
	"""Get statistics for a specific difficulty."""
	var plays = []
	
	for metrics in metrics_history:
		if metrics.difficulty == difficulty:
			plays.append(metrics)
	
	if plays.is_empty():
		return {}
	
	var total_score = 0
	var total_accuracy = 0.0
	var total_combo = 0
	var best_score = 0
	var best_accuracy = 0.0
	
	for metrics in plays:
		total_score += metrics.score
		total_accuracy += metrics.accuracy
		total_combo = max(total_combo, metrics.max_combo)
		best_score = max(best_score, metrics.score)
		best_accuracy = max(best_accuracy, metrics.accuracy)
	
	return {
		"play_count": plays.size(),
		"average_score": float(total_score) / plays.size(),
		"average_accuracy": total_accuracy / plays.size(),
		"best_score": best_score,
		"best_accuracy": best_accuracy,
		"best_combo": total_combo
	}

func get_rank_distribution() -> Dictionary:
	"""Get count of each rank achieved."""
	var ranks = {
		"SSS": 0,
		"SS": 0,
		"S": 0,
		"A": 0,
		"B": 0,
		"C": 0,
		"D": 0,
		"F": 0
	}
	
	for metrics in metrics_history:
		if metrics.rank in ranks:
			ranks[metrics.rank] += 1
	
	return ranks

func get_recent_plays(count: int = 10) -> Array:
	"""Get the most recent plays."""
	var recent = []
	var start = max(0, metrics_history.size() - count)
	
	for i in range(start, metrics_history.size()):
		recent.append(metrics_history[i])
	
	return recent

func get_improvement_over_time() -> Array:
	"""Get accuracy improvement trend."""
	var trend = []
	
	for i in range(0, min(20, metrics_history.size())):
		var index = (metrics_history.size() - 20) + i
		if index >= 0:
			trend.append({
				"position": i,
				"accuracy": metrics_history[index].accuracy,
				"song": metrics_history[index].song_title
			})
	
	return trend

func get_daily_stats() -> Dictionary:
	"""Get statistics for today."""
	var now = Time.get_datetime_dict_from_system()
	var today_start = Time.get_unix_time_from_datetime_dict({
		"year": now["year"],
		"month": now["month"],
		"day": now["day"],
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	
	var plays = 0
	var total_score = 0
	var total_accuracy = 0.0
	
	for metrics in metrics_history:
		var metrics_date = metrics.timestamp / 1000
		if metrics_date >= today_start:
			plays += 1
			total_score += metrics.score
			total_accuracy += metrics.accuracy
	
	if plays == 0:
		return {}
	
	return {
		"plays": plays,
		"average_score": float(total_score) / plays,
		"average_accuracy": total_accuracy / plays
	}

func _check_milestones() -> void:
	"""Check for achievement milestones."""
	var play_count = metrics_history.size()
	
	match play_count:
		1:
			emit_signal("milestone_reached", "First Play")
		10:
			emit_signal("milestone_reached", "10 Plays")
		50:
			emit_signal("milestone_reached", "50 Plays")
		100:
			emit_signal("milestone_reached", "100 Plays")
		500:
			emit_signal("milestone_reached", "500 Plays")
		1000:
			emit_signal("milestone_reached", "1000 Plays")

func _save_metrics() -> void:
	"""Save metrics to JSON file."""
	var data = {
		"metrics": []
	}
	
	for metrics in metrics_history:
		data["metrics"].append({
			"timestamp": metrics.timestamp,
			"song_title": metrics.song_title,
			"difficulty": metrics.difficulty,
			"score": metrics.score,
			"accuracy": metrics.accuracy,
			"max_combo": metrics.max_combo,
			"perfect": metrics.perfect_count,
			"great": metrics.great_count,
			"good": metrics.good_count,
			"misses": metrics.miss_count,
			"duration": metrics.play_duration,
			"rank": metrics.rank
		})
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(ANALYTICS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func _load_metrics() -> void:
	"""Load metrics from JSON file."""
	if not ResourceLoader.exists(ANALYTICS_PATH):
		return
	
	var file = FileAccess.open(ANALYTICS_PATH, FileAccess.READ)
	if not file:
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_string) == OK:
		var data = json.data
		if data and "metrics" in data:
			for metric_data in data["metrics"]:
				var metrics = GameplayMetrics.new()
				metrics.timestamp = metric_data.get("timestamp", 0)
				metrics.song_title = metric_data.get("song_title", "")
				metrics.difficulty = metric_data.get("difficulty", "")
				metrics.score = metric_data.get("score", 0)
				metrics.accuracy = metric_data.get("accuracy", 0.0)
				metrics.max_combo = metric_data.get("max_combo", 0)
				metrics.perfect_count = metric_data.get("perfect", 0)
				metrics.great_count = metric_data.get("great", 0)
				metrics.good_count = metric_data.get("good", 0)
				metrics.miss_count = metric_data.get("misses", 0)
				metrics.play_duration = metric_data.get("duration", 0.0)
				metrics.rank = metric_data.get("rank", "F")
				
				metrics_history.append(metrics)

func clear_all_data() -> void:
	"""Clear all analytics data."""
	metrics_history.clear()
	_save_metrics()
