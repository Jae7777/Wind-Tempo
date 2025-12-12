extends Control

var difficulties = ["Easy", "Normal", "Hard"]
var current_index = 1 # Default = Normal

const MAIN_MENU_SCENE_PATH = "res://start.tscn"
const EASY_TRACKS_PATH = "res://Easy.tscn"

# FIX: Update the path to your Label. You must ensure this path is correct
@onready var label = $CenterContainer/PanelContainer/VBoxContainer/Label

func _ready():
	load_setting()
	
func _unhandled_input(event):
	# Keeping this for optional keyboard support (ui_left/ui_right are redundant for mouse clicks)
	if event.is_action_pressed("ui_left"):
		current_index = (current_index - 1 + difficulties.size()) % difficulties.size()
		update_label()
	elif event.is_action_pressed("ui_right"):
		current_index = (current_index + 1) % difficulties.size()
		update_label()
	elif event.is_action_pressed("ui_accept"):
		select_difficulty()
	
func select_difficulty():
	# This function runs when a difficulty is clicked (or accepted via keyboard)
	print("Difficulty set to: " + difficulties[current_index])
	save_settings() # Save the setting when the difficulty is selected
	
	# --- SCENE LOADING LOGIC (UPDATED) ---
	var scene_path = ""
	match current_index:
		0: # Easy
			scene_path = EASY_TRACKS_PATH
	
	if scene_path != "":
		if FileAccess.file_exists(scene_path):
			print("Loading tracks scene: " + scene_path)
			get_tree().change_scene_to_file(scene_path)
		else:
			print("Error: Tracks scene not found at: " + scene_path)

func load_setting():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		current_index = config.get_value("game", "difficulty_index", 1)
	else:
		current_index = 1
		
	update_label()

func update_label():
	label.text = "Select Difficulty" 

func save_settings():
	var config = ConfigFile.new()
	config.set_value("game", "difficulty_index", current_index)
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Error saving settings: ", error_string(err))

func _on_return_pressed() -> void:
	print("Returning to main menu.")
	if FileAccess.file_exists(MAIN_MENU_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	else:
		print("ERROR: Main menu scene not found at: ", MAIN_MENU_SCENE_PATH)


func _on_easy_pressed() -> void:
	current_index = 0 # Index 0 = "Easy"
	select_difficulty() # This calls save_settings() and loads tracks
