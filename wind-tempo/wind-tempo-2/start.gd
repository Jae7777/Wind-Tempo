extends Control

# IMPORTANT: Ensure this path correctly points to your Difficulty Selection scene file (control.tscn)
const DIFFICULTY_SCENE_PATH = "res://control.tscn" 

func _on_button_pressed() -> void:
	print("Start button pressed. Loading difficulty selection screen.")
	
	if FileAccess.file_exists(DIFFICULTY_SCENE_PATH):
		get_tree().change_scene_to_file(DIFFICULTY_SCENE_PATH)
	else:
		print("ERROR: Difficulty scene not found at: ", DIFFICULTY_SCENE_PATH)
