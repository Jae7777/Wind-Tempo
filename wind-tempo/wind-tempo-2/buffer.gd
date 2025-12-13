# InputBuffer.gd
extends Node

const EARLY_HIT_BUFFER: float = 0.05 # 50 milliseconds
var buffered_inputs: Dictionary = {} # Stores {lane_index: time_of_press}

# Called by HitDetector when key is pressed, *before* checking overlap
func buffer_press(lane_index: int):
	# Store the time the button was pressed
	buffered_inputs[lane_index] = Time.get_ticks_msec()

# Called by HitDetector/Note.gd when a note enters the buffer window
func check_early_hit(note_instance: Area2D, lane_index: int) -> bool:
	if buffered_inputs.has(lane_index):
		var time_pressed = buffered_inputs[lane_index]
		var time_now = Time.get_ticks_msec()
		
		# Check if press occurred within the buffer window
		if time_now - time_pressed <= EARLY_HIT_BUFFER * 1000:
			# Early hit confirmed! Process as a PERFECT hit.
			buffered_inputs.erase(lane_index)
			return true
			
	return false

# NOTE: Requires coordinating with the HitDetector and Note scripts.
