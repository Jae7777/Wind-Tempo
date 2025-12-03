# scripts/components/piano_keyboard.gd
# Renders the piano keyboard overlay and handles key press visualization
class_name PianoKeyboard
extends Node2D

signal key_pressed(lane: int, midi_note: int)
signal key_released(lane: int, midi_note: int)

@export var white_key_color: Color = Color(0.95, 0.95, 0.92)
@export var black_key_color: Color = Color(0.15, 0.15, 0.18)
@export var key_pressed_color: Color = Color(0.4, 0.8, 1.0)
@export var show_note_labels: bool = true
@export var keyboard_height: float = 120.0

const MIDI_START_A0: int = 21
const LANE_COUNT: int = 88

# References
var lane_manager: LaneManager = null
var judge_y: float = 500.0

# State
var pressed_lanes: Dictionary = {}

# Keyboard controls
const KB_KEYS: Array[int] = [
	Key.KEY_A, Key.KEY_S, Key.KEY_D, Key.KEY_F, Key.KEY_G,
	Key.KEY_H, Key.KEY_J, Key.KEY_K, Key.KEY_L, Key.KEY_SEMICOLON, Key.KEY_APOSTROPHE
]
const KB_LEFT: int = Key.KEY_COMMA
const KB_RIGHT: int = Key.KEY_PERIOD
const KB_OCT_DOWN: int = Key.KEY_BRACKETLEFT
const KB_OCT_UP: int = Key.KEY_BRACKETRIGHT

var kb_base_lane: int = 0

func _ready() -> void:
	# Find lane manager in parent
	lane_manager = _find_lane_manager()
	
	# Center keyboard on middle C
	var middle_c_lane := 60 - MIDI_START_A0
	var window := KB_KEYS.size()
	kb_base_lane = clampi(middle_c_lane - window / 2, 0, maxi(0, LANE_COUNT - window))
	
	_ensure_keyboard_actions()
	_connect_midi()

func _find_lane_manager() -> LaneManager:
	var parent := get_parent()
	while parent:
		for child in parent.get_children():
			if child is LaneManager:
				return child
		parent = parent.get_parent()
	return null

func _ensure_keyboard_actions() -> void:
	for i in KB_KEYS.size():
		var act := "kb_play_%d" % i
		if not InputMap.has_action(act):
			InputMap.add_action(act)
			var ev := InputEventKey.new()
			ev.physical_keycode = KB_KEYS[i]
			ev.keycode = KB_KEYS[i]
			InputMap.action_add_event(act, ev)
	
	var nav := {
		"kb_left": KB_LEFT,
		"kb_right": KB_RIGHT,
		"kb_oct_down": KB_OCT_DOWN,
		"kb_oct_up": KB_OCT_UP
	}
	for act_name in nav.keys():
		if not InputMap.has_action(act_name):
			InputMap.add_action(act_name)
			var ev2 := InputEventKey.new()
			ev2.physical_keycode = nav[act_name]
			ev2.keycode = nav[act_name]
			InputMap.action_add_event(act_name, ev2)

func _connect_midi() -> void:
	var midi_input = get_node_or_null("/root/MidiInput")
	if midi_input:
		midi_input.note_on.connect(_on_midi_note_on)
		midi_input.note_off.connect(_on_midi_note_off)

func _process(_delta: float) -> void:
	_process_keyboard_input()

