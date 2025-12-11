extends Node

# The input action this listener is responsible for (e.g., "button_a")
@export var key_action: String

# The target Y-position for a perfect hit
@export var target_y_position: float = 500.0

# The pixel tolerance for a "perfect" and "good" hit
const PERFECT_HIT_WINDOW = 25.0 # 50px total window
const GOOD_HIT_WINDOW = 50.0    # 100px total window

func _unhandled_input(event):
	# Check if the correct button was just pressed
	if event.is_action_pressed(key_action):
		var best_key = find_hittable_key()
		
		if best_key:
			var distance = abs(best_key.global_position.y - target_y_position)
			
			if distance <= PERFECT_HIT_WINDOW:
				ScoreManager.add_hit("perfect")
				print("Perfect hit on ", key_action)
			elif distance <= GOOD_HIT_WINDOW:
				ScoreManager.add_hit("good")
				print("Good hit on ", key_action)
			else:
				# The key was hit, but outside the scoring window.
				# This could be a miss or just ignored, depending on game design.
				# For now, we'll count it as a miss to be strict.
				ScoreManager.add_miss()
				print("Hit outside window for ", key_action)

			# Remove the key that was hit
			best_key.queue_free()

# Finds the lowest falling key that matches this listener's action
func find_hittable_key():
	var best_candidate = null
	var lowest_y = -INF # Start with a very small number

	# Iterate through all children of the main scene (or a specific container node)
	for key in get_tree().get_nodes_in_group("falling_keys"):
		# Check if the key has the correct action and is lower than any other found so far
		if key.key_action == key_action and key.global_position.y > lowest_y:
			lowest_y = key.global_position.y
			best_candidate = key
			
	return best_candidate
