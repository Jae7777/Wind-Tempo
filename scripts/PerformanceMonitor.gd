extends Node

"""
PerformanceMonitor tracks and reports game performance metrics.
Useful for debugging and optimization.
"""

var fps_history: Array = []
var memory_history: Array = []
var max_history_size: int = 600  # 10 seconds at 60 FPS

var frame_count: int = 0
var total_time: float = 0.0
var peak_memory: int = 0

signal performance_warning(message: String)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	"""Collect performance data."""
	frame_count += 1
	total_time += delta
	
	# Record FPS
	var current_fps = Engine.get_frames_per_second()
	fps_history.append(current_fps)
	if fps_history.size() > max_history_size:
		fps_history.pop_front()
	
	# Record memory usage
	var memory = OS.get_static_memory_usage()
	memory_history.append(memory)
	peak_memory = max(peak_memory, memory)
	if memory_history.size() > max_history_size:
		memory_history.pop_front()
	
	# Warn on low FPS
	if current_fps < 30:
		emit_signal("performance_warning", "Low FPS detected: %d" % current_fps)

func get_average_fps() -> float:
	"""Get average FPS over history."""
	if fps_history.is_empty():
		return 0.0
	
	var sum = 0
	for fps in fps_history:
		sum += fps
	return float(sum) / float(fps_history.size())

func get_min_fps() -> int:
	"""Get minimum FPS in history."""
	if fps_history.is_empty():
		return 0
	return fps_history.min()

func get_max_fps() -> int:
	"""Get maximum FPS in history."""
	if fps_history.is_empty():
		return 0
	return fps_history.max()

func get_average_memory() -> int:
	"""Get average memory usage."""
	if memory_history.is_empty():
		return 0
	
	var sum = 0
	for mem in memory_history:
		sum += mem
	return sum / memory_history.size()

func get_peak_memory() -> int:
	"""Get peak memory usage."""
	return peak_memory

func get_memory_mb() -> float:
	"""Get current memory in MB."""
	return float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)

func print_stats() -> void:
	"""Print performance statistics."""
	print("\n=== Performance Stats ===")
	print("Frame Count: %d" % frame_count)
	print("Total Time: %.2f seconds" % total_time)
	print("Average FPS: %.1f" % get_average_fps())
	print("FPS Range: %d - %d" % [get_min_fps(), get_max_fps()])
	print("Memory: %.1f MB (peak: %.1f MB)" % [get_memory_mb(), float(peak_memory) / (1024.0 * 1024.0)])

func reset() -> void:
	"""Reset performance data."""
	fps_history.clear()
	memory_history.clear()
	frame_count = 0
	total_time = 0.0
	peak_memory = 0
