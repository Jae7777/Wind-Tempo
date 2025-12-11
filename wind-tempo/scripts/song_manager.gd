# scripts/SongManager.gd
# Autoload singleton for managing songs and game state
extends Node

signal song_loaded(chart: MidiParser.ChartData)
signal song_started
signal song_ended(stats: Dictionary)

# Current song data
var current_chart: MidiParser.ChartData = null
var current_track: TrackFormat.Track = null
var song_time: float = 0.0
var is_playing: bool = false

# Note scroll timing
@export var note_travel_time: float = 2.0

# Directories
const SONGS_DIR: String = "res://songs/"
const USER_SONGS_DIR: String = "user://songs/"
const TRACKS_DIR: String = "res://tracks/"
const USER_TRACKS_DIR: String = "user://tracks/"

func _ready() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("songs"):
			dir.make_dir("songs")
		if not dir.dir_exists("tracks"):
			dir.make_dir("tracks")

func scan_songs() -> Array[Dictionary]:
	"""Scan for available songs and return their metadata"""
	var songs: Array[Dictionary] = []
	songs.append_array(_scan_directory(SONGS_DIR, [".mid"]))
	songs.append_array(_scan_directory(USER_SONGS_DIR, [".mid"]))
	songs.append_array(_scan_directory(TRACKS_DIR, [".wtrack"]))
	songs.append_array(_scan_directory(USER_TRACKS_DIR, [".wtrack"]))
	return songs

func _scan_directory(path: String, extensions: Array[String]) -> Array[Dictionary]:
	var songs: Array[Dictionary] = []
	var dir := DirAccess.open(path)
	
	if dir == null:
		return songs
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			for ext in extensions:
				if file_name.ends_with(ext):
					var full_path := path.path_join(file_name)
					var song_type := "midi" if ext == ".mid" else "wtrack"
					songs.append({
						"path": full_path,
						"name": file_name.get_basename(),
						"file": file_name,
						"type": song_type
					})
					break
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return songs

func load_song(path: String) -> bool:
	"""Load a song from a MIDI or .wtrack file"""
	current_track = null
	
	if path.ends_with(".wtrack"):
		current_track = TrackFormat.load_track(path)
		if current_track == null:
			push_error("SongManager: Failed to load track: %s" % path)
			return false
		current_chart = current_track.to_chart_data()
	else:
		current_chart = MidiParser.parse_file(path)
	
	if current_chart == null:
		push_error("SongManager: Failed to load song: %s" % path)
		return false
	
	song_loaded.emit(current_chart)
	print("SongManager: Loaded '%s' with %d notes" % [current_chart.title, current_chart.notes.size()])
	return true

func start_song() -> void:
	"""Start playing the current song"""
	if current_chart == null:
		push_warning("SongManager: No song loaded")
		return
	
	song_time = -note_travel_time
	is_playing = true
	song_started.emit()

func stop_song() -> void:
	"""Stop the current song"""
	is_playing = false
	song_time = 0.0

func get_current_time() -> float:
	"""Get the current playback time"""
	return song_time

func advance_time(delta: float) -> void:
	"""Advance the song time (called by Game)"""
	if is_playing:
		song_time += delta

func is_song_complete() -> bool:
	"""Check if the song has finished"""
	if current_chart == null:
		return true
	return song_time > current_chart.duration_seconds + 2.0

func create_demo_chart() -> MidiParser.ChartData:
	"""Create a simple demo chart for testing"""
	var chart := MidiParser.ChartData.new()
	chart.title = "Demo Song"
	chart.tempo_bpm = 120.0
	
	var time: float = 0.0
	var demo_notes: Array[int] = [60, 62, 64, 65, 67, 69, 71, 72, 71, 69, 67, 65, 64, 62]
	
	for i in range(28):
		var note_event := MidiParser.NoteEvent.new()
		note_event.time_seconds = time
		note_event.midi_note = demo_notes[i % demo_notes.size()]
		note_event.duration = 0.25
		note_event.velocity = 100
		note_event.lane = note_event.midi_note - 21
		chart.notes.append(note_event)
		time += 0.5
	
	chart.duration_seconds = time
	return chart

func load_demo_song() -> void:
	"""Load the demo song for testing"""
	current_chart = create_demo_chart()
	current_track = null
	song_loaded.emit(current_chart)
