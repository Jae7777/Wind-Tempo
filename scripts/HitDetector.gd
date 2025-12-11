extends Node2D

"""
HitDetector handles collision detection between input hits and falling notes.
Matches incoming input signals to notes in hit zones and returns judgments.
"""

var judgment_system: Node
var notes: Array = []
var hit_zone_y := 900.0  # Y position of hit detection zone
var lane_positions = [100, 220, 340, 460]  # X positions for 4 lanes

signal note_hit_result(judgment: String, lane: int)

func _ready() -> void:
	# Get reference to judgment system
	judgment_system = get_parent().get_node_or_null("JudgmentSystem")
	if not judgment_system:
		push_error("HitDetector: JudgmentSystem not found!")

func register_note(note: Node2D) -> void:
	"""Register a note for hit detection."""
	if note not in notes:
		notes.append(note)

func unregister_note(note: Node2D) -> void:
	"""Unregister a note when it's freed."""
	notes.erase(note)

func process_input_hit(lane: int, current_time: float) -> void:
	"""
	Process a player input for a specific lane.
	Finds the closest hittable note in that lane and judges it.
	"""
	if not judgment_system:
		return
	
	# Find all notes in the target lane that are in hit zone
	var hittable_notes = []
	for note in notes:
		if note.get_lane() == lane and not note.is_hit:
			if note.is_in_hit_zone(current_time):
				hittable_notes.append(note)
	
	# If no notes found, it's a miss
	if hittable_notes.is_empty():
		var judgment = judgment_system.judge_hit(999.0)  # Large offset = miss
		emit_signal("note_hit_result", judgment, lane)
		return
	
	# Find the closest note to the perfect hit time
	var closest_note = hittable_notes[0]
	var closest_offset = abs(closest_note.get_time_offset(current_time))
	
	for note in hittable_notes:
		var offset = abs(note.get_time_offset(current_time))
		if offset < closest_offset:
			closest_note = note
			closest_offset = offset
	
	# Judge the hit
	var time_offset = closest_note.get_time_offset(current_time)
	var judgment = judgment_system.judge_hit(time_offset)
	
	# Mark note as hit and play feedback
	closest_note.mark_as_hit()
	unregister_note(closest_note)
	
	emit_signal("note_hit_result", judgment, lane)

func _process(_delta: float) -> void:
	"""Clean up freed notes from the registry."""
	notes = notes.filter(func(note): return is_instance_valid(note))
