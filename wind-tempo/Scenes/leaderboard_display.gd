# Scenes/LeaderboardDisplay.gd
# Display top 10 scores for a song
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var score_list: ItemList = $VBoxContainer/ScoreList
@onready var back_button: Button = $VBoxContainer/BackButton

var current_song_name: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	score_list.item_selected.connect(_on_score_selected)

func display_leaderboard(song_name: String) -> void:
	"""Display the leaderboard for a song"""
	current_song_name = song_name
	title_label.text = song_name + " Leaderboard"
	
	var lb_manager = get_node_or_null("/root/LeaderboardManager")
	if not lb_manager:
		return
	
	var leaderboard = lb_manager.get_leaderboard(song_name)
	score_list.clear()
	
	if leaderboard.scores.is_empty():
		score_list.add_item("No scores yet!")
		return
	
	for i in range(leaderboard.scores.size()):
		var score = leaderboard.scores[i]
		var text = "#%d - %s | Score: %d | Accuracy: %.1f%%" % [
			i + 1, score.player_name, score.score, score.accuracy
		]
		score_list.add_item(text)

func _on_score_selected(_index: int) -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")
