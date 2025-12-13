# PauseMenu.gd
extends Control

# Path to the main menu scene for the Quit button
const MAIN_MENU_PATH = "res://start.tscn"

# This function is called when the Resume button is pressed
func _on_resume_pressed():
	# 1. Unpause the game time globally
	get_tree().paused = false 
	# 2. Remove the menu instance from the scene tree
	queue_free()

# This function is called when the Restart button is pressed
func _on_restart_pressed():
	# 1. Unpause the game time
	get_tree().paused = false
	# 2. Reload the current track scene
	get_tree().reload_current_scene()
	
# This function is called when the Quit button is pressed
func _on_quit_pressed():
	# 1. Unpause the game time before leaving
	get_tree().paused = false
	# 2. Return to the main menu
	if FileAccess.file_exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
	else:
		print("ERROR: Main menu scene not found at: ", MAIN_MENU_PATH)
