# scripts/MidiInput.gd
# Autoload singleton for handling MIDI keyboard input
extends Node

# Emitted when a MIDI note is pressed
signal note_on(note: int, velocity: int, channel: int)
# Emitted when a MIDI note is released
signal note_off(note: int, channel: int)
# Emitted when MIDI devices change
signal devices_changed(devices: PackedStringArray)

# MIDI message types (Godot 4 uses MIDIMessage enum values)
const MIDI_NOTE_OFF: int = MIDI_MESSAGE_NOTE_OFF
const MIDI_NOTE_ON: int = MIDI_MESSAGE_NOTE_ON
const MIDI_CONTROL_CHANGE: int = MIDI_MESSAGE_CONTROL_CHANGE

# Currently connected MIDI devices
var available_devices: PackedStringArray = []
var is_midi_enabled: bool = false

# Track currently held notes (for sustain visualization)
var held_notes: Dictionary = {}

func _ready() -> void:
	refresh_midi_devices()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		refresh_midi_devices()

func refresh_midi_devices() -> void:
	"""Scan for connected MIDI devices and open inputs"""
	OS.close_midi_inputs()
	OS.open_midi_inputs()
	available_devices = OS.get_connected_midi_inputs()
	is_midi_enabled = available_devices.size() > 0
	
	if is_midi_enabled:
		print("[MidiInput] Found %d MIDI device(s):" % available_devices.size())
		for i in range(available_devices.size()):
			print("  [%d] %s" % [i, available_devices[i]])
	else:
		print("[MidiInput] No MIDI devices found")
	
	devices_changed.emit(available_devices)

func _input(event: InputEvent) -> void:
	if event is InputEventMIDI:
		_handle_midi_event(event as InputEventMIDI)

func _handle_midi_event(midi: InputEventMIDI) -> void:
	var channel: int = midi.channel
	var message: int = midi.message
	var pitch: int = midi.pitch
	var velocity: int = midi.velocity
	
	match message:
		MIDI_NOTE_ON:
			if velocity > 0:
				held_notes[pitch] = velocity
				note_on.emit(pitch, velocity, channel)
			else:
				# Note On with velocity 0 = Note Off
				held_notes.erase(pitch)
				note_off.emit(pitch, channel)
		
		MIDI_NOTE_OFF:
			held_notes.erase(pitch)
			note_off.emit(pitch, channel)
		
		MIDI_CONTROL_CHANGE:
			# Handle sustain pedal (CC 64)
			if midi.controller_number == 64:
				if midi.controller_value < 64:
					pass  # Pedal released

func get_note_name(midi_note: int) -> String:
	"""Get the note name (e.g., 'C4', 'F#5') from MIDI note number"""
	const NOTE_NAMES: Array[String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var note_idx: int = midi_note % 12
	var octave: int = (midi_note / 12) - 1
	return "%s%d" % [NOTE_NAMES[note_idx], octave]
