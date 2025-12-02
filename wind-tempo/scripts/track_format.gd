# scripts/TrackFormat.gd
# Wind Tempo Track Format (.wtrack) - JSON-based custom format
# This defines the structure and provides parsing/saving for user-created tracks
class_name TrackFormat
extends RefCounted

# ============================================================
# WIND TEMPO TRACK FORMAT (.wtrack) SPECIFICATION
# ============================================================
# 
# File extension: .wtrack
# Encoding: UTF-8 JSON
# 
# Structure:
# {
#   "format_version": 1,
#   "metadata": {
#     "title": "Song Title",
#     "artist": "Artist Name",
#     "creator": "Track Creator",
#     "difficulty": "Normal",  // Easy, Normal, Hard, Expert
#     "description": "Optional description",
#     "created_at": "2024-01-01T00:00:00Z",
#     "modified_at": "2024-01-01T00:00:00Z"
#   },
#   "settings": {
#     "bpm": 120.0,
#     "time_signature": [4, 4],
#     "audio_file": "optional_audio.ogg",
#     "audio_offset": 0.0,
#     "preview_start": 30.0
#   },
#   "notes": [
#     {
#       "time": 0.0,        // Time in seconds
#       "note": 60,         // MIDI note number (21-108 for piano)
#       "duration": 0.5,    // Duration in seconds (for held notes)
#       "velocity": 100     // 1-127
#     }
#   ],
#   "events": [
#     {
#       "time": 10.0,
#       "type": "bpm_change",
#       "value": 140.0
#     }
#   ]
# }
# ============================================================

const FORMAT_VERSION: int = 1

# Track metadata
class TrackMetadata:
	var title: String = "Untitled Track"
	var artist: String = "Unknown"
	var creator: String = ""
	var difficulty: String = "Normal"
	var description: String = ""
	var created_at: String = ""
	var modified_at: String = ""
	
	func to_dict() -> Dictionary:
		return {
			"title": title,
			"artist": artist,
			"creator": creator,
			"difficulty": difficulty,
			"description": description,
			"created_at": created_at,
			"modified_at": modified_at
		}
	
	static func from_dict(data: Dictionary) -> TrackMetadata:
		var meta := TrackMetadata.new()
		meta.title = data.get("title", "Untitled Track")
		meta.artist = data.get("artist", "Unknown")
		meta.creator = data.get("creator", "")
		meta.difficulty = data.get("difficulty", "Normal")
		meta.description = data.get("description", "")
		meta.created_at = data.get("created_at", "")
		meta.modified_at = data.get("modified_at", "")
		return meta

# Track settings
class TrackSettings:
	var bpm: float = 120.0
	var time_signature: Array[int] = [4, 4]
	var audio_file: String = ""
	var audio_offset: float = 0.0
	var preview_start: float = 0.0
	
	func to_dict() -> Dictionary:
		return {
			"bpm": bpm,
			"time_signature": time_signature,
			"audio_file": audio_file,
			"audio_offset": audio_offset,
			"preview_start": preview_start
		}
	
	static func from_dict(data: Dictionary) -> TrackSettings:
		var settings := TrackSettings.new()
		settings.bpm = data.get("bpm", 120.0)
		var ts = data.get("time_signature", [4, 4])
		if ts is Array and ts.size() >= 2:
			settings.time_signature = [int(ts[0]), int(ts[1])]
		settings.audio_file = data.get("audio_file", "")
		settings.audio_offset = data.get("audio_offset", 0.0)
		settings.preview_start = data.get("preview_start", 0.0)
		return settings

# Single note in the track
class TrackNote:
	var time: float = 0.0        # Time in seconds
	var note: int = 60           # MIDI note (21-108)
	var duration: float = 0.0    # Duration in seconds (0 = tap note)
	var velocity: int = 100      # Velocity 1-127
	
	func to_dict() -> Dictionary:
		var d := {
			"time": time,
			"note": note,
			"velocity": velocity
		}
		if duration > 0:
			d["duration"] = duration
		return d
	
	static func from_dict(data: Dictionary) -> TrackNote:
		var n := TrackNote.new()
		n.time = data.get("time", 0.0)
		n.note = data.get("note", 60)
		n.duration = data.get("duration", 0.0)
		n.velocity = data.get("velocity", 100)
		return n
	
	func get_lane() -> int:
		return note - 21  # A0 = MIDI 21 = lane 0

# Track event (BPM changes, etc.)
class TrackEvent:
	var time: float = 0.0
	var type: String = ""
	var value: Variant = null
	
	func to_dict() -> Dictionary:
		return {
			"time": time,
			"type": type,
			"value": value
		}
	
	static func from_dict(data: Dictionary) -> TrackEvent:
		var e := TrackEvent.new()
		e.time = data.get("time", 0.0)
		e.type = data.get("type", "")
		e.value = data.get("value", null)
		return e

