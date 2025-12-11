extends Control

"""
SongSelectUI provides an interactive song selection experience with preview and difficulty info.
"""

@onready var song_grid = $VBoxContainer/SongGrid
@onready var song_info = $VBoxContainer/SongInfo
@onready var difficulty_buttons = $VBoxContainer/DifficultyButtons
@onready var back_button = $VBoxContainer/BackButton

var chart_library: Node
var chart_entries: Array = []
var selected_index: int = 0

func _ready() -> void:
	chart_library = get_tree().root.get_node_or_null("Main/ChartLibrary")
	_setup_ui()
	_populate_songs()
	_connect_signals()
	hide()

func _setup_ui() -> void:
	"""Configure UI elements."""
	back_button.pressed.connect(_on_back_pressed)

func _populate_songs() -> void:
	"""Populate song grid from chart library."""
	if not chart_library:
		return
	
	chart_entries = chart_library.get_available_charts()
	
	for i in range(chart_entries.size()):
		var entry = chart_entries[i]
		var button = Button.new()
		button.text = "%s\n%s" % [entry.get_title(), entry.get_artist()]
		button.pressed.connect(func(): _on_song_selected(i))
		song_grid.add_child(button)

func _connect_signals() -> void:
	"""Connect internal signals."""
	pass

func _on_song_selected(index: int) -> void:
	"""Handle song selection."""
	selected_index = index
	var entry = chart_entries[index]
	
	song_info.text = """
Title: %s
Artist: %s
Difficulty: %s
""" % [entry.get_title(), entry.get_artist(), entry.get_difficulty()]

func _on_back_pressed() -> void:
	"""Return to main menu."""
	hide()

func get_selected_chart_index() -> int:
	"""Get index of selected chart."""
	return selected_index
