extends Node

"""
ScoringCalculator provides advanced scoring logic with difficulty scaling,
combo multipliers, and accuracy bonuses.
"""

class ScoreRank:
	var rank: String
	var min_accuracy: float
	var min_score: int
	var color: Color
	
	func _init(r: String, acc: float, score: int, col: Color) -> void:
		rank = r
		min_accuracy = acc
		min_score = score
		color = col

var score_ranks = [
	ScoreRank.new("SSS", 99.0, 10000, Color.GOLD),
	ScoreRank.new("SS", 95.0, 9000, Color.YELLOW),
	ScoreRank.new("S", 90.0, 8000, Color.ORANGE),
	ScoreRank.new("A", 80.0, 6000, Color.GREEN),
	ScoreRank.new("B", 70.0, 4000, Color.CYAN),
	ScoreRank.new("C", 60.0, 2000, Color.LIGHT_BLUE),
	ScoreRank.new("D", 50.0, 1000, Color.WHITE),
	ScoreRank.new("F", 0.0, 0, Color.RED)
]

var base_judgment_scores = {
	"Perfect": 100,
	"Great": 70,
	"Good": 40,
	"Miss": 0
}

var combo_multiplier_threshold: int = 10
var combo_multiplier_bonus: float = 1.1

func calculate_score(judgment: String, combo: int, difficulty: String = "Normal") -> int:
	"""Calculate score for a hit with difficulty scaling."""
	if judgment not in base_judgment_scores:
		return 0
	
	var base_score = base_judgment_scores[judgment]
	var difficulty_multiplier = _get_difficulty_multiplier(difficulty)
	var combo_bonus = _calculate_combo_bonus(combo)
	
	var final_score = int(float(base_score) * difficulty_multiplier * combo_bonus)
	return final_score

func _get_difficulty_multiplier(difficulty: String) -> float:
	"""Get score multiplier based on difficulty."""
	match difficulty.to_lower():
		"easy":
			return 0.8
		"normal":
			return 1.0
		"hard":
			return 1.5
		"extreme":
			return 2.0
		_:
			return 1.0

func _calculate_combo_bonus(combo: int) -> float:
	"""Calculate combo bonus multiplier."""
	if combo < combo_multiplier_threshold:
		return 1.0
	
	var bonus_combos = combo - combo_multiplier_threshold
	return 1.0 + (float(bonus_combos) / 10.0 * (combo_multiplier_bonus - 1.0))

func get_rank(accuracy: float, score: int) -> ScoreRank:
	"""Determine rank based on accuracy and score."""
	for rank in score_ranks:
		if accuracy >= rank.min_accuracy and score >= rank.min_score:
			return rank
	return score_ranks[-1]  # Return F grade

func get_rank_string(accuracy: float, score: int) -> String:
	"""Get rank letter as string."""
	return get_rank(accuracy, score).rank

func get_rank_color(accuracy: float, score: int) -> Color:
	"""Get rank color."""
	return get_rank(accuracy, score).color

func calculate_accuracy_bonus(accuracy: float) -> int:
	"""Calculate bonus points for high accuracy."""
	if accuracy >= 99.0:
		return 1000
	elif accuracy >= 95.0:
		return 500
	elif accuracy >= 90.0:
		return 250
	elif accuracy >= 80.0:
		return 100
	return 0

func calculate_combo_bonus_points(max_combo: int) -> int:
	"""Calculate bonus points for maintaining combo."""
	return (max_combo / 10) * 100

func calculate_total_bonus(accuracy: float, max_combo: int) -> int:
	"""Calculate total bonus points."""
	return calculate_accuracy_bonus(accuracy) + calculate_combo_bonus_points(max_combo)
