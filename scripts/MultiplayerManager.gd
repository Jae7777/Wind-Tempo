extends Node

"""
MultiplayerManager handles multiplayer game logic and matchmaking.
Provides foundation for local co-op and future online features.
"""

class GameSession:
	var id: String
	var players: Array
	var mode: String
	var chart: String
	var difficulty: String
	var created_at: int
	
	func _init(p_id: String, p_mode: String, p_chart: String, p_difficulty: String) -> void:
		id = p_id
		mode = p_mode
		chart = p_chart
		difficulty = p_difficulty
		players = []
		created_at = Time.get_ticks_msec()

class Player:
	var id: String
	var name: String
	var score: int = 0
	var accuracy: float = 0.0
	var combo: int = 0
	var rank: String = "F"
	
	func _init(p_id: String, p_name: String) -> void:
		id = p_id
		name = p_name

var current_session: GameSession = null
var local_players: Array = []
var max_players: int = 4

signal session_created(session_id: String)
signal session_started
signal session_ended(results: Dictionary)
signal player_joined(player_name: String)
signal player_left(player_name: String)
signal player_score_updated(player_name: String, score: int, rank: String)
signal round_completed(results: Dictionary)

func _ready() -> void:
	"""Initialize multiplayer manager."""
	pass

func create_session(mode: String, chart: String, difficulty: String, player_names: Array) -> String:
	"""Create a new multiplayer session."""
	if player_names.size() > max_players:
		push_error("Too many players for session")
		return ""
	
	var session_id = _generate_session_id()
	current_session = GameSession.new(session_id, mode, chart, difficulty)
	
	local_players.clear()
	for player_name in player_names:
		var player = Player.new(_generate_player_id(), player_name)
		current_session.players.append(player)
		local_players.append(player)
	
	emit_signal("session_created", session_id)
	return session_id

func start_session() -> void:
	"""Start the current session."""
	if current_session == null:
		return
	
	emit_signal("session_started")

func end_session(results: Dictionary) -> void:
	"""End the current session."""
	if current_session == null:
		return
	
	emit_signal("session_ended", results)
	current_session = null

func add_player(player_name: String) -> bool:
	"""Add a player to current session."""
	if current_session == null:
		return false
	
	if current_session.players.size() >= max_players:
		return false
	
	var player = Player.new(_generate_player_id(), player_name)
	current_session.players.append(player)
	local_players.append(player)
	
	emit_signal("player_joined", player_name)
	return true

func remove_player(player_id: String) -> void:
	"""Remove a player from current session."""
	if current_session == null:
		return
	
	for i in range(current_session.players.size()):
		if current_session.players[i].id == player_id:
			var player_name = current_session.players[i].name
			current_session.players.remove_at(i)
			emit_signal("player_left", player_name)
			break

func update_player_score(player_id: String, score: int, accuracy: float, combo: int, rank: String) -> void:
	"""Update a player's score during gameplay."""
	if current_session == null:
		return
	
	for player in current_session.players:
		if player.id == player_id:
			player.score = score
			player.accuracy = accuracy
			player.combo = combo
			player.rank = rank
			emit_signal("player_score_updated", player.name, score, rank)
			return

func get_session_players() -> Array:
	"""Get all players in current session."""
	if current_session == null:
		return []
	return current_session.players.duplicate()

func get_player(player_id: String) -> Player:
	"""Get a specific player."""
	if current_session == null:
		return null
	
	for player in current_session.players:
		if player.id == player_id:
			return player
	return null

func get_leaderboard() -> Array:
	"""Get players sorted by score."""
	if current_session == null:
		return []
	
	var sorted_players = current_session.players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	return sorted_players

func get_session_info() -> Dictionary:
	"""Get information about current session."""
	if current_session == null:
		return {}
	
	return {
		"id": current_session.id,
		"mode": current_session.mode,
		"chart": current_session.chart,
		"difficulty": current_session.difficulty,
		"player_count": current_session.players.size(),
		"created_at": current_session.created_at
	}

func get_supported_modes() -> Array:
	"""Get available multiplayer modes."""
	return [
		{"name": "Co-op", "description": "Play together on the same song"},
		{"name": "Battle", "description": "Compete for the highest score"},
		{"name": "Survival", "description": "Last player to maintain combo wins"},
		{"name": "Tag Team", "description": "Take turns hitting notes"}
	]

func _generate_session_id() -> String:
	"""Generate a unique session ID."""
	return "%s_%d" % [RandomNumberGenerator.new().randf_range(1000, 9999), Time.get_ticks_msec()]

func _generate_player_id() -> String:
	"""Generate a unique player ID."""
	return "player_%d" % Time.get_ticks_msec()

func reset() -> void:
	"""Reset multiplayer state."""
	current_session = null
	local_players.clear()
