extends Node

var current_score: int = 0
var difficulty_multiplier: float = 1.0 # Set by difficulty selection (1.0, 1.5, or 2.0)

# --- Combo System Variables ---
var current_combo_streak: int = 0
const BASE_COMBO_FACTOR: float = 0.1 # Multiplier applied to the combo streak (e.g., 20 streak * 0.1 = 2.0 bonus)

# --- Base Scoring Constant ---
const BASE_SCORE_PER_HIT: int = 100 

func set_difficulty_multiplier(difficulty_index: int):
	match difficulty_index:
		0: # Easy
			difficulty_multiplier = 1.0
		1: # Normal
			difficulty_multiplier = 1.5
		2: # Hard
			difficulty_multiplier = 2.0
		_:
			difficulty_multiplier = 1.0
	
	print("Difficulty Multiplier set to: ", difficulty_multiplier)

func register_successful_hit():
	
	# 1. Increase the combo streak
	current_combo_streak += 1
	
	# 2. Calculate the Combo Bonus Multiplier
	# Example: (1 + (20 streak * 0.1 factor)) = 3.0x bonus
	var combo_bonus = 1.0 + (float(current_combo_streak) * BASE_COMBO_FACTOR)
	
	# 3. Calculate the Total Multiplier
	var total_multiplier = difficulty_multiplier * combo_bonus
	
	# 4. Calculate the final score
	var final_score = BASE_SCORE_PER_HIT * total_multiplier
	
	# 5. Add the calculated score to the total score (score is kept even if combo resets later)
	current_score += int(round(final_score))
	
	print("Hit! Score: %d | Combo Streak: %d | Total Multiplier: %.2fx" % 
		[int(round(final_score)), current_combo_streak, total_multiplier])

func register_miss():
	
	if current_combo_streak > 0:
		print("COMBO BROKEN! Streak ended at: %d" % current_combo_streak)
		
	# Reset the combo streak
	current_combo_streak = 0

func reset_score():
	current_score = 0
	register_miss()
