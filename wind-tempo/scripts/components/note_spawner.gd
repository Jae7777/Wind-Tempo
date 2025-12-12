# scripts/components/note_spawner.gd
# Handles spawning notes from charts or randomly for practice
class_name NoteSpawner
extends Node2D

signal note_spawned(note: Node2D, lane: int)

@export var note_scene: PackedScene
@export var spawn_y: float = -40.0
@export var spawn_interval_min: float = 0.5
@export var spawn_interval_max: float = 1.25
@export var practice_lane_min: int = 24  # C3
@export var practice_lane_max: int = 48  # C5

const MIDI_START_A0: int = 21
const NOTE_NAMES: Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

# References
var lane_manager: LaneManager = null
var notes_container: Node2D = null

# State
var rng := RandomNumberGenerator.new()
var next_spawn: float = 0.0
var note_speed: float = 250.0
var spawned_note_ids: Dictionary = {}
var is_practice_mode: bool = true

func _ready() -> void:
	rng.randomize()
	next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)
	
	# Find lane manager in scene tree
	lane_manager = _find_component(LaneManager) as LaneManager
	
	# Find or create notes container as a child
	notes_container = get_node_or_null("NotesContainer")
	if notes_container == null:
		notes_container = Node2D.new()
		notes_container.name = "NotesContainer"
		add_child(notes_container)
	
	if lane_manager:
		lane_manager.lanes_updated.connect(_on_lanes_updated)

func _on_lanes_updated(_positions: Array[float], _width: float) -> void:
	# Could update note sizes here if needed
	pass

func _find_component(type: Variant) -> Node:
	var parent := get_parent()
	while parent:
		for child in parent.get_children():
			if is_instance_of(child, type):
				return child
		parent = parent.get_parent()
	return null

func _process(delta: float) -> void:
	if is_practice_mode:
		_process_practice_mode(delta)

func _process_practice_mode(delta: float) -> void:
	next_spawn -= delta
	if next_spawn <= 0.0:
		next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)
		var lane: int = rng.randi_range(practice_lane_min, practice_lane_max)
		spawn_note(lane)

func set_practice_mode(enabled: bool) -> void:
	is_practice_mode = enabled

func set_note_speed(speed: float) -> void:
	note_speed = speed

func spawn_note(lane: int, velocity: int = 100) -> Node2D:
	if note_scene == null:
		push_warning("NoteSpawner: note_scene not assigned")
		return null
	
	if lane_manager == null:
		push_warning("NoteSpawner: lane_manager not found")
		return null
	
	var lane_x := lane_manager.get_lane_x(lane)
	var lane_width := lane_manager.get_lane_width()
	
	var note := note_scene.instantiate() as Node2D
	note.position = Vector2(lane_x, spawn_y)
	note.set("lane", lane)
	
	if note.get("speed") != null:
		note.set("speed", note_speed)
	
	# Set note name label
	var note_label := _get_lane_label(lane)
	if note.has_method("set_note_name"):
		note.set_note_name(note_label)
	elif note.get("note_name") != null:
		note.set("note_name", note_label)
	
	notes_container.add_child(note)
	
	# Style the note
	_style_note(note, lane, lane_width)
	
	note_spawned.emit(note, lane)
	return note

func spawn_from_chart(chart_notes: Array, song_time: float, travel_time: float) -> void:
	for i in range(chart_notes.size()):
		if spawned_note_ids.has(i):
			continue
		
		var note_event = chart_notes[i]
		var spawn_time: float = note_event.time_seconds - travel_time
		
		if song_time >= spawn_time:
			spawn_note(note_event.lane, note_event.velocity)
			spawned_note_ids[i] = true

func reset_chart_state() -> void:
	spawned_note_ids.clear()

func get_notes_container() -> Node2D:
	return notes_container

func _style_note(note: Node2D, lane: int, lane_width: float) -> void:
	var poly := note.get_node_or_null("Polygon2D")
	if poly is Polygon2D:
		var base_w: float = 24.0
		(poly as Polygon2D).scale.x = maxf(1.0, lane_width) / base_w
		
		var midi_note: int = lane + MIDI_START_A0
		if _is_black_key(midi_note):
			(poly as Polygon2D).color = Color(0.25, 0.2, 0.35)
		else:
			var octave_progress: float = float(midi_note - 21) / 87.0
			(poly as Polygon2D).color = Color.from_hsv(octave_progress * 0.8, 0.7, 0.95)
	
	var label := note.get_node_or_null("NoteLabel")
	if label is Label:
		(label as Label).offset_left = -lane_width * 0.5
		(label as Label).offset_right = lane_width * 0.5

func _get_lane_label(lane: int) -> String:
	var midi: int = MIDI_START_A0 + lane
	var idx: int = midi % 12
	var octave: int = (midi / 12) - 1
	return "%s%d" % [NOTE_NAMES[idx], octave]

func _is_black_key(midi_note: int) -> bool:
	return (midi_note % 12) in [1, 3, 6, 8, 10]
