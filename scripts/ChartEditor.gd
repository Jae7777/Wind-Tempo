extends Node

"""
ChartEditor provides tools for creating and editing custom rhythm charts.
Supports JSON export and visual editing with playback preview.
"""

class EditableChart:
	var title: String
	var artist: String
	var bpm: float
	var difficulty: String
	var notes: Array
	var offset: float
	
	func _init(p_title: String = "", p_artist: String = "", p_bpm: float = 120.0) -> void:
		title = p_title
		artist = p_artist
		bpm = p_bpm
		difficulty = "Normal"
		notes = []
		offset = 0.0

@onready var event_bus = get_node("/root/Main/EventBus") if has_node("/root/Main/EventBus") else null

var current_chart: EditableChart = null
var is_editing: bool = false
var playback_time: float = 0.0
var bpm_base: float = 120.0

signal chart_created(chart: EditableChart)
signal chart_loaded(chart: EditableChart)
signal chart_saved(path: String)
signal note_added(note_data: Dictionary)
signal note_removed(note_index: int)
signal chart_modified
signal playback_started
signal playback_stopped

func _ready() -> void:
	"""Initialize chart editor."""
	pass

func create_new_chart(title: String, artist: String, bpm: float) -> EditableChart:
	"""Create a new blank chart."""
	current_chart = EditableChart.new(title, artist, bpm)
	is_editing = true
	emit_signal("chart_created", current_chart)
	return current_chart

func add_note(lane: int, time: float, duration: float = 0.0) -> void:
	"""Add a note to the chart."""
	if current_chart == null:
		return
	
	var note_data = {
		"lane": lane,
		"time": time,
		"duration": duration
	}
	
	current_chart.notes.append(note_data)
	current_chart.notes.sort_custom(func(a, b): return a["time"] < b["time"])
	
	emit_signal("note_added", note_data)
	emit_signal("chart_modified")

func remove_note(index: int) -> void:
	"""Remove a note from the chart."""
	if current_chart == null or index < 0 or index >= current_chart.notes.size():
		return
	
	current_chart.notes.remove_at(index)
	emit_signal("note_removed", index)
	emit_signal("chart_modified")

func clear_chart() -> void:
	"""Clear all notes from the chart."""
	if current_chart:
		current_chart.notes.clear()
		emit_signal("chart_modified")

func save_chart(file_path: String) -> bool:
	"""Save chart to JSON file."""
	if current_chart == null:
		return false
	
	var chart_data = {
		"metadata": {
			"title": current_chart.title,
			"artist": current_chart.artist,
			"bpm": current_chart.bpm,
			"difficulty": current_chart.difficulty,
			"offset": current_chart.offset
		},
		"notes": current_chart.notes
	}
	
	var json_string = JSON.stringify(chart_data)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		emit_signal("chart_saved", file_path)
		return true
	
	return false

func load_chart(file_path: String) -> EditableChart:
	"""Load a chart from JSON file."""
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		return null
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_string) != OK:
		return null
	
	var data = json.data
	if not data or "metadata" not in data or "notes" not in data:
		return null
	
	var metadata = data["metadata"]
	current_chart = EditableChart.new(
		metadata.get("title", ""),
		metadata.get("artist", ""),
		metadata.get("bpm", 120.0)
	)
	
	current_chart.difficulty = metadata.get("difficulty", "Normal")
	current_chart.offset = metadata.get("offset", 0.0)
	current_chart.notes = data["notes"]
	
	is_editing = true
	emit_signal("chart_loaded", current_chart)
	
	return current_chart

func get_current_chart() -> EditableChart:
	"""Get the currently edited chart."""
	return current_chart

func get_notes_in_range(start_time: float, end_time: float) -> Array:
	"""Get all notes within a time range."""
	if current_chart == null:
		return []
	
	var notes_in_range = []
	for note in current_chart.notes:
		if note["time"] >= start_time and note["time"] <= end_time:
			notes_in_range.append(note)
	
	return notes_in_range

func get_note_count() -> int:
	"""Get total number of notes in chart."""
	return current_chart.notes.size() if current_chart else 0

func get_chart_duration() -> float:
	"""Get duration of chart (time of last note)."""
	if current_chart == null or current_chart.notes.is_empty():
		return 0.0
	
	return current_chart.notes[-1]["time"]

func set_chart_bpm(bpm: float) -> void:
	"""Set chart BPM."""
	if current_chart:
		current_chart.bpm = bpm
		emit_signal("chart_modified")

func set_chart_difficulty(difficulty: String) -> void:
	"""Set chart difficulty."""
	if current_chart:
		current_chart.difficulty = difficulty
		emit_signal("chart_modified")

func set_chart_offset(offset: float) -> void:
	"""Set chart audio offset."""
	if current_chart:
		current_chart.offset = offset
		emit_signal("chart_modified")

func time_to_beat(time: float) -> float:
	"""Convert time in seconds to beat position."""
	return (time * current_chart.bpm) / 60.0 if current_chart else 0.0

func beat_to_time(beat: float) -> float:
	"""Convert beat position to time in seconds."""
	return (beat * 60.0) / current_chart.bpm if current_chart else 0.0

func validate_chart() -> Dictionary:
	"""Validate chart for common issues."""
	var issues = []
	
	if current_chart == null:
		return {"valid": false, "issues": ["No chart loaded"]}
	
	if current_chart.title.is_empty():
		issues.append("Chart title is empty")
	
	if current_chart.artist.is_empty():
		issues.append("Chart artist is empty")
	
	if current_chart.bpm <= 0:
		issues.append("Invalid BPM")
	
	if current_chart.notes.is_empty():
		issues.append("Chart has no notes")
	
	# Check for invalid lanes
	for note in current_chart.notes:
		if note["lane"] < 0 or note["lane"] > 3:
			issues.append("Invalid lane: %d" % note["lane"])
		
		if note["time"] < 0:
			issues.append("Negative note time")
	
	return {
		"valid": issues.is_empty(),
		"issues": issues
	}

func get_chart_statistics() -> Dictionary:
	"""Get statistics about the chart."""
	if current_chart == null:
		return {}
	
	var lane_counts = [0, 0, 0, 0]
	var total_duration = get_chart_duration()
	
	for note in current_chart.notes:
		lane_counts[note["lane"]] += 1
	
	var notes_per_second = 0.0
	if total_duration > 0:
		notes_per_second = float(current_chart.notes.size()) / total_duration
	
	return {
		"note_count": current_chart.notes.size(),
		"duration": total_duration,
		"notes_per_second": notes_per_second,
		"lane_distribution": lane_counts,
		"bpm": current_chart.bpm,
		"difficulty": current_chart.difficulty
	}

func close_chart() -> void:
	"""Close the current chart."""
	current_chart = null
	is_editing = false
	playback_time = 0.0
