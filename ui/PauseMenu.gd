extends Control

"""
PauseMenu provides in-game pause functionality with resume/retry/quit options.
"""

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var retry_button = $VBoxContainer/RetryButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var menu_button = $VBoxContainer/MenuButton
@onready var stats_label = $VBoxContainer/StatsLabel

var game_controller: Node
var judgment_system: Node

func _ready() -> void:
	game_controller = get_tree().root.get_node_or_null("Main/GameController")
	judgment_system = get_tree().root.get_node_or_null("Main/JudgmentSystem")
	
	_connect_signals()
	hide()

func _connect_signals() -> void:
	"""Connect button signals."""
	resume_button.pressed.connect(_on_resume_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_pause_menu() -> void:
	"""Display pause menu with current stats."""
	if judgment_system:
		var stats = judgment_system.get_stats()
		stats_label.text = "Score: %d | Combo: %d | Accuracy: %.1f%%" % [
			stats["score"],
			stats["combo"],
			stats["accuracy"]
		]
	
	show()
	get_tree().paused = true

func _on_resume_pressed() -> void:
	"""Resume game."""
	get_tree().paused = false
	if game_controller:
		game_controller.resume_game()
	hide()

func _on_retry_pressed() -> void:
	"""Restart current song."""
	get_tree().paused = false
	if game_controller:
		game_controller.return_to_menu()
	hide()

func _on_settings_pressed() -> void:
	"""Open settings (TODO)."""
	print("Settings not yet implemented in pause menu")

func _on_menu_pressed() -> void:
	"""Return to main menu."""
	get_tree().paused = false
	if game_controller:
		game_controller.return_to_menu()
	hide()

func _input(event: InputEvent) -> void:
	"""Handle escape key to toggle pause."""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			_on_resume_pressed()
		else:
			show_pause_menu()
		get_tree().root.set_input_as_handled()
