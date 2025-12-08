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
		if score.score > scores[max_scores - 1].score:
			scores[max_scores - 1] = score
			_sort_scores()
			return true
		return false
	
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