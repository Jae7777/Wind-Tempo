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
			"scores": score_dicts
		}
	
	static func from_dict(data: Dictionary) -> Leaderboard:
		var lb = Leaderboard.new()
		lb.song_name = data.get("song_name", "Unknown")
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

func load_leaderboard(song_name: String) -> Leaderboard:
	"""Load a leaderboard for a specific song"""
	if leaderboards.has(song_name):
		return leaderboards[song_name]
	
	var path = LEADERBOARD_PATH + song_name + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		var lb = Leaderboard.new()
		lb.song_name = song_name
		leaderboards[song_name] = lb
		return lb
	
	var json = JSON.new()
	var data = json.parse(file.get_as_text())
	file.close()
	
	if data is Dictionary:
		var lb = Leaderboard.from_dict(data)
		leaderboards[song_name] = lb
		return lb
	
	var lb = Leaderboard.new()
	lb.song_name = song_name
	leaderboards[song_name] = lb
	return lb

func save_leaderboard(song_name: String) -> bool:
	"""Save a leaderboard to disk"""
	if not leaderboards.has(song_name):
		return false
	
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("leaderboards"):
		dir.make_dir("leaderboards")
	
	var path = LEADERBOARD_PATH + song_name + ".json"
	var lb = leaderboards[song_name]
	var json_str = JSON.stringify(lb.to_dict())
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func add_score(song_name: String, score: Score) -> bool:
	"""Add a score to a song's leaderboard"""
	var lb = load_leaderboard(song_name)
	var made_top_10 = lb.add_score(score)
	if made_top_10:
		save_leaderboard(song_name)
	return made_top_10

func get_leaderboard(song_name: String) -> Leaderboard:
	"""Get a leaderboard for a song"""
	return load_leaderboard(song_name)

func get_player_rank(song_name: String) -> int:
	"""Get player's rank on a leaderboard (-1 if not ranked)"""
	var lb = load_leaderboard(song_name)
	for i in range(lb.scores.size()):
		if lb.scores[i].player_name == "Player":
			return i + 1
	return -1
