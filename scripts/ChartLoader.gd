extends Node

"""
ChartLoader handles loading and parsing chart files (JSON format).
Charts define note timing and lane positions for a song.
"""

class Chart:
	var metadata: Dictionary
	var notes: Array
	
	func _init(meta: Dictionary, note_list: Array) -> void:
		metadata = meta
		notes = note_list
	
	func get_title() -> String:
		return metadata.get("title", "Unknown")
	
	func get_artist() -> String:
		return metadata.get("artist", "Unknown")
	
	func get_duration() -> float:
		return metadata.get("duration", 0.0)
	
	func get_bpm() -> float:
		return metadata.get("bpm", 120.0)
	
	func get_offset() -> float:
		return metadata.get("offset", 0.0)

signal chart_loaded(chart: Chart)
signal load_error(message: String)

func load_chart(file_path: String) -> Chart:
	"""Load and parse a chart file."""
	if not ResourceLoader.exists(file_path):
		var error_msg = "Chart file not found: %s" % file_path
		emit_signal("load_error", error_msg)
		push_error(error_msg)
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error_msg = "Failed to open chart: %s" % file_path
		emit_signal("load_error", error_msg)
		push_error(error_msg)
		return null
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		var error_msg = "JSON parse error in chart: %s" % file_path
		emit_signal("load_error", error_msg)
		push_error(error_msg)
		return null
	
	var data = json.get_data()
	if not data.has("metadata") or not data.has("notes"):
		var error_msg = "Invalid chart format (missing metadata or notes)"
		emit_signal("load_error", error_msg)
		push_error(error_msg)
		return null
	
	var chart = Chart.new(data["metadata"], data["notes"])
	emit_signal("chart_loaded", chart)
	return chart

func validate_chart(chart: Chart) -> bool:
	"""Validate chart integrity."""
	if chart == null:
		return false
	
	if chart.notes.is_empty():
		push_warning("Chart has no notes")
		return false
	
	# Validate each note
	for note in chart.notes:
		if not note.has("time") or not note.has("lane"):
			push_error("Invalid note format: missing time or lane")
			return false
		
		if note["lane"] < 0 or note["lane"] > 3:
			push_error("Invalid lane: %d (must be 0-3)" % note["lane"])
			return false
	
	return true
