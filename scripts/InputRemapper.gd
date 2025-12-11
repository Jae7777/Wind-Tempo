extends Node

"""
InputRemapper allows players to customize keyboard and MIDI bindings.
Provides persistence via ConfigFile and real-time binding updates.
"""

const CONFIG_PATH = "user://input_remapper.cfg"

@onready var config = ConfigFile.new()

# Default key bindings
var default_bindings = {
	"lane_0": KEY_A,      # Left lane
	"lane_1": KEY_S,      # Left-middle lane
	"lane_2": KEY_D,      # Right-middle lane
	"lane_3": KEY_F,      # Right lane
	"pause": KEY_ESCAPE,
	"restart": KEY_R
}

# Current active bindings
var current_bindings: Dictionary = {}

# MIDI note mappings (0-127 MIDI notes to lanes)
var midi_bindings = {
	60: 0,  # Middle C -> Lane 0
	62: 1,  # D -> Lane 1
	64: 2,  # E -> Lane 2
	65: 3   # F -> Lane 3
}

signal binding_changed(action: String, new_key: int)
signal bindings_reset
signal remapping_started(action: String)
signal remapping_cancelled

var is_remapping: bool = false
var remapping_action: String = ""

func _ready() -> void:
	"""Load bindings from config file."""
	_load_bindings()

func _load_bindings() -> void:
	"""Load saved bindings or use defaults."""
	var error = config.load(CONFIG_PATH)
	
	current_bindings = default_bindings.duplicate()
	
	if error == OK:
		for action in default_bindings.keys():
			if config.has_section_key("bindings", action):
				current_bindings[action] = config.get_value("bindings", action)
		
		if config.has_section("midi_bindings"):
			midi_bindings.clear()
			for key in config.get_section_keys("midi_bindings"):
				midi_bindings[int(key)] = config.get_value("midi_bindings", key)

func _save_bindings() -> void:
	"""Save current bindings to config file."""
	config.clear()
	
	config.set_value("bindings", "lane_0", current_bindings["lane_0"])
	config.set_value("bindings", "lane_1", current_bindings["lane_1"])
	config.set_value("bindings", "lane_2", current_bindings["lane_2"])
	config.set_value("bindings", "lane_3", current_bindings["lane_3"])
	config.set_value("bindings", "pause", current_bindings["pause"])
	config.set_value("bindings", "restart", current_bindings["restart"])
	
	for midi_note in midi_bindings.keys():
		config.set_value("midi_bindings", str(midi_note), midi_bindings[midi_note])
	
	config.save(CONFIG_PATH)

func start_remapping(action: String) -> void:
	"""Begin remapping an action."""
	if action not in current_bindings:
		push_error("Invalid action: %s" % action)
		return
	
	is_remapping = true
	remapping_action = action
	emit_signal("remapping_started", action)

func cancel_remapping() -> void:
	"""Cancel ongoing remapping."""
	is_remapping = false
	remapping_action = ""
	emit_signal("remapping_cancelled")

func handle_remapped_key(key: int) -> void:
	"""Process a key press during remapping."""
	if not is_remapping or remapping_action.is_empty():
		return
	
	# Don't allow remapping escape as anything other than pause
	if key == KEY_ESCAPE and remapping_action != "pause":
		cancel_remapping()
		return
	
	# Check for conflicts with other bindings
	for action in current_bindings:
		if action != remapping_action and current_bindings[action] == key:
			push_warning("Key already bound to action: %s" % action)
			return
	
	# Update binding
	current_bindings[remapping_action] = key
	emit_signal("binding_changed", remapping_action, key)
	_save_bindings()
	
	is_remapping = false
	remapping_action = ""

func set_midi_binding(midi_note: int, lane: int) -> void:
	"""Set MIDI note to lane mapping."""
	if lane < 0 or lane > 3:
		push_error("Invalid lane: %d" % lane)
		return
	
	midi_bindings[midi_note] = lane
	_save_bindings()
	emit_signal("binding_changed", "midi_%d" % midi_note, lane)

func remove_midi_binding(midi_note: int) -> void:
	"""Remove MIDI note binding."""
	if midi_note in midi_bindings:
		midi_bindings.erase(midi_note)
		_save_bindings()

func get_binding(action: String) -> int:
	"""Get current key binding for an action."""
	if action in current_bindings:
		return current_bindings[action]
	return -1

func get_action_name(key: int) -> String:
	"""Get action name for a key (for display)."""
	for action in current_bindings:
		if current_bindings[action] == key:
			return action
	return "Unbound"

func get_key_name(key: int) -> String:
	"""Get human-readable name for a key code."""
	return OS.get_keycode_string(key)

func reset_to_defaults() -> void:
	"""Reset all bindings to defaults."""
	current_bindings = default_bindings.duplicate()
	midi_bindings = {
		60: 0,
		62: 1,
		64: 2,
		65: 3
	}
	_save_bindings()
	emit_signal("bindings_reset")

func get_all_bindings() -> Dictionary:
	"""Return a copy of all current bindings."""
	return current_bindings.duplicate()

func get_midi_bindings() -> Dictionary:
	"""Return a copy of all MIDI bindings."""
	return midi_bindings.duplicate()

func is_action_pressed(action: String) -> bool:
	"""Check if an action key is currently pressed."""
	if action not in current_bindings:
		return false
	return Input.is_key_pressed(current_bindings[action])