# Complete track data
class Track:
	var format_version: int = FORMAT_VERSION
	var metadata: TrackMetadata = TrackMetadata.new()
	var settings: TrackSettings = TrackSettings.new()
	var notes: Array[TrackNote] = []
	var events: Array[TrackEvent] = []
	var file_path: String = ""  # Path where this track is saved
	
	func get_duration() -> float:
		var max_time: float = 0.0
		for n in notes:
			var end_time: float = n.time + n.duration
			if end_time > max_time:
				max_time = end_time
		return max_time
	
	func get_note_count() -> int:
		return notes.size()
	
	func sort_notes() -> void:
		notes.sort_custom(func(a: TrackNote, b: TrackNote) -> bool:
			return a.time < b.time
		)
	
	func add_note(time: float, midi_note: int, duration: float = 0.0, velocity: int = 100) -> TrackNote:
		var n := TrackNote.new()
		n.time = time
		n.note = clampi(midi_note, 21, 108)
		n.duration = maxf(0.0, duration)
		n.velocity = clampi(velocity, 1, 127)
		notes.append(n)
		return n
	
	func remove_note(note: TrackNote) -> void:
		var idx := notes.find(note)
		if idx >= 0:
			notes.remove_at(idx)
	
	func to_dict() -> Dictionary:
		var notes_array := []
		for n in notes:
			notes_array.append(n.to_dict())
		
		var events_array := []
		for e in events:
			events_array.append(e.to_dict())
		
		return {
			"format_version": format_version,
			"metadata": metadata.to_dict(),
			"settings": settings.to_dict(),
			"notes": notes_array,
			"events": events_array
		}
	
	static func from_dict(data: Dictionary) -> Track:
		var track := Track.new()
		track.format_version = data.get("format_version", FORMAT_VERSION)
		
		if data.has("metadata"):
			track.metadata = TrackMetadata.from_dict(data["metadata"])
		if data.has("settings"):
			track.settings = TrackSettings.from_dict(data["settings"])
		
		if data.has("notes") and data["notes"] is Array:
			for note_data in data["notes"]:
				track.notes.append(TrackNote.from_dict(note_data))
		
		if data.has("events") and data["events"] is Array:
			for event_data in data["events"]:
				track.events.append(TrackEvent.from_dict(event_data))
		
		return track
	
	func to_chart_data() -> MidiParser.ChartData:
		"""Convert to ChartData for gameplay"""
		var chart := MidiParser.ChartData.new()
		chart.title = metadata.title
		chart.artist = metadata.artist
		chart.tempo_bpm = settings.bpm
		chart.time_signature_num = settings.time_signature[0]
		chart.time_signature_den = settings.time_signature[1]
		chart.duration_seconds = get_duration()
		
		for n in notes:
			var note_event := MidiParser.NoteEvent.new()
			note_event.time_seconds = n.time
			note_event.midi_note = n.note
			note_event.duration = n.duration
			note_event.velocity = n.velocity
			note_event.lane = n.get_lane()
			chart.notes.append(note_event)
		
		return chart

# ============================================================
# STATIC UTILITY FUNCTIONS
# ============================================================

static func save_track(track: Track, path: String) -> Error:
	"""Save a track to a .wtrack file"""
	# Update modified timestamp
	track.metadata.modified_at = Time.get_datetime_string_from_system(true)
	if track.metadata.created_at == "":
		track.metadata.created_at = track.metadata.modified_at
	
	# Sort notes before saving
	track.sort_notes()
	
	# Convert to JSON
	var json_string := JSON.stringify(track.to_dict(), "\t")
	
	# Write to file
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	
	file.store_string(json_string)
	file.close()
	
	track.file_path = path
	print("TrackFormat: Saved track to %s" % path)
	return OK

static func load_track(path: String) -> Track:
	"""Load a track from a .wtrack file"""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TrackFormat: Cannot open file: %s" % path)
		return null
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("TrackFormat: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("TrackFormat: Invalid track format")
		return null
	
	var track := Track.from_dict(data)
	track.file_path = path
	
	print("TrackFormat: Loaded track '%s' with %d notes" % [track.metadata.title, track.notes.size()])
	return track

static func create_empty_track(title: String = "New Track") -> Track:
	"""Create a new empty track"""
	var track := Track.new()
	track.metadata.title = title
	track.metadata.created_at = Time.get_datetime_string_from_system(true)
	track.metadata.modified_at = track.metadata.created_at
	return track


