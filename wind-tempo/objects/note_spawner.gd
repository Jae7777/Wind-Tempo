extends Node

# The scene for the falling key
@export var falling_key_scene: PackedScene

# The different keys/buttons the player needs to press
@export var available_actions: Array[String] = ["button_a", "button_s", "button_d", "button_f"]

# The X-coordinates for each of the four columns where notes can fall
@export var column_positions: Array[float] = [100.0, 200.0, 300.0, 400.0]

# How often to spawn a new key (in seconds)
@export var spawn_interval: float = 1.0

# The Y-coordinate where keys will start
const SPAWN_Y = -50.0

func _ready():
	# A timer to control how often notes are spawned
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.connect("timeout", self._on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	if not falling_key_scene:
		print("Error: Falling key scene is not set in the spawner.")
		return

	# Choose a random column/action
	var random_index = randi() % available_actions.size()
	var action = available_actions[random_index]
	var x_pos = column_positions[random_index]

	# Create a new falling key
	var new_key = falling_key_scene.instantiate()
	
	# Set its starting position and the action required to hit it
	if new_key.has_method("setup"):
		new_key.setup(Vector2(x_pos, SPAWN_Y), action)
		get_parent().add_child(new_key)
	else:
		print("Error: The falling key scene is missing the 'setup' method.")
		new_key.queue_free()
