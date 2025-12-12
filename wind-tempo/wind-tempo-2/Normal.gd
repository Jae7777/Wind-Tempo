extends Control

# Path back to the Difficulty Selection Scene
const DIFFICULTY_SCENE_PATH = "res://control.tscn" 

func _on_return_pressed():
	print("Returning to Difficulty Selection.")
	get_tree().change_scene_to_file(DIFFICULTY_SCENE_PATH)

func _on_track_1_pressed() -> void:
	print("Starting Easy Track 1.")


func _on_track_2_pressed() -> void:
	print("Starting Easy Track 2.")


func _on_track_3_pressed() -> void:
	print("Starting Easy Track 3.")
