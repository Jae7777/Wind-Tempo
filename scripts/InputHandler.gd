extends Node

signal note_hit(lane_index: int, time: float)

# Key-to-lane mapping (ASDF for 4 lanes)
var key_map = {
	"a": 0,
	"s": 1,
	"d": 2,
	"f": 3
}

# Optional: MIDI support (requires Godot MIDI plugin)
var midi_enabled := false
var midi_device_id := 0

# Reference to parent's audio player for timing sync
var audio_player: AudioStreamPlayer = null
var current_song_time: float = 0.0

func _ready() -> void:
	# Try to get audio player from parent
	if get_parent().has_node("AudioPlayer"):
		audio_player = get_parent().get_node("AudioPlayer")

func _process(_delta: float) -> void:
	# Update current song time for hit detection
	if audio_player and audio_player.playing:
		current_song_time = audio_player.get_playback_position()

func _unhandled_input(event) -> void:
	"""Handle keyboard input for note hits."""
	if event is InputEventKey and event.pressed and not event.echo:
		var key = OS.get_scancode_string(event.scancode).to_lower()
		if key in key_map:
			var lane = key_map[key]
			emit_signal("note_hit", lane, current_song_time)
			get_tree().root.set_input_as_handled()

func handle_midi_input(note: int) -> void:
	"""Handle MIDI note input and map to lanes."""
	# Simple MIDI mapping: notes 48-51 map to lanes 0-3
	# (C3-E3, adjust as needed)
	if note >= 48 and note <= 51:
		var lane = note - 48
		emit_signal("note_hit", lane, current_song_time)
