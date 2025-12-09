extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Hide the menu initially. It will be shown by the main game script.
	hide()

# --- BUTTON SIGNALS ---
# Connect these functions to the 'pressed()' signal of their respective buttons.

func _on_Resume_pressed():
	# Un-pause the game and hide the menu.
	get_tree().paused = false
	hide()

func _on_Restart_pressed():
	# Reload the current scene, effectively restarting the song.
	# Note: Un-pausing the game first is good practice.
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_Options_pressed():
	# Placeholder for showing the Options sub-menu.
	print("Options button pressed!")
	# You would typically instance and add a separate Options scene here.

func _on_Main_Menu_pressed():
	# Un-pause and switch to the main menu scene.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_resume_button_pressed() -> void:
	pass # Replace with function body.


func _on_restart_button_pressed() -> void:
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_button_pressed() -> void:
	pass # Replace with function body.
