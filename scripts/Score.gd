extends Node

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var accuracy: float = 0.0

signal score_updated(new_score: int)
signal combo_updated(new_combo: int)

func add_judgement(judgement: String) -> void:
	match judgement:
		"Perfect":
			score += 100
			combo += 1
		"Great":
			score += 70
			combo += 1
		"Good":
			score += 40
			combo += 1
		"Miss":
			max_combo = max(max_combo, combo)
			combo = 0
	
	emit_signal("score_updated", score)
	emit_signal("combo_updated", combo)

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	accuracy = 0.0
	emit_signal("score_updated", score)
	emit_signal("combo_updated", combo)

func _ready() -> void:
	pass
