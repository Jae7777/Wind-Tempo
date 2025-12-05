extends Control

@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var accuracy_label = $MarginContainer/VBoxContainer/AccuracyLabel
@ontml:parameter name="combo_label = $MarginContainer/VBoxContainer/ComboLabel
@onready var notes_hit_label = $MarginContainer/VBoxContainer/NotesHitLabel
@onready var rank_label = $MarginContainer/VBoxContainer/RankLabel
@onready var retry_button = $MarginContainer/VBoxContainer/ButtonContainer/RetryButton
@onready var menu_button = $MarginContainer/VBoxContainer/ButtonContainer/MenuButton

var final_score: int = 0
var notes_hit: int = 0
var total_notes: int = 0
var max_combo: int = 0

func _ready() -> void:
	retry_button.connect("pressed", Callable(self, "_on_retry_pressed"))
	menu_button.connect("pressed", Callable(self, "_on_menu_pressed"))
	_display_results()

func set_results(score: int, hits: int, total: int, combo: int) -> void:
	final_score = score
	notes_hit = hits
	total_notes = total
	max_combo = combo

func _display_results() -> void:
	score_label.text = "Score: %d" % final_score
	notes_hit_label.text = "Notes Hit: %d / %d" % [notes_hit, total_notes]
	combo_label.text = "Max Combo: %d" % max_combo
	
	var accuracy = 0.0
	if total_notes > 0:
		accuracy = (float(notes_hit) / float(total_notes)) * 100.0
	accuracy_label.text = "Accuracy: %.1f%%" % accuracy
	
	var rank = _calculate_rank(accuracy)
	rank_label.text = "Rank: %s" % rank

func _calculate_rank(accuracy: float) -> String:
	if accuracy >= 95.0:
		return "S"
	elif accuracy >= 90.0:
		return "A"
	elif accuracy >= 80.0:
		return "B"
	elif accuracy >= 70.0:
		return "C"
	elif accuracy >= 60.0:
		return "D"
	else:
		return "F"

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://CoreGameplay/Main.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
