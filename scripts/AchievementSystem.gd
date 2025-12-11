extends Node

"""
AchievementSystem tracks player accomplishments and unlocks achievements/badges.
Provides unlocks, notifications, and persistence via JSON.
"""

const ACHIEVEMENTS_PATH = "user://achievements.json"

@onready var event_bus = get_node("/root/Main/EventBus")

var achievements: Dictionary = {}
var unlocked_achievements: Array = []

signal achievement_unlocked(achievement_id: String, achievement_name: String)
signal achievement_progress_updated(achievement_id: String, progress: float)

func _ready() -> void:
	"""Initialize achievement system."""
	_setup_achievements()
	_load_unlocked()
	if event_bus:
		_connect_events()

func _setup_achievements() -> void:
	"""Define all available achievements."""
	achievements = {
		"first_perfect": {
			"name": "First Perfect",
			"description": "Hit your first Perfect judgment",
			"icon": "⭐",
			"points": 10,
			"rarity": "common"
		},
		"combo_10": {
			"name": "Building Momentum",
			"description": "Reach a combo of 10",
			"icon": "🔥",
			"points": 25,
			"rarity": "common"
		},
		"combo_50": {
			"name": "On Fire",
			"description": "Reach a combo of 50",
			"icon": "🌪️",
			"points": 50,
			"rarity": "uncommon"
		},
		"combo_100": {
			"name": "Unstoppable",
			"description": "Reach a combo of 100",
			"icon": "💫",
			"points": 100,
			"rarity": "rare"
		},
		"perfect_fc": {
			"name": "Flawless",
			"description": "Full Combo on a Hard difficulty song",
			"icon": "💎",
			"points": 150,
			"rarity": "epic"
		},
		"rank_sss": {
			"name": "Godlike",
			"description": "Achieve SSS rank (99%+ accuracy)",
			"icon": "👑",
			"points": 200,
			"rarity": "legendary"
		},
		"rank_ss": {
			"name": "Master",
			"description": "Achieve SS rank (95%+ accuracy)",
			"icon": "🏅",
			"points": 100,
			"rarity": "rare"
		},
		"accuracy_95": {
			"name": "Precision",
			"description": "Achieve 95%+ accuracy on any song",
			"icon": "🎯",
			"points": 75,
			"rarity": "uncommon"
		},
		"accuracy_90": {
			"name": "Steady Hands",
			"description": "Achieve 90%+ accuracy on any song",
			"icon": "✨",
			"points": 50,
			"rarity": "common"
		},
		"extreme_clear": {
			"name": "Extreme Master",
			"description": "Clear an Extreme difficulty song",
			"icon": "⚡",
			"points": 175,
			"rarity": "epic"
		},
		"all_songs_clear": {
			"name": "Completionist",
			"description": "Clear all songs at least once",
			"icon": "🏆",
			"points": 250,
			"rarity": "legendary"
		},
		"score_100k": {
			"name": "Six Digits",
			"description": "Achieve a score of 100,000+",
			"icon": "💰",
			"points": 100,
			"rarity": "rare"
		},
		"score_500k": {
			"name": "High Roller",
			"description": "Achieve a score of 500,000+",
			"icon": "🎰",
			"points": 200,
			"rarity": "legendary"
		},
		"played_50": {
			"name": "Dedicated",
			"description": "Play 50 songs",
			"icon": "🎮",
			"points": 100,
			"rarity": "uncommon"
		},
		"played_100": {
			"name": "Obsessed",
			"description": "Play 100 songs",
			"icon": "🌟",
			"points": 150,
			"rarity": "rare"
		}
	}

func _connect_events() -> void:
	"""Connect to game events for achievement tracking."""
	if event_bus:
		event_bus.connect("note_hit", Callable(self, "_on_note_hit"))
		event_bus.connect("combo_changed", Callable(self, "_on_combo_changed"))
		event_bus.connect("song_completed", Callable(self, "_on_song_completed"))

