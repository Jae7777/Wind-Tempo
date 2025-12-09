extends Sprite2D

@export var fall_speed: float = 200.0
# We no longer need init_y_pos here, since it's being passed in.

# ... (your _ready and _process functions remain the same) ...
func _ready():
		visible = false
		set_process(false)

func _process(delta):
		global_position.y += fall_speed * delta
		if global_position.y > get_viewport_rect().size.y + 50:
				queue_free()


# --- UPDATED FUNCTION ---
# This function now accepts both X and Y coordinates.
func Setup(target_x: float, target_y: float):
		# Set the global position using both passed-in values.
		global_position = Vector2(target_x, target_y)
		
		visible = true
		set_process(true)
