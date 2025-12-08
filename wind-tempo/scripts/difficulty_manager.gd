# scripts/difficulty_manager.gd
# Manages difficulty settings and modifiers
extends Node

enum Difficulty { EASY, NORMAL, HARD, EXPERT }

const DIFFICULTY_NAMES: Dictionary = {
	Difficulty.EASY: "Easy",
	Difficulty.NORMAL: "Normal", 
	Difficulty.HARD: "Hard",
	Difficulty.EXPERT: "Expert"
}

const DIFFICULTY_ICONS: Dictionary = {
	Difficulty.EASY: "⭐",
	Difficulty.NORMAL: "⭐⭐",
	Difficulty.HARD: "⭐⭐⭐",
	Difficulty.EXPERT: "⭐⭐⭐⭐"
}

# Timing window modifiers (smaller = harder)
const TIMING_MODIFIERS: Dictionary = {
	Difficulty.EASY: 1.5,      # 50% more forgiving
	Difficulty.NORMAL: 1.0,    # baseline
	Difficulty.HARD: 0.8,      # 20% stricter
	Difficulty.EXPERT: 0.6     # 40% stricter
}

# Score multipliers
const SCORE_MULTIPLIERS: Dictionary = {
	Difficulty.EASY: 0.5,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.5,
	Difficulty.EXPERT: 2.0
}

var current_difficulty: Difficulty = Difficulty.NORMAL

func get_timing_modifier(difficulty: Difficulty = current_difficulty) -> float:
	return TIMING_MODIFIERS.get(difficulty, 1.0)

func get_score_multiplier(difficulty: Difficulty = current_difficulty) -> float:
	return SCORE_MULTIPLIERS.get(difficulty, 1.0)

func get_difficulty_name(difficulty: Difficulty = current_difficulty) -> String:
	return DIFFICULTY_NAMES.get(difficulty, "Normal")

func get_difficulty_icons(difficulty: Difficulty = current_difficulty) -> String:
	return DIFFICULTY_ICONS.get(difficulty, "⭐")

func set_difficulty(difficulty: Difficulty) -> void:
	current_difficulty = difficulty
