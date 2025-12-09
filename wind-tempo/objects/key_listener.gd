# In key_listener.gd

extends Sprite2D

# This will be our TEMPLATE. Drag the pre-placed FallingKey node (e.g., FallingC) here.
@export var key_template: Sprite2D

@export var key_name: String = ""

func _process(delta):
		if Input.is_action_just_pressed(key_name):
				create_falling_key()

func create_falling_key():
		if not key_template:
				print("Error: No key_template assigned to ", name)
				return

		# Create a new key by duplicating the template.
		# This copies all its properties, including the texture!
		var new_key = key_template.duplicate()

		# Add the new key to the scene. Adding it to the same parent as the
		# listener is a good place.
		get_parent().add_child(new_key)

	#DEBUG PRINT
		print("Listener '", name, "' is sending global_position.x: ", global_position.x)

		# Call the Setup function on the new duplicate to position it and turn it on.
		if new_key.has_method("Setup"):
				new_key.Setup(global_position.x)
		else:
				# This is a safety check in case the script is missing on the template.
				print("Error: The duplicated key is missing the Setup() function.")
				new_key.queue_free()
