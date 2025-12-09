# scripts/pause_manager.gd
# Manages pause state and pause menu interactions
extends Node

signal paused
signal resumed

var is_paused: bool = false
var pause_menu_scene: PackedScene = preload("res://Scenes/pause_menu.tscn")
var current_pause_menu: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			resume()
		else:
			pause()
		get_tree().root.set_input_as_handled()

func pause() -> void:
	"""Pause the game and show pause menu"""
	if is_paused:
		return
	
	is_paused = true
	get_tree().paused = true
	
	if current_pause_menu == null:
		current_pause_menu = pause_menu_scene.instantiate()
		get_tree().root.add_child(current_pause_menu)
		current_pause_menu.setup(self)
	
	paused.emit()

func resume() -> void:
	"""Resume the game and hide pause menu"""
	if not is_paused:
		return
	
	is_paused = false
	get_tree().paused = false
	
	if current_pause_menu:
		current_pause_menu.queue_free()
		current_pause_menu = null
	
	resumed.emit()

func restart_song() -> void:
	"""Restart the current song"""
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	"""Return to song select menu"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/song_select.tscn")
