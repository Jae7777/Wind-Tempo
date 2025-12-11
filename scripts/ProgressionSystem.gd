extends Node

"""
ProgressionSystem tracks player progression through game content.
Manages milestones, unlocks, and progression-based rewards.
"""

const PROGRESSION_PATH = "user://progression.json"

class ProgressionLevel:
	var level: int
	var experience: int
	var experience_threshold: int
	var unlocked_content: Array
	var rewards: Dictionary
	
	func _init(p_level: int, p_exp: int = 0, p_threshold: int = 100) -> void:
		level = p_level
		experience = p_exp
		experience_threshold = p_threshold
		unlocked_content = []
		rewards = {}

var player_level: int = 1
var total_experience: int = 0
var progression_levels: Dictionary = {}
var milestones: Dictionary = {}

signal level_up(new_level: int)
signal experience_gained(amount: int, total: int)
signal content_unlocked(content_id: String)
signal milestone_reached(milestone_id: String)

func _ready() -> void:
	"""Initialize progression system."""
	_setup_progression_levels()
	_setup_milestones()
	_load_progression()

func _setup_progression_levels() -> void:
	"""Define progression levels."""
	var base_threshold = 100
	for i in range(1, 51):  # 50 levels
		var exp_threshold = base_threshold * (i + 1)
		var level_obj = ProgressionLevel.new(i, 0, exp_threshold)
		
		# Every 5 levels, unlock special content
		if i % 5 == 0:
			level_obj.unlocked_content.append("mode_hard")
		if i % 10 == 0:
			level_obj.unlocked_content.append("mode_extreme")
		
		# Rewards at certain levels
		level_obj.rewards = {
			"bonus_points": int(100 * (1 + i * 0.1)),
			"unlock_slots": i / 10
		}
		
		progression_levels[i] = level_obj

func _setup_milestones() -> void:
	"""Define progression milestones."""
	milestones = {
		"first_perfect": {
			"name": "First Perfect",
			"description": "Hit your first Perfect judgment",
			"reward": 100,
			"condition": "judgment",
			"target": "perfect"
		},
		"reach_level_10": {
			"name": "Novice",
			"description": "Reach Level 10",
			"reward": 500,
			"condition": "level",
			"target": 10
		},
		"reach_level_25": {
			"name": "Intermediate",
			"description": "Reach Level 25",
			"reward": 2000,
			"condition": "level",
			"target": 25
		},
		"reach_level_50": {
			"name": "Master",
			"description": "Reach Level 50",
			"reward": 10000,
			"condition": "level",
			"target": 50
		},
		"clear_all_songs": {
			"name": "Completionist",
			"description": "Clear all available songs",
			"reward": 5000,
			"condition": "songs_cleared",
			"target": 100
		}
	}

func add_experience(amount: int) -> void:
	"""Add experience and check for level up."""
	total_experience += amount
	emit_signal("experience_gained", amount, total_experience)
	
	# Check for level up
	while total_experience >= _get_experience_for_next_level():
		_level_up()

func _level_up() -> void:
	"""Handle level up."""
	player_level += 1
	
	if player_level in progression_levels:
		var level_obj = progression_levels[player_level]
		
		# Unlock content
		for content_id in level_obj.unlocked_content:
			_unlock_content(content_id)
		
		# Check milestones
		_check_milestone("reach_level_%d" % player_level)
	
	emit_signal("level_up", player_level)

func _get_experience_for_next_level() -> int:
	"""Get experience required for next level."""
	if player_level in progression_levels:
		return progression_levels[player_level].experience_threshold
	return 1000  # Default

func get_player_level() -> int:
	"""Get current player level."""
	return player_level

func get_total_experience() -> int:
	"""Get total experience."""
	return total_experience

func get_experience_to_next_level() -> int:
	"""Get experience needed to reach next level."""
	var current_exp = total_experience
	var next_level_exp = _get_experience_for_next_level()
	
	if current_exp >= next_level_exp:
		return 0
	
	return next_level_exp - current_exp

func get_level_progress() -> float:
	"""Get progress to next level (0.0 to 1.0)."""
	var exp_to_next = get_experience_to_next_level()
	var total_needed = _get_experience_for_next_level()
	
	if total_needed == 0:
		return 1.0
	
	return float(total_needed - exp_to_next) / total_needed

func is_content_unlocked(content_id: String) -> bool:
	"""Check if content is unlocked."""
	if player_level in progression_levels:
		return content_id in progression_levels[player_level].unlocked_content
	return false

func _unlock_content(content_id: String) -> void:
	"""Unlock content."""
	emit_signal("content_unlocked", content_id)

func _check_milestone(milestone_id: String) -> void:
	"""Check if a milestone is met."""
	if milestone_id in milestones:
		emit_signal("milestone_reached", milestone_id)

func get_milestone_progress(milestone_id: String) -> float:
	"""Get progress toward a milestone (0.0 to 1.0)."""
	if milestone_id not in milestones:
		return 0.0
	
	var milestone = milestones[milestone_id]
	var target = milestone.get("target", 1)
	var current = 0
	
	match milestone.get("condition"):
		"level":
			current = player_level
		"judgment":
			current = 0  # Would need external tracking
		"songs_cleared":
			current = 0  # Would need external tracking
	
	return min(float(current) / float(target), 1.0)

func get_all_milestones() -> Dictionary:
	"""Get all milestones."""
	return milestones.duplicate()

func get_level_info(level: int) -> Dictionary:
	"""Get information about a specific level."""
	if level not in progression_levels:
		return {}
	
	var level_obj = progression_levels[level]
	return {
		"level": level,
		"threshold": level_obj.experience_threshold,
		"rewards": level_obj.rewards,
		"unlocks": level_obj.unlocked_content
	}

func _save_progression() -> void:
	"""Save progression to file."""
	var data = {
		"level": player_level,
		"experience": total_experience
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(PROGRESSION_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func _load_progression() -> void:
	"""Load progression from file."""
	if not ResourceLoader.exists(PROGRESSION_PATH):
		return
	
	var file = FileAccess.open(PROGRESSION_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		
		if json.parse(json_string) == OK:
			var data = json.data
			if data:
				player_level = data.get("level", 1)
				total_experience = data.get("experience", 0)

func get_progression_summary() -> Dictionary:
	"""Get summary of player progression."""
	return {
		"level": player_level,
		"experience": total_experience,
		"next_level_progress": get_level_progress(),
		"experience_to_next": get_experience_to_next_level(),
		"unlocked_count": _count_unlocked_content()
	}

func _count_unlocked_content() -> int:
	"""Count total unlocked content."""
	var count = 0
	for i in range(1, player_level + 1):
		if i in progression_levels:
			count += progression_levels[i].unlocked_content.size()
	return count
