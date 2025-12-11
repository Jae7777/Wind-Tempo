extends Control

"""
ResultsScreen displays end-game statistics and performance feedback.
Shows score, accuracy, rank, and comparison to personal bests.
"""

@onready var title_label = $VBoxContainer/TitleLabel
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var accuracy_label = $VBoxContainer/AccuracyLabel
@onready var rank_label = $VBoxContainer/RankLabel
@onready var combo_label = $VBoxContainer/ComboLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var new_record_label = $VBoxContainer/NewRecordLabel
@onready var retry_button = $VBoxContainer/RetryButton
@onready var menu_button = $VBoxContainer/MenuButton

var statistics_tracker: Node
var scoring_calculator: Node
var game_controller: Node

func _ready() -> void:
	statistics_tracker = get_tree().root.get_node_or_null("Main/StatisticsTracker")
	scoring_calculator = get_tree().root.get_node_or_null("Main/ScoringCalculator")
	game_controller = get_tree().root.get_node_or_null("Main/GameController")
	
	_connect_signals()
	hide()

func _connect_signals() -> void:
	"""Connect UI signals."""
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_results(stats: Dictionary, chart_title: String) -> void:
	"""Display game results."""
	if not stats:
		return
	
	var score = stats.get("score", 0)
	var accuracy = stats.get("accuracy", 0.0)
	var combo = stats.get("max_combo", 0)
	var hit_notes = stats.get("hit_notes", 0)
	var total_notes = stats.get("total_notes", 0)
	
	# Get rank and color
	var rank = "F"
	var rank_color = Color.RED
	if scoring_calculator:
		rank = scoring_calculator.get_rank_string(accuracy, score)
		rank_color = scoring_calculator.get_rank_color(accuracy, score)
	
	# Update labels
	title_label.text = "Results: %s" % chart_title
	score_label.text = "Score: %d" % score
	accuracy_label.text = "Accuracy: %.1f%%" % accuracy
	rank_label.text = rank
	rank_label.add_theme_color_override("font_color", rank_color)
	combo_label.text = "Max Combo: %d" % combo
	stats_label.text = "Notes Hit: %d / %d" % [hit_notes, total_notes]
	
	# Check for new record
	if statistics_tracker:
		var prev_best = statistics_tracker.get_best_score(chart_title)
		if score > prev_best:
			new_record_label.text = "NEW PERSONAL RECORD!"
			new_record_label.add_theme_color_override("font_color", Color.GOLD)
			new_record_label.show()
		else:
			new_record_label.hide()
		
		# Record the session
		statistics_tracker.record_session(
			chart_title, score, accuracy, combo, rank,
			total_notes, hit_notes, total_notes - hit_notes, 0.0
		)
	
	show()

func _on_retry_pressed() -> void:
	"""Restart the same song."""
	if game_controller:
		game_controller.return_to_menu()
		hide()

func _on_menu_pressed() -> void:
	"""Return to main menu."""
	if game_controller:
		game_controller.return_to_menu()
		hide()
