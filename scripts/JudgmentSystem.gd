extends Node

# Timing windows (in milliseconds from perfect hit)
var timing_windows = {
	"Perfect": 50,
	"Great": 100,
	"Good": 150,
	"Miss": 300
}

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var total_notes: int = 0
var hit_notes: int = 0
var missed_notes: int = 0

signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal judgment_received(judgment: String, score_value: int)
signal accuracy_changed(accuracy: float)

func _ready() -> void:
	pass

func judge_hit(time_offset: float) -> String:
	"""
	Determine judgment based on timing offset in milliseconds.
	Returns the judgment string and updates score/combo.
	"""
	var abs_offset = abs(time_offset)
	var judgment = "Miss"
	var score_value = 0
	
	if abs_offset <= timing_windows["Perfect"]:
		judgment = "Perfect"
		score_value = 100
	elif abs_offset <= timing_windows["Great"]:
		judgment = "Great"
		score_value = 70
	elif abs_offset <= timing_windows["Good"]:
		judgment = "Good"
		score_value = 40
	else:
		judgment = "Miss"
		score_value = 0
	
	_apply_judgment(judgment, score_value)
	return judgment

func _apply_judgment(judgment: String, score_value: int) -> void:
	"""Apply judgment and update game state."""
	score += score_value
	total_notes += 1
	
	if judgment != "Miss":
		combo += 1
		hit_notes += 1
	else:
		max_combo = max(max_combo, combo)
		combo = 0
		missed_notes += 1
	
	max_combo = max(max_combo, combo)
	emit_signal("score_changed", score)
	emit_signal("combo_changed", combo)
	emit_signal("judgment_received", judgment, score_value)
	_update_accuracy()

func _update_accuracy() -> void:
	"""Calculate and emit accuracy percentage."""
	if total_notes > 0:
		var accuracy = float(hit_notes) / float(total_notes) * 100.0
		emit_signal("accuracy_changed", accuracy)

func get_accuracy() -> float:
	"""Return current accuracy percentage."""
	if total_notes == 0:
		return 0.0
	return float(hit_notes) / float(total_notes) * 100.0

func reset() -> void:
	"""Reset all scoring data."""
	score = 0
	combo = 0
	max_combo = 0
	total_notes = 0
	hit_notes = 0
	missed_notes = 0
	emit_signal("score_changed", score)
	emit_signal("combo_changed", combo)
	emit_signal("accuracy_changed", 0.0)

func get_stats() -> Dictionary:
	"""Return game stats as dictionary."""
	return {
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"accuracy": get_accuracy(),
		"total_notes": total_notes,
		"hit_notes": hit_notes,
		"missed_notes": missed_notes
	}
