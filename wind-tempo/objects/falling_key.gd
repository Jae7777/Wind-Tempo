extends Sprite2D

@export var fall_speed: float = 200.0
var key_action: String = "" # To store which key this falling note corresponds to (e.g., "button_a")

func _process(delta):
		position.y += fall_speed * delta
		
		# Disappear when it goes off-screen
		if position.y > get_viewport_rect().size.y + 100:
				# It was missed
				ScoreManager.add_miss()
				queue_free()

func _ready():
	add_to_group("falling_keys")

# --- NEW FUNCTION ---
# Sets the key's starting position and the action required to hit it.
func setup(start_pos: Vector2, action: String):
		global_position = start_pos
		key_action = action
