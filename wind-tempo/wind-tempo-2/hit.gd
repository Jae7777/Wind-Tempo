# HitDetector.gd
extends Node

const LANE_ACTIONS: Array = ["lane_0", "lane_1", "lane_2", "lane_3"]

# Array to hold references to the four HitZone Area2D nodes
var hit_zones: Array = [] 

# --- ACCURACY CONSTANTS ---
# Define the tolerance (distance in pixels) for each hit quality
const PERFECT_TOLERANCE: float = 10.0 # ±10 pixels from center
const GREAT_TOLERANCE: float = 30.0   # ±30 pixels from center
const OK_TOLERANCE: float = 60.0      # ±60 pixels from center

# NOTE: You MUST set this to the exact Y position of the center of your HitZone collision shape
const IDEAL_HIT_Y_POS: float = 900.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Attempt to find the HitZone nodes placed in the parent TrackScene
	for i in range(LANE_ACTIONS.size()):
		var hit_zone_node = get_parent().get_node_or_null("HitZone_" + str(i))
		if hit_zone_node:
			hit_zones.append(hit_zone_node)
		else:
			push_error("Missing HitZone node: HitZone_" + str(i) + ". Please check your scene tree.")

func _unhandled_input(event):
	
	# Iterate through all four lane actions to check which key was pressed
	for i in range(LANE_ACTIONS.size()):
		var action_name = LANE_ACTIONS[i]
		
		if event.is_action_pressed(action_name):
			check_for_hit(i)
			get_viewport().set_input_as_handled() 
			return

func check_for_hit(lane_index: int):
	
	if lane_index >= hit_zones.size() or not is_instance_valid(hit_zones[lane_index]):
		return

	var hit_zone = hit_zones[lane_index]
	
	# Get all Area2D nodes (notes) currently overlapping the HitZone
	var overlapping_notes: Array[Area2D] = hit_zone.get_overlapping_areas()
	
	if overlapping_notes.size() > 0:
		# --- HIT SUCCESSFUL! ---
		
		var hit_note: Area2D = overlapping_notes[0]
		
		# 1. Determine hit accuracy
		var hit_quality = calculate_accuracy(hit_note.position.y)
		
		# 2. Register hit and score based on quality
		if has_node("/root/Point"):
			Point.register_successful_hit(hit_quality) # Assumes Point.gd is updated
		
		print("HIT! Lane %d - Quality: %s" % [lane_index, hit_quality])
		
		# 3. Remove the note
		hit_note.queue_free()
		
	else:
		# --- HIT MISSED (Empty Press) ---
		
		if has_node("/root/Point"):
			Point.register_miss()
			
		print("Empty press in lane %d. Combo Broken." % lane_index)

func calculate_accuracy(note_y_pos: float) -> String:
	
	# Calculate the absolute distance from the note to the ideal hit position
	var distance = abs(note_y_pos - IDEAL_HIT_Y_POS)
	
	if distance <= PERFECT_TOLERANCE:
		return "PERFECT"
	elif distance <= GREAT_TOLERANCE:
		return "GREAT"
	elif distance <= OK_TOLERANCE:
		return "OK"
	else:
		# This case should ideally not happen if the HitZone collision is properly set 
		# to match the max tolerance, but serves as a fail-safe.
		return "BAD"
