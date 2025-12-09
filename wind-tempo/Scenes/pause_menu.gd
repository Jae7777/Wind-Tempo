# Scenes/pause_menu.gd
# Pause menu popup UI
extends Control

@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $PanelContainer/VBoxContainer/MenuButton

var pause_manager: Node = null

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Ensure pause menu stays visible when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func setup(manager: Node) -> void:
	"""Set reference to pause manager"""
	pause_manager = manager

func _on_resume_pressed() -> void:
	"""Resume game"""
	if pause_manager:
		pause_manager.resume()

func _on_restart_pressed() -> void:
	"""Restart current song"""
	if pause_manager:
		pause_manager.restart_song()

func _on_menu_pressed() -> void:
	"""Return to song select"""
	if pause_manager:
		pause_manager.return_to_menu()
