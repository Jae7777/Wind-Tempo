# scripts/leaderboard_manager.gd
# Manages leaderboard data for songs and high scores
extends Node

class Score:
	var player_name: String = "Player"
	var score: int = 0
	var accuracy: float = 0.0
	var combo: int = 0
	var rank: String = "F"
	var timestamp: float = 0.0
	
	func to_dict() -> Dictionary:
		return {
			"player_name": player_name,
			"score": score,
			"accuracy": accuracy,
			"combo": combo,
			"rank": rank,
			"timestamp": timestamp
		}
	
	static func from_dict(data: Dictionary) -> Score:
		var s = Score.new()
		s.player_name = data.get("player_name", "Player")
		s.score = data.get("score", 0)
		s.accuracy = data.get("accuracy", 0.0)
		s.combo = data.get("combo", 0)
		s.rank = data.get("rank", "F")
		s.timestamp = data.get("timestamp", 0.0)
		return s

# Leaderboard for a single song
class Leaderboard:
	var song_name: String = ""
	var difficulty: int = 0  # 0=Easy, 1=Normal, 2=Hard, 3=Expert
	var scores: Array[Score] = []
	var max_scores: int = 10
	
	func add_score(score: Score) -> bool:
		"""Add a score and return true if it made the top 10"""
		if scores.size() < max_scores:
			scores.append(score)
			_sort_scores()
			return true
		elif score.score > scores[max_scores - 1].score:
			scores[max_scores - 1] = score
			_sort_scores()
			return true
		return false

	func _sort_scores() -> void:
		scores.sort_custom(func(a, b): return a.score > b.score)
	
	func to_dict() -> Dictionary:
		var score_dicts = []
		for s in scores:
			score_dicts.append(s.to_dict())
		return {
			"song_name": song_name,
			"difficulty": difficulty,
			"scores": score_dicts
		}
	
	static func from_dict(data: Dictionary) -> Leaderboard:
		var lb = Leaderboard.new()
		lb.song_name = data.get("song_name", "Unknown")
		lb.difficulty = data.get("difficulty", 0)
		for score_data in data.get("scores", []):
			lb.scores.append(Score.from_dict(score_data))
		return lb

# Leaderboards
var leaderboards: Dictionary = {}
const LEADERBOARD_PATH: String = "user://leaderboards/"

func _ready() -> void:
	load_all_leaderboards()

func load_all_leaderboards() -> void:
	"""Load all leaderboard files from disk"""
	var dir = DirAccess.open(LEADERBOARD_PATH)
	if dir == null:
		dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("leaderboards")
	else:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var song_name = file_name.get_basename()
				load_leaderboard(song_name)
			file_name = dir.get_next()

func load_leaderboard(song_name: String, difficulty: int = 1) -> Leaderboard:
	"""Load a leaderboard for a specific song and difficulty"""
	var key = song_name + "_" + str(difficulty)
	if leaderboards.has(key):
		return leaderboards[key]
	
	var path = LEADERBOARD_PATH + key + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		var lb = Leaderboard.new()
		lb.song_name = song_name
		lb.difficulty = difficulty
		leaderboards[key] = lb
		return lb
	
	var json = JSON.new()
	var data = json.parse(file.get_as_text())
	file.close()
	
	if data is Dictionary:
		var lb = Leaderboard.from_dict(data)
		leaderboards[key] = lb
		return lb
	var lb = Leaderboard.new()
	lb.song_name = song_name
	lb.difficulty = difficulty
	leaderboards[key] = lb
	return lb

func save_leaderboard(song_name: String, difficulty: int = 1) -> bool:
	"""Save a leaderboard to disk"""
	var key = song_name + "_" + str(difficulty)
	if not leaderboards.has(key):
		return false
	
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("leaderboards"):
		dir.make_dir("leaderboards")
	
	var path = LEADERBOARD_PATH + key + ".json"
	var lb = leaderboards[key]
	var json_str = JSON.stringify(lb.to_dict())
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func add_score(song_name: String, score: Score, difficulty: int = 1) -> bool:
	"""Add a score to a song's leaderboard for a difficulty"""
	var lb = load_leaderboard(song_name, difficulty)
	var made_top_10 = lb.add_score(score)
	if made_top_10:
		save_leaderboard(song_name, difficulty)
	return made_top_10

func get_leaderboard(song_name: String, difficulty: int = 1) -> Leaderboard:
	"""Get a leaderboard for a song and difficulty"""
	return load_leaderboard(song_name, difficulty)

func get_player_rank(song_name: String, difficulty: int = 1) -> int:
	"""Get player's rank on a leaderboard (-1 if not ranked)"""
	var lb = load_leaderboard(song_name, difficulty)
	for i in range(lb.scores.size()):
		if lb.scores[i].player_name == "Player":
			return i + 1
	return -1
