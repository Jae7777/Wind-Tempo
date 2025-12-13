# PauseMenu.gd
extends Control

# This function is called when the Resume button is pressed
func _on_resume_pressed():
	# 1. Unpause the game time
	get_tree().paused = false 
	# 2. Queue this pause menu scene for deletion
	queue_free()

# This function is called when the Quit button is pressed
func _on_quit_pressed():
	# 1. Unpause the game time (important before leaving the track scene)
	get_tree().paused = false
	# 2. Go back to the main menu (replace with your actual main menu path)
	get_tree().change_scene_to_file("res://start.tscn")
	
# This function is called when the Restart button is pressed
func _on_restart_pressed():
	# 1. Unpause the game time
	get_tree().paused = false
	# 2. Restart the current scene
	get_tree().reload_current_scene()
