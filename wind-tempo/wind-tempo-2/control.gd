extends Control

var difficulties = ["Easy", "Normal", "Hard"]
var current_index = 1 # Default = Normal

# FIX: Update the path to your Label. You must ensure this path is correct
@onready var label = $CenterContainer/PanelContainer/VBoxContainer/Label

func _ready():
	load_setting()
	
func select_difficulty():
	# This function runs when a difficulty is clicked (or accepted via keyboard)
	print("Difficulty set to: " + difficulties[current_index])
	save_settings() # Save the setting when the difficulty is selected
	
	# --- SCENE LOADING LOGIC (UPDATED) ---
	var scene_path = ""
	
	if scene_path != "":
		if FileAccess.file_exists(scene_path):
			print("Loading tracks scene: " + scene_path)
			get_tree().change_scene_to_file(scene_path)
		else:
			print("Error: Tracks scene not found at: " + scene_path)

func load_setting():
	update_label()

func update_label():
	label.text = "Select Difficulty" 

func save_settings():
	var config = ConfigFile.new()
	config.set_value("game", "difficulty_index", current_index)
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Error saving settings: ", error_string(err))
