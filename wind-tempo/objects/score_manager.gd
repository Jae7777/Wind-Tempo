# objects/score_manager.gd
# A global script to manage score, combo, and other gameplay stats.
extends Node

# Signals to notify the UI when values change
signal score_updated(new_score)
signal combo_updated(new_combo)

var score: int = 0
var combo: int = 0

const PERFECT_HIT_SCORE = 10
const GOOD_HIT_SCORE = 5

# Call this when a note is hit successfully
func add_hit(hit_type: String):
		combo += 1
		
		if hit_type == "perfect":
				score += PERFECT_HIT_SCORE * combo
		elif hit_type == "good":
				score += GOOD_HIT_SCORE * combo
		
		emit_signal("score_updated", score)
		emit_signal("combo_updated", combo)
		print("Hit! New score: ", score, " (Combo: ", combo, ")")

# Call this when a note is missed
func add_miss():
		if combo > 0:
				print("Combo broken!")
		combo = 0
		emit_signal("combo_updated", combo)

# Resets the score for a new game
func reset():
		score = 0
		combo = 0
		emit_signal("score_updated", score)
		emit_signal("combo_updated", combo)
