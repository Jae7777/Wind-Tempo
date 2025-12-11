extends Node

"""
InputDebugger helps identify and debug input mapping issues.
Logs all input events with timestamps for troubleshooting.
"""

var input_log: Array = []
var max_log_size: int = 200
var is_logging: bool = true

signal input_event_recorded(event_data: Dictionary)

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	"""Log all input events."""
	if not is_logging:
		return
	
	if event is InputEventKey and event.pressed:
		var event_data = {
			"timestamp": Time.get_ticks_msec(),
			"type": "key",
			"keycode": event.keycode,
			"key_name": OS.get_scancode_string(event.keycode),
			"pressed": event.pressed,
			"echo": event.echo
		}
		
		_record_event(event_data)
	
	elif event is InputEventMIDI:
		var event_data = {
			"timestamp": Time.get_ticks_msec(),
			"type": "midi",
			"message": event.message,
			"channel": event.channel,
			"pitch": event.pitch,
			"velocity": event.velocity
		}
		
		_record_event(event_data)

func _record_event(event_data: Dictionary) -> void:
	"""Record an input event."""
	input_log.append(event_data)
	
	if input_log.size() > max_log_size:
		input_log.pop_front()
	
	emit_signal("input_event_recorded", event_data)

func get_input_log() -> Array:
	"""Get all recorded input events."""
	return input_log.duplicate()

func get_recent_inputs(count: int = 10) -> Array:
	"""Get last N input events."""
	var start = max(0, input_log.size() - count)
	return input_log.slice(start, input_log.size())

func print_input_log() -> void:
	"""Print input log to console."""
	print("\n=== Input Debug Log ===")
	for event_data in input_log:
		match event_data["type"]:
			"key":
				print("Key: %s (echo: %s)" % [event_data["key_name"], event_data["echo"]])
			"midi":
				print("MIDI: Message=%d, Pitch=%d, Velocity=%d" % [
					event_data["message"],
					event_data["pitch"],
					event_data["velocity"]
				])

func clear_log() -> void:
	"""Clear the input log."""
	input_log.clear()
	print("Input log cleared")

func set_logging(enabled: bool) -> void:
	"""Enable or disable input logging."""
	is_logging = enabled
	print("Input logging: %s" % ("enabled" if enabled else "disabled"))
