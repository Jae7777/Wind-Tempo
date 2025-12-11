extends Control

"""
Leaderboard displays top scores and personal records.
Supports both local leaderboards and per-song leaderboards.
"""

@onready var leaderboard_list = $VBoxContainer/LeaderboardList
@onready var song_filter = $VBoxContainer/SongFilter
@onready var sort_button = $VBoxContainer/SortButton
@onready var refresh_button = $VBoxContainer/RefreshButton
@onready var back_button = $VBoxContainer/BackButton

var statistics_tracker: Node
var current_sort: String = "score"  # "score" or "accuracy"
var current_filter: String = "all"  # "all" or specific song title

signal leaderboard_updated

func _ready() -> void:
	statistics_tracker = get_tree().root.get_node_or_null("Main/StatisticsTracker")
	_connect_signals()
	hide()

func _connect_signals() -> void:
	"""Connect button signals."""
	sort_button.pressed.connect(_toggle_sort)
	refresh_button.pressed.connect(_refresh_leaderboard)
	back_button.pressed.connect(_on_back_pressed)

func show_leaderboard() -> void:
	"""Display leaderboard."""
	show()
	_refresh_leaderboard()

func _refresh_leaderboard() -> void:
	"""Refresh and display leaderboard entries."""
	if not statistics_tracker:
		return
	
	leaderboard_list.clear()
	
	var sessions = statistics_tracker.sessions
	var filtered_sessions = []
	
	# Filter by song if needed
	if current_filter != "all":
		for session in sessions:
			if session.chart_title == current_filter:
				filtered_sessions.append(session)
	else:
		filtered_sessions = sessions.duplicate()
	
	# Sort
	match current_sort:
		"score":
			filtered_sessions.sort_custom(func(a, b): return a.score > b.score)
		"accuracy":
			filtered_sessions.sort_custom(func(a, b): return a.accuracy > b.accuracy)
	
	# Display top 50
	for i in range(mini(filtered_sessions.size(), 50)):
		var session = filtered_sessions[i]
		var entry_text = "#%d | %s | Score: %d | Accuracy: %.1f%% | Rank: %s" % [
			i + 1,
			session.chart_title,
			session.score,
			session.accuracy,
			session.rank
		]
		leaderboard_list.add_item(entry_text)
	
	sort_button.text = "Sort: %s" % current_sort.to_upper()
	emit_signal("leaderboard_updated")

func _toggle_sort() -> void:
	"""Toggle sorting method."""
	current_sort = "accuracy" if current_sort == "score" else "score"
	_refresh_leaderboard()

func _set_filter(song_title: String) -> void:
	"""Set leaderboard filter by song."""
	current_filter = song_title
	_refresh_leaderboard()

func _on_back_pressed() -> void:
	"""Return to menu."""
	hide()

func get_personal_best(song_title: String = "") -> Dictionary:
	"""Get personal best score."""
	if not statistics_tracker:
		return {}
	
	var best_score = statistics_tracker.get_best_score(song_title)
	var best_accuracy = statistics_tracker.get_best_accuracy(song_title)
	
	return {
		"score": best_score,
		"accuracy": best_accuracy,
		"play_count": statistics_tracker.get_total_plays(song_title)
	}
