# UIManager.gd
extends Node

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var combo_label = $CanvasLayer/ComboLabel

func _process(delta):
	# This is simple, but reliable way to constantly update the UI
	if has_node("/root/Point"):
		score_label.text = "SCORE: %d" % Point.current_score
		
		var combo = Point.current_combo_streak
		if combo > 1:
			combo_label.text = "COMBO x%d" % combo
			combo_label.show()
		else:
			combo_label.hide()