func _process_keyboard_input() -> void:
	# Navigation
	if Input.is_action_just_pressed("kb_left"):
		kb_base_lane = maxi(0, kb_base_lane - 1)
		queue_redraw()
	if Input.is_action_just_pressed("kb_right"):
		kb_base_lane = mini(LANE_COUNT - KB_KEYS.size(), kb_base_lane + 1)
		queue_redraw()
	if Input.is_action_just_pressed("kb_oct_down"):
		kb_base_lane = maxi(0, kb_base_lane - 12)
		queue_redraw()
	if Input.is_action_just_pressed("kb_oct_up"):
		kb_base_lane = mini(LANE_COUNT - KB_KEYS.size(), kb_base_lane + 12)
		queue_redraw()

	# Key presses
	var needs_redraw := false
	for i in KB_KEYS.size():
		var act := "kb_play_%d" % i
		var lane_idx := kb_base_lane + i
		if lane_idx >= 0 and lane_idx < LANE_COUNT:
			if Input.is_action_just_pressed(act):
				pressed_lanes[lane_idx] = true
				needs_redraw = true
				key_pressed.emit(lane_idx, lane_idx + MIDI_START_A0)
			elif Input.is_action_just_released(act):
				if pressed_lanes.has(lane_idx):
					pressed_lanes.erase(lane_idx)
					needs_redraw = true
					key_released.emit(lane_idx, lane_idx + MIDI_START_A0)
	
	if needs_redraw:
		queue_redraw()

func _on_midi_note_on(midi_note: int, _velocity: int, _channel: int) -> void:
	var lane: int = midi_note - MIDI_START_A0
	if lane >= 0 and lane < LANE_COUNT:
		pressed_lanes[lane] = true
		queue_redraw()
		key_pressed.emit(lane, midi_note)

func _on_midi_note_off(midi_note: int, _channel: int) -> void:
	var lane: int = midi_note - MIDI_START_A0
	if pressed_lanes.has(lane):
		pressed_lanes.erase(lane)
		queue_redraw()
		key_released.emit(lane, midi_note)

func is_lane_pressed(lane: int) -> bool:
	return pressed_lanes.has(lane)

func set_judge_line_y(y: float) -> void:
	judge_y = y
	queue_redraw()

func _draw() -> void:
	if lane_manager == null:
		return
	
	var lane_width := lane_manager.get_lane_width()
	var lane_positions := lane_manager.get_lane_positions()
	if lane_positions.is_empty():
		return
	
	var start_x: float = lane_manager.lane_margin
	var screen_height: float = get_viewport_rect().size.y
	var piano_y: float = judge_y - 10
	var piano_h: float = screen_height - piano_y
	
	# Background
	draw_rect(Rect2(start_x, piano_y, LANE_COUNT * lane_width, piano_h), Color(0.1, 0.1, 0.12), true)
	
	# White keys first
	for i in range(LANE_COUNT):
		var midi_note: int = MIDI_START_A0 + i
		if not _is_black_key(midi_note):
			var key_x: float = start_x + i * lane_width
			var key_color: Color = key_pressed_color if pressed_lanes.has(i) else white_key_color
			
			draw_rect(Rect2(key_x, piano_y, lane_width - 1, piano_h), key_color, true)
			draw_rect(Rect2(key_x, piano_y, lane_width - 1, piano_h), Color(0.3, 0.3, 0.3), false, 1.0)
			
			if show_note_labels and midi_note % 12 == 0:
				var octave: int = (midi_note / 12) - 1
				_draw_key_label(key_x + lane_width * 0.5, screen_height - 15, "C%d" % octave, Color(0.2, 0.2, 0.2))
	
	# Black keys on top
	for i in range(LANE_COUNT):
		var midi_note: int = MIDI_START_A0 + i
		if _is_black_key(midi_note):
			var key_x: float = start_x + i * lane_width
			var black_key_h: float = piano_h * 0.6
			var key_color: Color = key_pressed_color.darkened(0.3) if pressed_lanes.has(i) else black_key_color
			
			draw_rect(Rect2(key_x, piano_y, lane_width - 1, black_key_h), key_color, true)
			draw_rect(Rect2(key_x, piano_y, lane_width - 1, black_key_h), Color(0.0, 0.0, 0.0), false, 1.0)

func _draw_key_label(x: float, y: float, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x - 8, y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, color)

func _is_black_key(midi_note: int) -> bool:
	return (midi_note % 12) in [1, 3, 6, 8, 10]
