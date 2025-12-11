extends Node

"""
AudioSyncCalibrator measures and calibrates audio/input latency for accurate hit detection.
Provides calibration tests and offset management.
"""

var calibration_offsets: Array = []
var current_offset: float = 0.0
var is_calibrating: bool = false

signal calibration_started
signal calibration_complete(average_offset: float)
signal offset_updated(new_offset: float)

func _ready() -> void:
	pass

func start_calibration() -> void:
	"""Start latency calibration sequence."""
	is_calibrating = true
	calibration_offsets.clear()
	current_offset = 0.0
	emit_signal("calibration_started")
	print("Audio latency calibration started. Hit notes on beat for 5-10 samples.")

func record_hit_offset(offset: float) -> void:
	"""Record a hit offset during calibration."""
	if not is_calibrating:
		return
	
	calibration_offsets.append(offset)
	print("Calibration sample %d: %.2f ms" % [calibration_offsets.size(), offset])
	
	# Auto-complete after 10 samples
	if calibration_offsets.size() >= 10:
		complete_calibration()

func complete_calibration() -> void:
	"""Finish calibration and calculate average offset."""
	if not is_calibrating:
		return
	
	if calibration_offsets.is_empty():
		print("No calibration data collected")
		is_calibrating = false
		return
	
	# Calculate average offset
	var sum = 0.0
	for offset in calibration_offsets:
		sum += offset
	
	current_offset = sum / float(calibration_offsets.size())
	is_calibrating = false
	
	emit_signal("calibration_complete", current_offset)
	_print_calibration_results()

func _print_calibration_results() -> void:
	"""Print calibration results."""
	print("\n=== Calibration Results ===")
	print("Samples: %d" % calibration_offsets.size())
	print("Average Offset: %.2f ms" % current_offset)
	
	var min_offset = calibration_offsets.min()
	var max_offset = calibration_offsets.max()
	print("Range: %.2f to %.2f ms" % [min_offset, max_offset])
	print("Stability: %.2f ms" % (max_offset - min_offset))
	
	if abs(current_offset) < 20:
		print("Status: EXCELLENT (very low latency)")
	elif abs(current_offset) < 50:
		print("Status: GOOD (acceptable latency)")
	else:
		print("Status: POOR (high latency, may affect gameplay)")

func get_current_offset() -> float:
	"""Get current calibration offset."""
	return current_offset

func set_offset_manually(offset: float) -> void:
	"""Manually set offset without calibration."""
	current_offset = offset
	emit_signal("offset_updated", current_offset)
	print("Offset manually set to: %.2f ms" % current_offset)

func reset_offset() -> void:
	"""Reset offset to zero."""
	current_offset = 0.0
	calibration_offsets.clear()
	emit_signal("offset_updated", current_offset)
	print("Offset reset to 0")
