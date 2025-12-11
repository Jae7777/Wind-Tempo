extends Node

"""
TimingDebugger provides tools for measuring and debugging hit detection timing.
Useful for calibrating judgment windows and audio/note sync.
"""

var hit_log: Array = []
var max_log_size: int = 100

signal timing_recorded(offset: float, judgment: String)

func _ready() -> void:
	pass

func record_hit(time_offset: float, judgment: String) -> void:
	"""Record a hit for debugging/calibration."""
	hit_log.append({
		"timestamp": Time.get_ticks_msec(),
		"offset": time_offset,
		"judgment": judgment
	})
	
	# Keep log size manageable
	if hit_log.size() > max_log_size:
		hit_log.pop_front()
	
	emit_signal("timing_recorded", time_offset, judgment)

func get_average_offset() -> float:
	"""Calculate average timing offset for all recorded hits."""
	if hit_log.is_empty():
		return 0.0
	
	var sum = 0.0
	for hit in hit_log:
		sum += hit["offset"]
	
	return sum / float(hit_log.size())

func get_timing_statistics() -> Dictionary:
	"""Return timing statistics for calibration."""
	if hit_log.is_empty():
		return {}
	
	var offsets = []
	var judgments = {"Perfect": 0, "Great": 0, "Good": 0, "Miss": 0}
	
	for hit in hit_log:
		offsets.append(hit["offset"])
		if hit["judgment"] in judgments:
			judgments[hit["judgment"]] += 1
	
	offsets.sort()
	var median = offsets[offsets.size() / 2] if offsets.size() > 0 else 0.0
	
	return {
		"average_offset": get_average_offset(),
		"median_offset": median,
		"min_offset": offsets[0] if offsets.size() > 0 else 0.0,
		"max_offset": offsets[-1] if offsets.size() > 0 else 0.0,
		"judgments": judgments,
		"total_hits": hit_log.size()
	}

func print_statistics() -> void:
	"""Print timing statistics to console."""
	var stats = get_timing_statistics()
	if stats.is_empty():
		print("No timing data recorded yet.")
		return
	
	print("\n=== Timing Statistics ===")
	print("Average Offset: %.2f ms" % stats["average_offset"])
	print("Median Offset: %.2f ms" % stats["median_offset"])
	print("Range: %.2f to %.2f ms" % [stats["min_offset"], stats["max_offset"]])
	print("\nJudgment Breakdown:")
	for judgment in stats["judgments"]:
		print("  %s: %d" % [judgment, stats["judgments"][judgment]])
	print("Total Hits: %d" % stats["total_hits"])

func clear_log() -> void:
	"""Clear recorded data."""
	hit_log.clear()
