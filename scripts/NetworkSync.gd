extends Node

"""
NetworkSync provides foundation for real-time multiplayer synchronization.
Handles game state sync, latency compensation, and player coordination.
"""

class PlayerState:
	var player_id: String
	var score: int = 0
	var accuracy: float = 0.0
	var combo: int = 0
	var current_note_index: int = 0
	var is_connected: bool = true
	var last_update: int
	
	func _init(p_id: String) -> void:
		player_id = p_id
		last_update = Time.get_ticks_msec()

@onready var event_bus = get_node("/root/Main/EventBus") if has_node("/root/Main/EventBus") else null

var local_player_state: PlayerState = null
var remote_player_states: Dictionary = {}
var network_latency: float = 0.0
var is_host: bool = false
var sync_interval: float = 0.1  # Sync every 100ms
var time_since_last_sync: float = 0.0

signal player_state_updated(player_id: String, state: PlayerState)
signal latency_changed(latency: float)
signal sync_completed
signal network_error(error: String)

func _ready() -> void:
	"""Initialize network sync."""
	if event_bus:
		_connect_events()

func _process(delta: float) -> void:
	"""Process network updates."""
	time_since_last_sync += delta
	
	if time_since_last_sync >= sync_interval:
		_perform_sync()
		time_since_last_sync = 0.0

func _connect_events() -> void:
	"""Connect to game events."""
	if event_bus:
		event_bus.connect("note_hit", Callable(self, "_on_note_hit"))
		event_bus.connect("combo_changed", Callable(self, "_on_combo_changed"))
		event_bus.connect("score_changed", Callable(self, "_on_score_changed"))

func initialize_local_player(player_id: String) -> void:
	"""Initialize local player state."""
	local_player_state = PlayerState.new(player_id)

func add_remote_player(player_id: String) -> void:
	"""Add a remote player to track."""
	if player_id not in remote_player_states:
		remote_player_states[player_id] = PlayerState.new(player_id)

func remove_remote_player(player_id: String) -> void:
	"""Remove a remote player from tracking."""
	if player_id in remote_player_states:
		remote_player_states.erase(player_id)

func update_local_state(score: int, accuracy: float, combo: int, note_index: int) -> void:
	"""Update local player state."""
	if local_player_state == null:
		return
	
	local_player_state.score = score
	local_player_state.accuracy = accuracy
	local_player_state.combo = combo
	local_player_state.current_note_index = note_index
	local_player_state.last_update = Time.get_ticks_msec()

func update_remote_state(player_id: String, state_data: Dictionary) -> void:
	"""Update remote player state."""
	if player_id not in remote_player_states:
		add_remote_player(player_id)
	
	var state = remote_player_states[player_id]
	state.score = state_data.get("score", 0)
	state.accuracy = state_data.get("accuracy", 0.0)
	state.combo = state_data.get("combo", 0)
	state.current_note_index = state_data.get("note_index", 0)
	state.last_update = Time.get_ticks_msec()
	
	emit_signal("player_state_updated", player_id, state)

func get_local_state() -> Dictionary:
	"""Get local player state as dictionary."""
	if local_player_state == null:
		return {}
	
	return {
		"player_id": local_player_state.player_id,
		"score": local_player_state.score,
		"accuracy": local_player_state.accuracy,
		"combo": local_player_state.combo,
		"note_index": local_player_state.current_note_index,
		"timestamp": local_player_state.last_update
	}

func get_remote_state(player_id: String) -> Dictionary:
	"""Get remote player state as dictionary."""
	if player_id not in remote_player_states:
		return {}
	
	var state = remote_player_states[player_id]
	return {
		"player_id": state.player_id,
		"score": state.score,
		"accuracy": state.accuracy,
		"combo": state.combo,
		"note_index": state.current_note_index,
		"is_connected": state.is_connected
	}

func get_all_remote_states() -> Dictionary:
	"""Get all remote player states."""
	var states = {}
	for player_id in remote_player_states:
		states[player_id] = get_remote_state(player_id)
	return states

func set_network_latency(latency: float) -> void:
	"""Set the detected network latency in milliseconds."""
	network_latency = latency
	emit_signal("latency_changed", latency)

func get_network_latency() -> float:
	"""Get current network latency."""
	return network_latency

func compensate_for_latency(action_time: float) -> float:
	"""Adjust action time to compensate for network latency."""
	return action_time - (network_latency / 1000.0)

func calculate_reconciliation_offset() -> float:
	"""Calculate frame offset for reconciliation."""
	return network_latency / 1000.0 * 60.0  # Assuming 60 FPS

func detect_latency() -> void:
	"""Ping remote to detect latency."""
	var ping_time = Time.get_ticks_msec()
	# Simulate round-trip ping
	await get_tree().create_timer(0.05).timeout
	var pong_time = Time.get_ticks_msec()
	var latency = pong_time - ping_time
	set_network_latency(float(latency))

func set_host(host: bool) -> void:
	"""Set whether this player is the host."""
	is_host = host

func is_network_host() -> bool:
	"""Check if this player is the network host."""
	return is_host

func _perform_sync() -> void:
	"""Perform periodic network sync."""
	if local_player_state == null:
		return
	
	var state_data = get_local_state()
	
	# Broadcast local state to all remote players
	for player_id in remote_player_states:
		_send_state_to_player(player_id, state_data)
	
	emit_signal("sync_completed")

func _send_state_to_player(player_id: String, state_data: Dictionary) -> void:
	"""Send state update to a specific player."""
	# This would be replaced with actual network transmission
	# For now, it's a placeholder for local testing
	pass

func _on_note_hit(judgment: String) -> void:
	"""Track note hits for sync."""
	if local_player_state:
		local_player_state.current_note_index += 1

func _on_combo_changed(combo: int) -> void:
	"""Track combo changes for sync."""
	if local_player_state:
		local_player_state.combo = combo

func _on_score_changed(score: int) -> void:
	"""Track score changes for sync."""
	if local_player_state:
		local_player_state.score = score

func check_player_connection(player_id: String) -> bool:
	"""Check if a remote player is still connected."""
	if player_id not in remote_player_states:
		return false
	
	var state = remote_player_states[player_id]
	var time_since_update = (Time.get_ticks_msec() - state.last_update) / 1000.0
	
	if time_since_update > 5.0:  # 5 second timeout
		state.is_connected = false
		return false
	
	return true

func get_leaderboard_snapshot() -> Array:
	"""Get a snapshot of current leaderboard."""
	var snapshot = []
	
	if local_player_state:
		snapshot.append(get_local_state())
	
	for player_id in remote_player_states:
		snapshot.append(get_remote_state(player_id))
	
	# Sort by score descending
	snapshot.sort_custom(func(a, b): return a["score"] > b["score"])
	
	return snapshot

func reset_sync() -> void:
	"""Reset all network state."""
	local_player_state = null
	remote_player_states.clear()
	network_latency = 0.0
	time_since_last_sync = 0.0
