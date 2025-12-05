extends CanvasLayer

@onready var pause_panel = $PausePanel
@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@ontml:parameter name="restart_button = $PausePanel/VBoxContainer/RestartButton
@onready var main_menu_button = $PausePanel/VBoxContainer/MainMenuButton

var is_paused: bool = false

func _ready() -> void:
	pause_panel.visible = false
	resume_button.connect("pressed", Callable(self, "_on_resume_pressed"))
	restart_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_pressed"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	pause_panel.visible = is_paused
	get_tree().paused = is_paused

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")
