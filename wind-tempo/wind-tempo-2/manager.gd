# GameStateManager.gd
extends Node2D

@onready var music_player = $AudioStreamPlayer
@onready var spawner = $Spawner

# Function to start the game flow
func start_track():
	music_player.play()
	spawner.set_process(true) # Start spawning notes

# Handle pausing the game
func _input(event):
	if event.is_action_pressed("ui_cancel"): # Usually Esc key
		get_tree().paused = not get_tree().paused
		print("Game Paused: ", get_tree().paused)

# Check if the level is over
func _process(delta):
	if spawner.is_finished() and get_child_count() < 5: 
		# Assumes < 5 is reached when music is done and all notes are cleared/missed
		end_track()

func end_track():
	get_tree().paused = true
	print("TRACK FINISHED! Final Score: ", Point.current_score)
	# TODO: Load Results Scene
