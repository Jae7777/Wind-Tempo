# PrototypeSpawner.gd
extends Node2D

const NOTE_SCENE = preload("res://Note.tscn")

# Lane X-positions: Defines where the notes appear horizontally
# (Adjust these to match your visual lanes)
const LANE_POSITIONS: Array = [100, 300, 500, 700] # Example for four lanes

func spawn_note(lane_index: int):
	# 1. Instantiate the note scene
	var new_note = NOTE_SCENE.instantiate()

	# 2. Determine the horizontal position
	var spawn_x = LANE_POSITIONS[lane_index]

	# 3. Set the note's initial position (Y=0 is typically the top/off-screen)
	new_note.position = Vector2(spawn_x, 0)

	# 4. Add the note to the scene tree
	add_child(new_note)
