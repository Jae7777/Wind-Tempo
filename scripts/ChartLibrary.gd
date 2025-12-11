extends Node

"""
ChartLibrary manages available charts and provides song selection.
Maintains a registry of all available charts with metadata.
"""

class ChartEntry:
	var file_path: String
	var metadata: Dictionary
	
	func _init(path: String, meta: Dictionary) -> void:
		file_path = path
		metadata = meta
	
	func get_title() -> String:
		return metadata.get("title", "Unknown")
	
	func get_artist() -> String:
		return metadata.get("artist", "Unknown")
	
	func get_difficulty() -> String:
		return metadata.get("difficulty", "Normal")

var available_charts: Array = []
var chart_loader: Node

func _ready() -> void:
	chart_loader = get_parent().get_node_or_null("ChartLoader")
	_initialize_library()

func _initialize_library() -> void:
	"""Initialize the library with available charts."""
	# Define available charts
	var chart_data = [
		{"path": "res://charts/easy_mode.json", "title": "Easy Mode"},
		{"path": "res://charts/sample_song.json", "title": "Sample Song"},
		{"path": "res://charts/hard_mode.json", "title": "Hard Mode"}
	]
	
	for chart_info in chart_data:
		if chart_loader:
			var chart = chart_loader.load_chart(chart_info["path"])
			if chart:
				var entry = ChartEntry.new(chart_info["path"], chart.metadata)
				available_charts.append(entry)
				print("Registered chart: %s" % entry.get_title())

func get_available_charts() -> Array:
	"""Return list of available chart entries."""
	return available_charts

func get_chart_by_index(index: int) -> ChartEntry:
	"""Get a chart entry by index."""
	if index >= 0 and index < available_charts.size():
		return available_charts[index]
	return null

func get_chart_by_title(title: String) -> ChartEntry:
	"""Find a chart by title."""
	for entry in available_charts:
		if entry.get_title() == title:
			return entry
	return null

func get_chart_count() -> int:
	"""Return total number of available charts."""
	return available_charts.size()

func print_library() -> void:
	"""Print all available charts."""
	print("\n=== Chart Library ===")
	for i in range(available_charts.size()):
		var entry = available_charts[i]
		print("[%d] %s by %s (Difficulty: %s)" % [
			i,
			entry.get_title(),
			entry.get_artist(),
			entry.get_difficulty()
		])
	print("Total: %d charts" % available_charts.size())
