extends Control

@onready var volume_slider = $VBoxContainer/Volume
@onready var fullscreen_checkbox = $VBoxContainer/Fullscreen
@onready var back_button = $VBoxContainer/Back

func _ready():
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	volume_slider.value = 100

	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

func _on_fullscreen_toggled(pressed):
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://path/to/MainMenu.tscn")
