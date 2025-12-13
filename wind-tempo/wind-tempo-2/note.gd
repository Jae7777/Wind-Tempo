# PrototypeSpawner.gd
extends Node2D 

# =======================================================
# 1. CONSTANTS AND PRELOADS
# =======================================================

# 🛑 IMPORTANT: Replace this with the actual path to your Note scene
const NOTE_SCENE = preload("res://note.tscn") 

# Lane X-positions: Defines where the notes appear horizontally
# (Adjust these to match your visual lanes)
const LANE_POSITIONS: Array = [100, 300, 500, 700] # Example for four lanes

# NOTE MAP: Simple list of spawn times in seconds, one note every 0.5s for 4 seconds
# The index of the time in this list will also be the lane index (0, 1, 2, 3, 0, 1, ...)
const SPAWN_TIMES: Array = [
	0.5, 1.0, 1.5, 2.0, 
	2.5, 3.0, 3.5, 4.0, 
	4.5, 5.0, 5.5, 6.0
]

var spawn_timer: float = 0.0 # Tracks the total time the scene has been running
var next_note_index: int = 0 # Index of the next note time in the SPAWN_TIMES array

func _process(delta):
	# 1. Update the running time
	spawn_timer += delta
	
	# 2. Check if we have notes left to spawn
	if next_note_index < SPAWN_TIMES.size():
		var spawn_time_required = SPAWN_TIMES[next_note_index]
		
		# 3. Decision: Has the elapsed time reached the required spawn time?
		if spawn_timer >= spawn_time_required:
			
			# Determine the lane to use: Cycle through lanes 0, 1, 2, 3
			var lane_index = next_note_index % LANE_POSITIONS.size()
			
			# Time to spawn!
			spawn_note(lane_index)
			
			# Move to the next note in the list
			next_note_index += 1
			
	elif spawn_timer > SPAWN_TIMES[SPAWN_TIMES.size() - 1] + 2.0:
		# Optional: Stop testing after the last note has spawned and 2 seconds have passed
		print("Spawn Test Finished.")
		set_process(false) # Stop calling _process()

func spawn_note(lane_index: int):
	# 1. Instantiate the note scene
	var new_note = NOTE_SCENE.instantiate()
	
	# 2. Determine the horizontal position
	var spawn_x = LANE_POSITIONS[lane_index]
	
	# 3. Set the note's initial position (Y=0 is typically the top/off-screen)
	new_note.position = Vector2(spawn_x, 0)
	
	# 4. Add the note to the scene tree
	add_child(new_note)
	
	print("Spawned Note #%d in Lane %d at time %.2f" % [next_note_index + 1, lane_index, spawn_timer])
