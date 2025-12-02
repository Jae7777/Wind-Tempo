# scripts/MidiParser.gd
# Parses standard MIDI files (.mid) into game chart data
class_name MidiParser
extends RefCounted

# Parsed note data structure
class NoteEvent:
	var time_seconds: float  # When the note should be hit
	var midi_note: int       # MIDI note number (21-108 for piano)
	var duration: float      # How long the note is held
	var velocity: int        # How hard the note was pressed (1-127)
	var lane: int            # Converted lane index (0-87)
	
	func _to_string() -> String:
		return "Note(%d, time=%.2fs, dur=%.2fs)" % [midi_note, time_seconds, duration]

# Chart data containing all parsed notes
class ChartData:
	var title: String = "Unknown"
	var artist: String = "Unknown"
	var tempo_bpm: float = 120.0
	var duration_seconds: float = 0.0
	var notes: Array[NoteEvent] = []
	var time_signature_num: int = 4
	var time_signature_den: int = 4
	
	func get_note_count() -> int:
		return notes.size()

# MIDI parsing constants
const MIDI_MIN_NOTE: int = 21
const MIDI_MAX_NOTE: int = 108

# Parse a MIDI file and return ChartData
static func parse_file(path: String) -> ChartData:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MidiParser: Cannot open file: %s" % path)
		return null
	
	var bytes := file.get_buffer(file.get_length())
	file.close()
	
	return parse_bytes(bytes, path.get_file().get_basename())

