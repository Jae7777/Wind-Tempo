# NotePooler.gd
extends Node
class_name NotePooler # Add class_name for easier reference

@export var pool_size: int = 50 # Max notes to keep ready
@export var note_scene: PackedScene # Reference to Note.tscn

var note_pool: Array = []
var pool_container: Node = Node.new() # Dedicated node to hold inactive notes

func _ready():
	# Add a dedicated container node to keep the scene tree clean
	pool_container.name = "NotePoolContainer"
	add_child(pool_container)

	# Pre-instantiate the pool
	for i in range(pool_size):
		var note = note_scene.instantiate()
		# Initial setup for pooled object
		note.visible = false
		note.set_process(false) # Stop processing movement/physics when inactive
		
		pool_container.add_child(note)
		note_pool.append(note)

# Spawner calls this instead of Note.tscn.instantiate()
func get_note() -> Area2D:
	for note in note_pool:
		if not note.visible:
			# --- Activation ---
			note.visible = true
			note.set_process(true)
			# Re-add to the scene hierarchy where it's needed (e.g., as child of the spawner)
			# Must remove from pool container first!
			note.get_parent().remove_child(note) 
			get_parent().get_node("PrototypeSpawner").add_child(note) 
			
			# Note.gd should handle adding itself to the 'notes' group in _ready()
			return note
	
	# Fallback: Create a new instance if the pool is empty
	push_warning("Note pool empty! Creating new instance.")
	var new_note = note_scene.instantiate()
	note_pool.append(new_note)
	return new_note

# Note.gd calls this instead of queue_free()
# This function is the opposite of get_note()
func return_note(note_to_free: Area2D):
	# 1. Remove from its active parent (e.g., the Spawner)
	note_to_free.get_parent().remove_child(note_to_free)
	
	# 2. Add back to the pool container
	pool_container.add_child(note_to_free)

	# 3. Reset state and deactivate
	note_to_free.visible = false
	note_to_free.set_process(false)
	note_to_free.position = Vector2.ZERO # Reset position
	
	# Crucial: Remove from the tracking group
	if note_to_free.is_in_group("notes"):
		note_to_free.remove_from_group("notes")
