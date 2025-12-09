extends Node

# Signals to notify the UI when values change
signal score_updated(new_score)
signal combo_updated(new_combo)
signal accuracy_updated(new_accuracy)

var score: int = 0
var combo: int = 0
var total_notes: int = 0
var successful_hits: int = 0

const HIT_SCORE = 100

func _ready():
		# Reset everything when the game starts
		reset()

func add_hit():
    """Called when the player successfully hits a note."""
		combo += 1
		score += HIT_SCORE * combo
		total_notes += 1
		successful_hits += 1
		
		emit_signal("score_updated", score)
		emit_signal("combo_updated", combo)
		update_accuracy()

func add_miss():
    """Called when the player misses a note."""
		combo = 0
		total_notes += 1
		
		emit_signal("combo_updated", combo)
		update_accuracy()
