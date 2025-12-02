extends Control

@onready var key_play: Button      = $LeftPanel/Piano/KeyPlay
@onready var key_settings: Button  = $LeftPanel/Piano/KeySettings
@onready var key_workshops: Button = $LeftPanel/Piano/KeyWorkshops
@onready var key_exit: Button      = $LeftPanel/Piano/KeyExit

func _ready() -> void:
	key_play.pressed.connect(_on_play)
	key_settings.pressed.connect(_on_settings)
	key_workshops.pressed.connect(_on_workshops)
	key_exit.pressed.connect(_on_exit)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("menu_play"):
		_on_play()
	elif Input.is_action_just_pressed("menu_settings"):
		_on_settings()
	elif Input.is_action_just_pressed("menu_workshops"):
		_on_workshops()
	elif Input.is_action_just_pressed("menu_exit"):
		_on_exit()

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Play.tscn")

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_workshops() -> void:
	get_tree().change_scene_to_file("res://scenes/Workshops.tscn")

func _on_exit() -> void:
	get_tree().quit()