# Parse MIDI data from a byte array
static func parse_bytes(bytes: PackedByteArray, title: String = "Unknown") -> ChartData:
	var chart := ChartData.new()
	chart.title = title
	
	var pos: int = 0
	
	# Verify MIDI header "MThd"
	if bytes.size() < 14:
		push_error("MidiParser: File too small to be valid MIDI")
		return null
	
	var header := bytes.slice(0, 4).get_string_from_ascii()
	if header != "MThd":
		push_error("MidiParser: Invalid MIDI header")
		return null
	
	pos = 4
	
	# Header length (always 6)
	var header_len := _read_uint32(bytes, pos)
	pos += 4
	
	# Format type (0, 1, or 2)
	var format_type := _read_uint16(bytes, pos)
	pos += 2
	
	# Number of tracks
	var num_tracks := _read_uint16(bytes, pos)
	pos += 2
	
	# Time division (ticks per quarter note or SMPTE)
	var time_division := _read_uint16(bytes, pos)
	pos += 2
	
	var ticks_per_beat: int = time_division
	if time_division & 0x8000:
		# SMPTE timing - convert to approximate ticks per beat
		var fps := -(time_division >> 8)
		var ticks_per_frame := time_division & 0xFF
		ticks_per_beat = fps * ticks_per_frame
	
	# Default tempo (microseconds per beat)
	var tempo_us: float = 500000.0  # 120 BPM default
	
	# Track active notes for duration calculation
	var active_notes: Dictionary = {}  # {(note, channel): {start_tick, velocity}}
	var all_events: Array = []  # Collect all note events with tick times
	
	# Parse each track
	for track_idx in range(num_tracks):
		if pos >= bytes.size():
			break
		
		# Verify track header "MTrk"
		var track_header := bytes.slice(pos, pos + 4).get_string_from_ascii()
		if track_header != "MTrk":
			push_warning("MidiParser: Expected MTrk at position %d" % pos)
			break
		pos += 4
		
		# Track length
		var track_len := _read_uint32(bytes, pos)
		pos += 4
		
		var track_end: int = pos + track_len
		var running_status: int = 0
		var current_tick: int = 0
		
		# Parse track events
		while pos < track_end and pos < bytes.size():
			# Read delta time (variable length)
			var delta_result := _read_variable_length(bytes, pos)
			var delta_time: int = delta_result[0]
			pos = delta_result[1]
			current_tick += delta_time
			
			if pos >= bytes.size():
				break
			
			var status := bytes[pos]
			
			# Check for running status
			if status < 0x80:
				# Use running status
				status = running_status
			else:
				pos += 1
				if status < 0xF0:
					running_status = status
			
			var message_type := status & 0xF0
			var channel := status & 0x0F
			
			match message_type:
				0x80:  # Note Off
					if pos + 1 < bytes.size():
						var note := bytes[pos]
						var velocity := bytes[pos + 1]
						pos += 2
						
						var key := "%d_%d" % [note, channel]
						if active_notes.has(key):
							var start_data: Dictionary = active_notes[key]
							all_events.append({
								"note": note,
								"start_tick": start_data["start_tick"],
								"end_tick": current_tick,
								"velocity": start_data["velocity"],
								"channel": channel
							})
							active_notes.erase(key)
				
				0x90:  # Note On
					if pos + 1 < bytes.size():
						var note := bytes[pos]
						var velocity := bytes[pos + 1]
						pos += 2
						
						var key := "%d_%d" % [note, channel]
						if velocity > 0:
							# Note On
							active_notes[key] = {
								"start_tick": current_tick,
								"velocity": velocity
							}
						else:
							# Note On with velocity 0 = Note Off
							if active_notes.has(key):
								var start_data: Dictionary = active_notes[key]
								all_events.append({
									"note": note,
									"start_tick": start_data["start_tick"],
									"end_tick": current_tick,
									"velocity": start_data["velocity"],
									"channel": channel
								})
								active_notes.erase(key)
				
				0xA0:  # Polyphonic Aftertouch
					pos += 2
				
				0xB0:  # Control Change
					pos += 2
				
				0xC0:  # Program Change
					pos += 1
				
				0xD0:  # Channel Aftertouch
					pos += 1
				
				0xE0:  # Pitch Bend
					pos += 2
				
				0xF0:  # System messages
					if status == 0xFF:  # Meta event
						if pos + 1 < bytes.size():
							var meta_type := bytes[pos]
							pos += 1
							var len_result := _read_variable_length(bytes, pos)
							var meta_len: int = len_result[0]
							pos = len_result[1]
							
							match meta_type:
								0x03:  # Track name
									if pos + meta_len <= bytes.size():
										chart.title = bytes.slice(pos, pos + meta_len).get_string_from_utf8()
								0x51:  # Tempo
									if meta_len >= 3 and pos + 2 < bytes.size():
										tempo_us = float((bytes[pos] << 16) | (bytes[pos + 1] << 8) | bytes[pos + 2])
								0x58:  # Time signature
									if meta_len >= 4 and pos + 3 < bytes.size():
										chart.time_signature_num = bytes[pos]
										chart.time_signature_den = 1 << bytes[pos + 1]
							
							pos += meta_len
					elif status == 0xF0 or status == 0xF7:  # SysEx
						var len_result := _read_variable_length(bytes, pos)
						pos = len_result[1] + len_result[0]
	
	# Calculate tempo
	chart.tempo_bpm = 60000000.0 / tempo_us
	
	# Convert ticks to seconds and create NoteEvents
	var seconds_per_tick: float = (tempo_us / 1000000.0) / float(ticks_per_beat)
	
	for event_data in all_events:
		var note := event_data["note"] as int
		
		# Filter to piano range
		if note < MIDI_MIN_NOTE or note > MIDI_MAX_NOTE:
			continue
		
		var note_event := NoteEvent.new()
		note_event.midi_note = note
		note_event.time_seconds = float(event_data["start_tick"]) * seconds_per_tick
		note_event.duration = float(event_data["end_tick"] - event_data["start_tick"]) * seconds_per_tick
		note_event.velocity = event_data["velocity"]
		note_event.lane = note - MIDI_MIN_NOTE
		
		chart.notes.append(note_event)
		
		var end_time: float = note_event.time_seconds + note_event.duration
		if end_time > chart.duration_seconds:
			chart.duration_seconds = end_time
	
	# Sort notes by time
	chart.notes.sort_custom(func(a: NoteEvent, b: NoteEvent) -> bool:
		return a.time_seconds < b.time_seconds
	)
	
	print("MidiParser: Loaded '%s' - %d notes, %.1f BPM, %.1fs duration" % [
		chart.title, chart.notes.size(), chart.tempo_bpm, chart.duration_seconds
	])
	
	return chart

# Read a big-endian 32-bit unsigned integer
static func _read_uint32(bytes: PackedByteArray, pos: int) -> int:
	if pos + 3 >= bytes.size():
		return 0
	return (bytes[pos] << 24) | (bytes[pos + 1] << 16) | (bytes[pos + 2] << 8) | bytes[pos + 3]

# Read a big-endian 16-bit unsigned integer
static func _read_uint16(bytes: PackedByteArray, pos: int) -> int:
	if pos + 1 >= bytes.size():
		return 0
	return (bytes[pos] << 8) | bytes[pos + 1]

# Read a MIDI variable-length quantity
static func _read_variable_length(bytes: PackedByteArray, pos: int) -> Array:
	var value: int = 0
	var byte: int = 0
	
	while pos < bytes.size():
		byte = bytes[pos]
		pos += 1
		value = (value << 7) | (byte & 0x7F)
		if (byte & 0x80) == 0:
			break
	
	return [value, pos]

