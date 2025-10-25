extends Control

@onready var volume_slider = $Panel/VBoxContainer/MarginContainer/InnerVBox/VolumeContainer/VolumeHBox/VolumeSlider
@onready var volume_value_label = $Panel/VBoxContainer/MarginContainer/InnerVBox/VolumeContainer/VolumeHBox/VolumeValueLabel
@onready var fullscreen_checkbox = $Panel/VBoxContainer/MarginContainer/InnerVBox/FullscreenContainer/FullscreenCheckBox
@onready var back_button = $Panel/VBoxContainer/MarginContainer/InnerVBox/ButtonContainer/BackButton
@onready var exit_button = $Panel/VBoxContainer/MarginContainer/InnerVBox/ButtonContainer/ExitButton

func _ready():
	# Set initial fullscreen state
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Set initial volume to 100%
	volume_slider.value = 100
	_update_volume_label(100)
	
	# Connect signals
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(value: float) -> void:
	# Convert slider value (0-100) to decibels
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, volume_db)
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	volume_value_label.text = "%d%%" % int(value)

func _on_back_pressed() -> void:
	# TODO: change back to your main menu scene 
	get_tree().change_scene_to_file("res://scenes/Main.tscn")  # update this path later

func _on_exit_pressed() -> void:
	# Quit the game
	get_tree().quit()
