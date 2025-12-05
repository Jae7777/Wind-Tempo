extends Control

@onready var chart_list = $MarginContainer/VBoxContainer/ChartListContainer/ChartList
@onready var back_button = $MarginContainer/VBoxContainer/BottomButtons/BackButton
@onready var refresh_button = $MarginContainer/VBoxContainer/BottomButtons/RefreshButton
@onready var download_button = $MarginContainer/VBoxContainer/BottomButtons/DownloadButton
@onready var chart_info_label = $MarginContainer/VBoxContainer/ChartInfoPanel/ChartInfoLabel

var available_charts: Array = []
var selected_chart_index: int = -1

func _ready() -> void:
	back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
	download_button.connect("pressed", Callable(self, "_on_download_pressed"))
	chart_list.connect("item_selected", Callable(self, "_on_chart_selected"))
	
	download_button.disabled = true
	_load_available_charts()

func _load_available_charts() -> void:
	chart_list.clear()
	available_charts.clear()
	chart_info_label.text = "Select a chart to view details"
	
	# Scan Charts directory for available charts
	var charts_dir = "res://Charts/"
	var dir = DirAccess.open(charts_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var chart_data = _load_chart_metadata(charts_dir + file_name)
				if chart_data:
					available_charts.append(chart_data)
					chart_list.add_item(chart_data["name"])
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if available_charts.size() == 0:
		chart_list.add_item("No charts available")
		chart_list.set_item_disabled(0, true)

func _load_chart_metadata(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		return {}
	
	var data = json.get_data()
	
	# Extract metadata or create default
	var chart_name = path.get_file().get_basename()
	var note_count = 0
	
	if typeof(data) == TYPE_DICTIONARY and data.has("notes"):
		note_count = data["notes"].size()
		if data.has("metadata"):
			var meta = data["metadata"]
			if meta.has("title"):
				chart_name = meta["title"]
	elif typeof(data) == TYPE_ARRAY:
		note_count = data.size()
	
	return {
		"name": chart_name,
		"path": path,
		"note_count": note_count,
		"author": "Unknown",
		"difficulty": "N/A"
	}

func _on_chart_selected(index: int) -> void:
	selected_chart_index = index
	
	if index >= 0 and index < available_charts.size():
		var chart = available_charts[index]
		var info_text = "Chart: %s\n" % chart["name"]
		info_text += "Author: %s\n" % chart["author"]
		info_text += "Notes: %d\n" % chart["note_count"]
		info_text += "Difficulty: %s\n" % chart["difficulty"]
		info_text += "\nPath: %s" % chart["path"]
		
		chart_info_label.text = info_text
		download_button.disabled = false
	else:
		chart_info_label.text = "Select a chart to view details"
		download_button.disabled = true

func _on_download_pressed() -> void:
	if selected_chart_index >= 0 and selected_chart_index < available_charts.size():
		var chart = available_charts[selected_chart_index]
		chart_info_label.text = "Chart already available locally:\n" + chart["path"]

func _on_refresh_pressed() -> void:
	_load_available_charts()
	chart_info_label.text = "Charts refreshed!"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
