extends Node

var current_score: int = 0
var current_multiplier: float = 1.0 # The active difficulty multiplier (1.0, 1.5, or 2.0)

# --- Base Scoring Constant ---
const BASE_SCORE_PER_HIT: int = 100 # Points awarded for any successful key press

# --- Functions ---

# 1. Sets the global score multiplier based on difficulty index (0=Easy, 1=Normal, 2=Hard)
func set_difficulty_multiplier(difficulty_index: int):
	match difficulty_index:
		0: # Easy
			current_multiplier = 1.0
		1: # Normal
			current_multiplier = 1.5
		2: # Hard
			current_multiplier = 2.0
		_:
			current_multiplier = 1.0
	
	print("Difficulty Multiplier set to: ", current_multiplier)

# 2. Registers a successful key press and calculates the score
func register_successful_hit():
	
	# Calculate the final score by applying the difficulty multiplier
	var final_score = BASE_SCORE_PER_HIT * current_multiplier
	
	# Add the calculated score to the total score
	# Use int(round()) to ensure the score is a whole number
	current_score += int(round(final_score))
	
	print("Hit! Base: %d, Final: %d, Total Score: %d" % [BASE_SCORE_PER_HIT, int(round(final_score)), current_score])

# 3. Optional: Add a function to reset the score at the start of a track
func reset_score():
	current_score = 0