func _on_note_hit(judgment: String) -> void:
	"""Track note hits for achievements."""
	if judgment == "Perfect":
		unlock_achievement("first_perfect")

func _on_combo_changed(combo: int) -> void:
	"""Track combo milestones."""
	if combo == 10:
		unlock_achievement("combo_10")
	elif combo == 50:
		unlock_achievement("combo_50")
	elif combo == 100:
		unlock_achievement("combo_100")

func _on_song_completed(result: Dictionary) -> void:
	"""Track song completion and check for achievement unlocks."""
	var accuracy = result.get("accuracy", 0.0)
	var combo = result.get("max_combo", 0)
	var score = result.get("score", 0)
	var rank = result.get("rank", "F")
	var difficulty = result.get("difficulty", "Normal")
	var is_fc = result.get("is_fc", false)
	
	# Check accuracy achievements
	if accuracy >= 0.99:
		unlock_achievement("rank_sss")
	elif accuracy >= 0.95:
		unlock_achievement("accuracy_95")
		unlock_achievement("rank_ss")
	elif accuracy >= 0.90:
		unlock_achievement("accuracy_90")
	
	# Check combo/FC achievements
	if is_fc and difficulty == "Hard":
		unlock_achievement("perfect_fc")
	
	# Check difficulty achievements
	if difficulty == "Extreme":
		unlock_achievement("extreme_clear")
	
	# Check score achievements
	if score >= 500000:
		unlock_achievement("score_500k")
	elif score >= 100000:
		unlock_achievement("score_100k")

func unlock_achievement(achievement_id: String) -> void:
	"""Unlock an achievement if not already unlocked."""
	if achievement_id not in achievements:
		push_error("Unknown achievement: %s" % achievement_id)
		return
	
	if achievement_id in unlocked_achievements:
		return  # Already unlocked
	
	unlocked_achievements.append(achievement_id)
	var achievement = achievements[achievement_id]
	
	print("Achievement Unlocked: %s - %s" % [achievement["name"], achievement["description"]])
	emit_signal("achievement_unlocked", achievement_id, achievement["name"])
	_save_unlocked()

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked."""
	return achievement_id in unlocked_achievements

func get_achievement(achievement_id: String) -> Dictionary:
	"""Get achievement data."""
	if achievement_id in achievements:
		var achievement = achievements[achievement_id].duplicate()
		achievement["unlocked"] = is_achievement_unlocked(achievement_id)
		return achievement
	return {}

func get_all_achievements() -> Array:
	"""Get all achievements with unlock status."""
	var all_achievements = []
	for achievement_id in achievements.keys():
		var achievement = achievements[achievement_id].duplicate()
		achievement["id"] = achievement_id
		achievement["unlocked"] = is_achievement_unlocked(achievement_id)
		all_achievements.append(achievement)
	return all_achievements

func get_achievement_progress() -> Dictionary:
	"""Get overall achievement progress."""
	return {
		"unlocked": unlocked_achievements.size(),
		"total": achievements.size(),
		"percentage": float(unlocked_achievements.size()) / float(achievements.size()) * 100.0,
		"total_points": _calculate_total_points()
	}

func _calculate_total_points() -> int:
	"""Calculate total points from unlocked achievements."""
	var total = 0
	for achievement_id in unlocked_achievements:
		if achievement_id in achievements:
			total += achievements[achievement_id].get("points", 0)
	return total

func _save_unlocked() -> void:
	"""Save unlocked achievements to JSON."""
	var data = {
		"unlocked": unlocked_achievements,
		"timestamp": Time.get_ticks_msec()
	}
	
	var json = JSON.stringify(data)
	var file = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)

func _load_unlocked() -> void:
	"""Load unlocked achievements from JSON."""
	if not ResourceLoader.exists(ACHIEVEMENTS_PATH):
		return
	
	var file = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var data = json.data
			if data and "unlocked" in data:
				unlocked_achievements = data["unlocked"]

func reset_all() -> void:
	"""Reset all unlocked achievements."""
	unlocked_achievements.clear()
	_save_unlocked()
