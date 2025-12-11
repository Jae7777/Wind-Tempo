extends Node

"""
ChartSpawner manages note spawning based on chart data and audio playback timing.
Synchronizes note spawn times with the current song position.
"""

@export var note_scene: PackedScene
@export var chart_file_path: String = "res://charts/sample_song.json"
@export var spawn_lead_time: float = 3.0  # Spawn notes 3 seconds before they should be hit

var chart_loader: Node
var current_chart: Node
var highway: Node2D
var hit_detector: Node2D
var audio_player: AudioStreamPlayer

var spawned_notes: Array = []
var current_note_index: int = 0
var is_spawning: bool = false
var latency_offset: float = 0.0  # Calibration offset in seconds

func _ready() -> void:
	chart_loader = get_parent().get_node_or_null("ChartLoader")
	highway = get_parent().get_node_or_null("Highway")
	hit_detector = get_parent().get_node_or_null("HitDetector")
	audio_player = get_parent().get_node_or_null("AudioPlayer")
	
	if not note_scene:
		push_error("ChartSpawner: note_scene not assigned!")
	
	if chart_loader:
		chart_loader.connect("chart_loaded", self, "_on_chart_loaded")
	
	# Load the default chart
	if chart_loader:
		current_chart = chart_loader.load_chart(chart_file_path)

func _process(delta: float) -> void:
	if not is_spawning or not audio_player or not audio_player.playing:
		return
	
	var current_time = audio_player.get_playback_position() + latency_offset
	
	# Spawn all notes that should appear now
	if current_chart and current_note_index < current_chart.notes.size():
		while current_note_index < current_chart.notes.size():
			var note_data = current_chart.notes[current_note_index]
			var spawn_trigger_time = note_data["time"] - spawn_lead_time
			
			if current_time >= spawn_trigger_time:
				_spawn_note(note_data)
				current_note_index += 1
			else:
				break

func _spawn_note(note_data: Dictionary) -> void:
	"""Spawn a single note based on note data."""
	if not note_scene or not highway:
		return
	
	var note = note_scene.instantiate()
	note.lane = note_data["lane"]
	note.spawn_time = note_data["time"]
	
	# Set initial X position based on lane
	var lane_positions = [100, 220, 340, 460]
	if note.lane >= 0 and note.lane < lane_positions.size():
		note.position.x = lane_positions[note.lane]
	
	# Spawn above screen
	note.position.y = -120
	
	highway.add_child(note)
	spawned_notes.append(note)
	
	# Register with hit detector
	if hit_detector:
		hit_detector.register_note(note)

func start_spawning() -> void:
	"""Start spawning notes from the current chart."""
	if not current_chart:
		push_error("ChartSpawner: No chart loaded!")
		return
	
	current_note_index = 0
	is_spawning = true

func stop_spawning() -> void:
	"""Stop spawning new notes."""
	is_spawning = false

func reset() -> void:
	"""Reset spawner state."""
	current_note_index = 0
	is_spawning = false
	spawned_notes.clear()

func load_chart(file_path: String) -> bool:
	"""Load a new chart."""
	if not chart_loader:
		push_error("ChartSpawner: ChartLoader not found!")
		return false
	
	current_chart = chart_loader.load_chart(file_path)
	if current_chart and chart_loader.validate_chart(current_chart):
		reset()
		return true
	
	return false

func set_latency_offset(offset: float) -> void:
	"""Set timing offset for audio latency compensation."""
	latency_offset = offset
	print("Latency offset set to: %.2f ms" % (latency_offset * 1000))

func _on_chart_loaded(chart: Node) -> void:
	"""Handle chart loaded signal."""
	current_chart = chart
	reset()
	print("Chart loaded: %s by %s" % [chart.get_title(), chart.get_artist()])
