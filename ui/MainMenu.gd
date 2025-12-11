extends Control

"""
MainMenu provides the primary navigation hub for the game.
Displays song selection, settings access, and game launch.
"""

@onready var song_list = $VBoxContainer/SongList
@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var info_label = $VBoxContainer/InfoLabel

var chart_library: Node
var game_controller: Node
var selected_chart_index: int = 0

func _ready() -> void:
	chart_library = get_tree().root.get_node_or_null("Main/ChartLibrary")
	game_controller = get_tree().root.get_node_or_null("Main/GameController")
	
	_setup_ui()
	_populate_song_list()
	_connect_signals()

func _setup_ui() -> void:
	"""Configure UI elements."""
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _populate_song_list() -> void:
	"""Populate song list from chart library."""
	if not chart_library:
		info_label.text = "Error: ChartLibrary not found"
		return
	
	var charts = chart_library.get_available_charts()
	for i in range(charts.size()):
		var entry = charts[i]
		var item_text = "%s - %s [%s]" % [entry.get_title(), entry.get_artist(), entry.get_difficulty()]
		song_list.add_item(item_text, i)
	
	song_list.item_selected.connect(_on_song_selected)
	info_label.text = "Ready to play! Select a song."

func _connect_signals() -> void:
	"""Connect to game controller signals."""
	if game_controller:
		game_controller.connect("state_changed", self, "_on_game_state_changed")

func _on_song_selected(index: int) -> void:
	"""Handle song selection."""
	selected_chart_index = index
	if chart_library:
		var entry = chart_library.get_chart_by_index(index)
		info_label.text = "Selected: %s by %s" % [entry.get_title(), entry.get_artist()]

func _on_start_pressed() -> void:
	"""Start the game with selected chart."""
	if game_controller:
		game_controller.select_chart(selected_chart_index)
		game_controller.start_game()
		hide()

func _on_settings_pressed() -> void:
	"""Open settings menu."""
	print("Settings menu not yet implemented")

func _on_quit_pressed() -> void:
	"""Quit the game."""
	get_tree().quit()

func return_to_menu() -> void:
	"""Return to main menu from game."""
	show()
