extends Node

"""
ReplaySystem records and playbacks player inputs for review and practice.
Stores input sequences with timing data for later replay.
"""

const REPLAYS_PATH = "user://replays/"

class Replay:
	var metadata: Dictionary
	var input_events: Array
	
	func _init(p_metadata: Dictionary) -> void:
		metadata = p_metadata
		input_events = []
	
	func add_input(lane: int, timestamp: float) -> void:
		input_events.append({"lane": lane, "timestamp": timestamp})
	
	func get_replay_length() -> float:
		if input_events.is_empty():
			return 0.0
		return input_events[-1]["timestamp"]

var current_replay: Replay = null
var is_recording: bool = false
var playback_replays: Array = []

signal replay_started(metadata: Dictionary)
signal replay_stopped(replay: Replay)
signal replay_input(lane: int, timestamp: float)
signal replay_list_updated

func _ready() -> void:
	"""Initialize replay system."""
	if not DirAccess.dir_exists_absolute(REPLAYS_PATH):
		DirAccess.make_abs_absolute(REPLAYS_PATH)
	_load_replays()

func start_recording(song_title: String, artist: String, difficulty: String, chart_path: String) -> void:
	"""Begin recording a new replay."""
	var metadata = {
		"song_title": song_title,
		"artist": artist,
		"difficulty": difficulty,
		"chart_path": chart_path,
		"timestamp": Time.get_ticks_msec(),
		"date": Time.get_datetime_string_from_system()
	}
	
	current_replay = Replay.new(metadata)
	is_recording = true
	emit_signal("replay_started", metadata)

func stop_recording() -> void:
	"""Stop recording and save the replay."""
	if current_replay == null:
		return
	
	is_recording = false
	_save_replay(current_replay)
	emit_signal("replay_stopped", current_replay)
	current_replay = null

func record_input(lane: int) -> void:
	"""Record an input during playback."""
	if not is_recording or current_replay == null:
		return
	
	var timestamp = get_node("/root/Main/AudioManager").get_playback_position()
	current_replay.add_input(lane, timestamp)

func get_saved_replays() -> Array:
	"""Get list of all saved replays."""
	return playback_replays.duplicate()

func get_replay_by_index(index: int) -> Replay:
	"""Get a specific replay by index."""
	if index < 0 or index >= playback_replays.size():
		return null
	return playback_replays[index]

func load_replay(index: int) -> Replay:
	"""Load a replay for playback."""
	var replay = get_replay_by_index(index)
	if replay:
		return replay
	return null

func delete_replay(index: int) -> void:
	"""Delete a saved replay."""
	if index < 0 or index >= playback_replays.size():
		return
	
	var replay = playback_replays[index]
	var filename = _get_replay_filename(replay.metadata)
	
	var file = FileAccess.open(REPLAYS_PATH + filename, FileAccess.WRITE)
	if file:
		file = null
	
	playback_replays.remove_at(index)
	emit_signal("replay_list_updated")

func _save_replay(replay: Replay) -> void:
	"""Save a replay to disk as JSON."""
	var filename = _get_replay_filename(replay.metadata)
	var filepath = REPLAYS_PATH + filename
	
	var data = {
		"metadata": replay.metadata,
		"input_events": replay.input_events
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		playback_replays.append(replay)
		emit_signal("replay_list_updated")
	else:
		push_error("Failed to save replay to: %s" % filepath)

func _load_replays() -> void:
	"""Load all saved replays from disk."""
	playback_replays.clear()
	
	var dir = DirAccess.open(REPLAYS_PATH)
	if not dir:
		return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	
	while filename != "":
		if filename.ends_with(".json"):
			var filepath = REPLAYS_PATH + filename
			var file = FileAccess.open(filepath, FileAccess.READ)
			
			if file:
				var json_string = file.get_as_text()
				var json = JSON.new()
				
				if json.parse(json_string) == OK:
					var data = json.data
					if data and "metadata" in data and "input_events" in data:
						var replay = Replay.new(data["metadata"])
						replay.input_events = data["input_events"]
						playback_replays.append(replay)
		
		filename = dir.get_next()

func _get_replay_filename(metadata: Dictionary) -> String:
	"""Generate a filename for a replay."""
	var song = metadata.get("song_title", "Unknown").to_lower().replace(" ", "_")
	var timestamp = metadata.get("timestamp", 0)
	return "%s_%d.json" % [song, timestamp]

func get_replay_duration(replay: Replay) -> float:
	"""Get the total duration of a replay."""
	if replay == null or replay.input_events.is_empty():
		return 0.0
	return replay.get_replay_length()

func get_replay_stats(replay: Replay) -> Dictionary:
	"""Get statistics about a replay."""
	if replay == null:
		return {}
	
	return {
		"input_count": replay.input_events.size(),
		"duration": get_replay_duration(replay),
		"song_title": replay.metadata.get("song_title", "Unknown"),
		"artist": replay.metadata.get("artist", "Unknown"),
		"difficulty": replay.metadata.get("difficulty", "Unknown"),
		"date": replay.metadata.get("date", "Unknown")
	}
