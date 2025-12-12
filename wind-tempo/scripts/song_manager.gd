# scripts/SongManager.gd
# Autoload singleton for managing songs and game state
extends Node

signal song_loaded(chart: MidiParser.ChartData)
signal song_started
signal song_ended(stats: Dictionary)

# -------------------------
# Difficulty (NEW)
# -------------------------
enum Difficulty { EASY, NORMAL, HARD, EXPERT }
@export var difficulty: int = Difficulty.NORMAL

const DIFF_PRESETS := {
	Difficulty.EASY:   {"travel_time": 2.4, "perfect": 30.0, "good": 60.0, "miss": 100.0},
	Difficulty.NORMAL: {"travel_time": 2.0, "perfect": 20.0, "good": 45.0, "miss": 80.0},
	Difficulty.HARD:   {"travel_time": 1.7, "perfect": 14.0, "good": 32.0, "miss": 60.0},
	Difficulty.EXPERT: {"travel_time": 1.4, "perfect": 10.0, "good": 24.0, "miss": 45.0},
}

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
	"""Load a song from a MIDI or .wtrack file (silent failure)"""
	current_track = null

	if path.ends_with(".wtrack"):
		current_track = TrackFormat.load_track(path)
		if current_track == null:
			return false
		current_chart = current_track.to_chart_data()
	else:
		current_chart = MidiParser.parse_file(path)

	if current_chart == null:
		return false

	song_loaded.emit(current_chart)
	return true

# -------------------------
# Difficulty application (NEW)
# -------------------------
func apply_difficulty(score_zone: Node = null) -> void:
	var preset: Dictionary = DIFF_PRESETS.get(difficulty, DIFF_PRESETS[Difficulty.NORMAL])

	# Scroll timing (SongManager)
	note_travel_time = float(preset["travel_time"])

	# Hit windows (ScoreZone) - duck-typed so it works without class_name
	if score_zone:
		if "perfect_window" in score_zone:
			score_zone.perfect_window = float(preset["perfect"])
		if "good_window" in score_zone:
			score_zone.good_window = float(preset["good"])
		if "miss_window" in score_zone:
			score_zone.miss_window = float(preset["miss"])

func start_song(score_zone: Node = null) -> void:
	"""Start playing the current song (silent if no song loaded)"""
	if current_chart == null:
		return

	apply_difficulty(score_zone)

	song_time = -note_travel_time
	is_playing = true
	song_started.emit()

func stop_song() -> void:
	is_playing = false
	song_time = 0.0

func get_current_time() -> float:
	return song_time

func advance_time(delta: float) -> void:
	if is_playing:
		song_time += delta

func is_song_complete() -> bool:
	if current_chart == null:
		return true
	return song_time > current_chart.duration_seconds + 2.0

func create_demo_chart() -> MidiParser.ChartData:
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
	current_chart = create_demo_chart()
	current_track = null
	song_loaded.emit(current_chart)
