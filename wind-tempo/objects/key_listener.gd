# In key_listener.gd

extends Sprite2D

# The template for the key to be spawned (e.g., FallingC)
@export var key_template: Sprite2D

# The input action to listen for (e.g., "button_j")
@export var key_name: String = ""

# The X-coordinate where the new key should spawn.
@export var spawn_x_position: float = 0.0

# --- NEW VARIABLE ---
# The Y-coordinate where the new key should spawn.
@export var spawn_y_position: float = -350.0


func _process(delta):
		if Input.is_action_just_pressed(key_name):
				create_falling_key()

func create_falling_key():
		if not key_template:
				print("Error: No key_template assigned to ", name)
				return

		var new_key = key_template.duplicate()
		get_parent().add_child(new_key)

		# --- UPDATED LINE ---
		# Pass BOTH the X and Y spawn positions to the Setup function.
		if new_key.has_method("Setup"):
				new_key.Setup(spawn_x_position, spawn_y_position)
		else:
				print("Error: The duplicated key is missing the Setup() function.")
				new_key.queue_free()
