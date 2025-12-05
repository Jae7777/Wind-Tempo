extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var workshop_button = $VBoxContainer/WorkshopButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready() -> void:
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))
	workshop_button.connect("pressed", Callable(self, "_on_workshop_pressed"))
	quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))

func _on_play_pressed() -> void:
	# Load the gameplay scene
	get_tree().change_scene_to_file("res://CoreGameplay/Main.tscn")

func _on_workshop_pressed() -> void:
	get_tree().change_scene_to_file("res://Workshop.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
