# In white_falling_key.gd

extends Sprite2D

@export var fall_speed: float = 200.0
@export var init_y_pos: float = -350.0

func _ready():
		# Make the original template nodes invisible and stop them from processing.
		# The copies we make will be made visible manually.
		visible = false
		set_process(false)

func _process(delta):
	
		# Move the key down
		global_position.y += fall_speed * delta
		
		# Clean up the key when it goes off-screen
		if global_position.y > get_viewport_rect().size.y + 50:
				queue_free()

# This function will be called on the NEWLY CREATED key
func Setup(target_x: float):
		# Let's see what X-position we received and where we are moving.
		print("New key received target_x: ", target_x, ". Setting global_position.")
		global_position = Vector2(target_x, init_y_pos)
		# Make the new copy visible and start its movement
		visible = true
		set_process(true)
