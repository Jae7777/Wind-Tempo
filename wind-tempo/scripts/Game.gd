# scripts/Game.gd
extends Node2D

# ==== Game Mode ====
enum GameMode { PRACTICE, SONG }
@export var game_mode: GameMode = GameMode.PRACTICE

# ==== Lane / visual separators ====
@export var show_lane_lines: bool = true
@export var lane_line_width: float = 1.0
@export var lane_line_color: Color = Color(1, 1, 1, 0.15)
@export var draw_edge_lines: bool = true
@export var lane_count: int = 88
@export var lane_margin: float = 20.0

# ==== Piano Keyboard Overlay ====
@export var show_piano_overlay: bool = true
@export var white_key_color: Color = Color(0.95, 0.95, 0.92)
@export var black_key_color: Color = Color(0.15, 0.15, 0.18)
@export var key_pressed_color: Color = Color(0.4, 0.8, 1.0)
@export var show_note_labels: bool = true

# ==== Scenes & Spawn ====
@export var note_scene: PackedScene
@export var spawn_interval_min: float = 0.5
@export var spawn_interval_max: float = 1.25
@export var spawn_y: float = -40.0

# ==== Timing windows (pixels from JudgeLine) ====
@export var perfect_window: float = 20.0
@export var good_window: float = 45.0
@export var miss_window: float = 80.0  # Beyond this, note is missed

# ==== Scoring ====
@export var perfect_points: int = 100
@export var good_points: int = 50
@export var miss_points: int = 0

# ==== Combo System ====
@export var combo_multiplier_threshold: int = 10 
@export var combo_multiplier_increment: int = 10 
@export var max_combo_multiplier: float = 4.0

# ==== Nodes ====
@onready var judge_line: Marker2D = $JudgeLine
@onready var judge_bar: ColorRect = $JudgeBar
@onready var notes_container: Node = $Notes
@onready var feedback_label: Label = $CanvasLayer/FeedbackLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var combo_label: Label = $CanvasLayer/ComboLabel
@onready var accuracy_label: Label = $CanvasLayer/AccuracyLabel
@onready var stats_panel: Panel = $CanvasLayer/StatsPanel
@onready var back_button: Button = $CanvasLayer/StatsPanel/BackButton

# ==== State ====
var lane_x: Array[float] = []
var rng := RandomNumberGenerator.new()
var next_spawn: float = 0.0
var score: int = 0
var lane_width: float = 0.0
var song_finished: bool = false
var pressed_lanes: Dictionary = {}  # Track which lanes are currently pressed for visual feedback

# ==== Chart playback ====
var spawned_note_ids: Dictionary = {}  # Track which chart notes have been spawned
var note_speed: float = 250.0  # Pixels per second

# ==== Combo & Accuracy Stats ====
var current_combo: int = 0
var max_combo: int = 0
var perfect_count: int = 0
var good_count: int = 0
var miss_count: int = 0

# ==== Piano note labels (A0..C8) ====
const MIDI_START_A0: int = 21
const NOTE_NAMES: Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

func _lane_label(lane: int) -> String:
	var midi: int = MIDI_START_A0 + lane
	var idx: int = midi % 12
	var note_name: String = NOTE_NAMES[idx]
	var octave: int = int(midi / 12) - 1
	return "%s%d" % [note_name, octave]

# ==== Keyboard control (window over 88 keys) ====
const KB_KEYS: Array[int] = [
	Key.KEY_A, Key.KEY_S, Key.KEY_D, Key.KEY_F, Key.KEY_G,
	Key.KEY_H, Key.KEY_J, Key.KEY_K, Key.KEY_L, Key.KEY_SEMICOLON, Key.KEY_APOSTROPHE
]
const KB_LEFT: int = Key.KEY_COMMA
const KB_RIGHT: int = Key.KEY_PERIOD
const KB_OCT_DOWN: int = Key.KEY_BRACKETLEFT
const KB_OCT_UP: int = Key.KEY_BRACKETRIGHT

var kb_base_lane: int = 0  # leftmost lane index controlled by KB window

func _ensure_keyboard_actions() -> void:
	# Create actions for each play key
	for i in KB_KEYS.size():
		var act := "kb_play_%d" % i
		if !InputMap.has_action(act):
			InputMap.add_action(act)
			var ev := InputEventKey.new()
			ev.physical_keycode = KB_KEYS[i]
			ev.keycode = KB_KEYS[i]
			InputMap.action_add_event(act, ev)
	# Navigation actions
	var nav := {
		"kb_left": KB_LEFT,
		"kb_right": KB_RIGHT,
		"kb_oct_down": KB_OCT_DOWN,
		"kb_oct_up": KB_OCT_UP
	}
	for act_name in nav.keys():
		if !InputMap.has_action(act_name):
			InputMap.add_action(act_name)
			var ev2 := InputEventKey.new()
			ev2.physical_keycode = nav[act_name]
			ev2.keycode = nav[act_name]
			InputMap.action_add_event(act_name, ev2)

func _ready() -> void:
	rng.randomize()
	_compute_lane_x_positions()
	next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)

	feedback_label.visible = false
	judge_bar.position.y = judge_line.position.y - (judge_bar.size.y * 0.5)
	_update_score_ui()
	_update_combo_ui()
	_update_accuracy_ui()
	
	# Hide stats panel initially (will show at end of song)
	if stats_panel:
		stats_panel.visible = false
	
	# Default KB window centered around middle C (MIDI 60)
	var middle_c_lane := 60 - MIDI_START_A0
	var window := KB_KEYS.size()
	kb_base_lane = clampi(middle_c_lane - window / 2, 0, maxi(0, lane_count - window))
	_ensure_keyboard_actions()
	
	# Connect to MIDI input if available
	if Engine.has_singleton("MidiInput") or has_node("/root/MidiInput"):
		var midi_input = get_node_or_null("/root/MidiInput")
		if midi_input:
			midi_input.note_on.connect(_on_midi_note_on)
			midi_input.note_off.connect(_on_midi_note_off)
			print("Game: Connected to MIDI input")
	
	# Connect to SongManager if in song mode
	if game_mode == GameMode.SONG:
		var song_manager = get_node_or_null("/root/SongManager")
		if song_manager:
			# Calculate note speed based on travel time and distance
			var travel_distance: float = judge_line.position.y - spawn_y
			note_speed = travel_distance / song_manager.note_travel_time
			song_manager.start_song()
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_to_menu)
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_to_menu()

func _on_back_to_menu() -> void:
	# Stop song if playing
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		song_manager.stop_song()
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_compute_lane_x_positions()
		queue_redraw()

func _process(delta: float) -> void:
	if song_finished:
		return
	
	if game_mode == GameMode.PRACTICE:
		_process_practice_mode(delta)
	else:
		_process_song_mode(delta)
	
	_process_keyboard_input()
	_check_missed_notes()

func _process_practice_mode(delta: float) -> void:
	# Random spawns for practice/testing
	next_spawn -= delta
	if next_spawn <= 0.0:
		next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)
		# Focus on middle octaves for practice (C3-C5 = lanes 24-48)
		var lane: int = rng.randi_range(24, 48)
		_spawn_note_in_lane(lane)

func _process_song_mode(delta: float) -> void:
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager == null or song_manager.current_chart == null:
		return
	
	# Advance song time
	song_manager.advance_time(delta)
	
	# Spawn notes from chart
	var chart: MidiParser.ChartData = song_manager.current_chart
	var song_time: float = song_manager.get_current_time()
	var travel_time: float = song_manager.note_travel_time
	
	for i in range(chart.notes.size()):
		if spawned_note_ids.has(i):
			continue
		
		var note_event: MidiParser.NoteEvent = chart.notes[i]
		var spawn_time: float = note_event.time_seconds - travel_time
		
		# Spawn note if it's time
		if song_time >= spawn_time:
			_spawn_note_in_lane(note_event.lane, note_event.velocity)
			spawned_note_ids[i] = true
	
	# Check if song is complete
	if song_manager.is_song_complete():
		_on_song_complete()

func _process_keyboard_input() -> void:
	# KB window navigation
	if Input.is_action_just_pressed("kb_left"):
		kb_base_lane = maxi(0, kb_base_lane - 1)
		queue_redraw()
	if Input.is_action_just_pressed("kb_right"):
		kb_base_lane = mini(lane_count - KB_KEYS.size(), kb_base_lane + 1)
		queue_redraw()
	if Input.is_action_just_pressed("kb_oct_down"):
		kb_base_lane = maxi(0, kb_base_lane - 12)
		queue_redraw()
	if Input.is_action_just_pressed("kb_oct_up"):
		kb_base_lane = mini(lane_count - KB_KEYS.size(), kb_base_lane + 12)
		queue_redraw()

	# Play notes with ASDF… ; ' - track pressed and released
	var needs_redraw := false
	for i in KB_KEYS.size():
		var act := "kb_play_%d" % i
		var lane_idx := kb_base_lane + i
		if lane_idx >= 0 and lane_idx < lane_count:
			if Input.is_action_just_pressed(act):
				pressed_lanes[lane_idx] = true
				needs_redraw = true
				_evaluate_hit_for_lane(lane_idx)
			elif Input.is_action_just_released(act):
				if pressed_lanes.has(lane_idx):
					pressed_lanes.erase(lane_idx)
					needs_redraw = true
	
	if needs_redraw:
		queue_redraw()

func _on_midi_note_on(midi_note: int, _velocity: int, _channel: int) -> void:
	"""Handle MIDI keyboard input"""
	var lane: int = midi_note - MIDI_START_A0
	if lane >= 0 and lane < lane_count:
		pressed_lanes[lane] = true
		queue_redraw()
		_evaluate_hit_for_lane(lane)

func _on_midi_note_off(midi_note: int, _channel: int) -> void:
	"""Handle MIDI keyboard release"""
	var lane: int = midi_note - MIDI_START_A0
	if pressed_lanes.has(lane):
		pressed_lanes.erase(lane)
		queue_redraw()

func _check_missed_notes() -> void:
	"""Check for notes that have passed the judge line and are now missed"""
	var miss_threshold: float = judge_line.global_position.y + miss_window
	
	for child in notes_container.get_children():
		if child is Node2D:
			var note_node := child as Node2D
			if note_node.global_position.y > miss_threshold:
				# Note missed
				var lane: int = note_node.get("lane") if note_node.get("lane") != null else 0
				_register_miss(lane)
				note_node.queue_free()

func _register_miss(lane: int) -> void:
	"""Register a missed note"""
	current_combo = 0
	miss_count += 1
	_update_combo_ui()
	_update_accuracy_ui()
	
	var label: String = _lane_label(lane)
	_show_feedback("MISS (%s)" % label, Color(1.0, 0.3, 0.3))

func _compute_lane_x_positions() -> void:
	lane_x.clear()
	var width: float = get_viewport_rect().size.x
	var usable: float = maxf(0.0, width - 2.0 * lane_margin)
	if lane_count <= 0 or usable <= 0.0:
		lane_x.append(width * 0.5)
		lane_width = usable
		return

	lane_width = usable / float(lane_count)
	for i in range(lane_count):
		var center_x: float = lane_margin + (i + 0.5) * lane_width
		lane_x.append(center_x)

	queue_redraw()

func _spawn_note_in_lane(lane: int, velocity: int = 100) -> void:
	if note_scene == null:
		push_warning("note_scene is not assigned.")
		return
	if lane < 0 or lane >= lane_x.size():
		return

	var note := note_scene.instantiate() as Node2D
	note.position = Vector2(lane_x[lane], spawn_y)
	note.set("lane", lane)
	
	# Set note speed if the note script supports it
	if note.get("speed") != null:
		note.set("speed", note_speed)
	
	# Set note name for the label
	var note_label_text: String = _lane_label(lane)
	if note.has_method("set_note_name"):
		note.set_note_name(note_label_text)
	elif note.get("note_name") != null:
		note.set("note_name", note_label_text)
	
	notes_container.add_child(note)

	# Fit note width to the lane width (Polygon2D assumed -12..12 => 24px base)
	var poly := note.get_node_or_null("Polygon2D")
	if poly is Polygon2D:
		var base_w: float = 24.0
		var scale_factor: float = maxf(1.0, lane_width) / base_w
		(poly as Polygon2D).scale.x = scale_factor
		
		# Color based on whether it's a black or white key
		var midi_note: int = lane + MIDI_START_A0
		var is_black: bool = _is_black_key(midi_note)
		if is_black:
			# Dark with subtle purple tint
			(poly as Polygon2D).color = Color(0.25, 0.2, 0.35)
		else:
			# Bright color based on octave - rainbow gradient
			var octave_progress: float = float(midi_note - 21) / 87.0
			(poly as Polygon2D).color = Color.from_hsv(octave_progress * 0.8, 0.7, 0.95)
	
	# Scale the label if it exists
	var label := note.get_node_or_null("NoteLabel")
	if label is Label:
		# Adjust label position based on note scale
		(label as Label).offset_left = -lane_width * 0.5
		(label as Label).offset_right = lane_width * 0.5

func _evaluate_hit_for_lane(lane: int) -> void:
	var best: Node2D = null
	var best_dist: float = INF

	for c in notes_container.get_children():
		if c is Node2D:
			var note_lane = c.get("lane")
			if note_lane != null and int(note_lane) == lane:
				var d: float = abs((c as Node2D).global_position.y - judge_line.global_position.y)
				if d < best_dist:
					best_dist = d
					best = c

	var label: String = _lane_label(lane)
	var result: String = "MISS (%s)" % label
	var base_points: int = miss_points
	var color: Color = Color(1.0, 0.3, 0.3)
	var hit_type: String = "miss"

	if best != null:
		if best_dist <= perfect_window:
			result = "PERFECT (%s)" % label
			base_points = perfect_points
			color = Color(0.3, 1.0, 0.3)
			hit_type = "perfect"
			best.queue_free()
		elif best_dist <= good_window:
			result = "GOOD (%s)" % label
			base_points = good_points
			color = Color(1.0, 0.9, 0.3)
			hit_type = "good"
			best.queue_free()

	# Update combo and stats based on hit type
	if hit_type == "perfect":
		current_combo += 1
		perfect_count += 1
		if current_combo > max_combo:
			max_combo = current_combo
	elif hit_type == "good":
		current_combo += 1
		good_count += 1
		if current_combo > max_combo:
			max_combo = current_combo
	else:  # miss
		current_combo = 0
		miss_count += 1

	# Calculate combo multiplier
	var multiplier: float = _get_combo_multiplier()
	var final_points: int = int(base_points * multiplier)
	
	score += final_points
	_update_score_ui()
	_update_combo_ui()
	_update_accuracy_ui()
	
	# Show multiplier in feedback if active
	if multiplier > 1.0:
		result += " x%.1f" % multiplier
	
	_show_feedback(result, color)

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.visible = true
	var t := create_tween()
	t.tween_property(feedback_label, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.finished.connect(func():
		feedback_label.visible = false
		feedback_label.modulate.a = 1.0
	)

func _update_score_ui() -> void:
	score_label.text = "Score: %d" % score

func _update_combo_ui() -> void:
	if combo_label:
		if current_combo > 0:
			combo_label.text = "Combo: %d" % current_combo
			# Change color based on combo multiplier
			var multiplier := _get_combo_multiplier()
			if multiplier >= max_combo_multiplier:
				combo_label.modulate = Color(1.0, 0.2, 1.0)  # max combo - pink/purple
			elif multiplier > 1.0:
				combo_label.modulate = Color(1.0, 0.8, 0.2)  # active multiplier - gold
			else:
				combo_label.modulate = Color(1.0, 1.0, 1.0)  # normal - white
		else:
			combo_label.text = ""

func _update_accuracy_ui() -> void:
	if accuracy_label:
		var total_notes: int = perfect_count + good_count + miss_count
		if total_notes > 0:
			var accuracy: float = (float(perfect_count) + float(good_count) * 0.5) / float(total_notes) * 100.0
			accuracy_label.text = "Accuracy: %.1f%%" % accuracy
		else:
			accuracy_label.text = "Accuracy: --.--%"

func _get_combo_multiplier() -> float:
	if current_combo < combo_multiplier_threshold:
		return 1.0
	
	var extra_combo: int = current_combo - combo_multiplier_threshold
	var multiplier: float = 1.0 + float(extra_combo / combo_multiplier_increment)
	return minf(multiplier, max_combo_multiplier)

func _on_song_complete() -> void:
	"""Called when the song finishes"""
	song_finished = true
	show_stats_panel()
	
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		song_manager.song_ended.emit({
			"score": score,
			"perfect": perfect_count,
			"good": good_count,
			"miss": miss_count,
			"max_combo": max_combo
		})

func show_stats_panel() -> void:
	"""Call this function when the song ends to display final statistics"""
	if not stats_panel:
		push_warning("StatsPanel node not found")
		return
	
	var total_notes: int = perfect_count + good_count + miss_count
	var accuracy: float = 0.0
	if total_notes > 0:
		accuracy = (float(perfect_count) + float(good_count) * 0.5) / float(total_notes) * 100.0
	
	# Determine rank
	var rank: String = _calculate_rank(accuracy)
	
	# Update stats panel labels 
	var stats_text := "=== FINAL STATS ===\n\n"
	stats_text += "Rank: %s\n\n" % rank
	stats_text += "Score: %d\n\n" % score
	stats_text += "Perfect: %d\n" % perfect_count
	stats_text += "Good: %d\n" % good_count
	stats_text += "Miss: %d\n" % miss_count
	stats_text += "Total Notes: %d\n\n" % total_notes
	stats_text += "Accuracy: %.2f%%\n\n" % accuracy
	stats_text += "Max Combo: %d" % max_combo
	
	# Try to find label child in StatsPanel
	var stats_label: Label = null
	for child in stats_panel.get_children():
		if child is Label:
			stats_label = child
			break
	
	if stats_label:
		stats_label.text = stats_text
	else:
		print(stats_text)  # print to console if there is no label found
	
	stats_panel.visible = true

func _calculate_rank(accuracy: float) -> String:
	if accuracy >= 95.0:
		return "S"
	elif accuracy >= 90.0:
		return "A"
	elif accuracy >= 80.0:
		return "B"
	elif accuracy >= 70.0:
		return "C"
	elif accuracy >= 60.0:
		return "D"
	else:
		return "F"

func _draw() -> void:
	var rect := get_viewport_rect()
	var w: float = rect.size.x
	var h: float = rect.size.y
	var usable: float = maxf(0.0, w - 2.0 * lane_margin)
	if lane_count <= 0 or usable <= 0.0:
		return

	var step_w: float = usable / float(lane_count)
	var start_x: float = lane_margin
	
	# Draw lane lines (subtle grid)
	if show_lane_lines:
		if draw_edge_lines:
			draw_line(Vector2(start_x, 0), Vector2(start_x, h), lane_line_color, lane_line_width, true)
		for i in range(1, lane_count):
			var x: float = start_x + float(i) * step_w
			# Draw slightly brighter lines at octave boundaries (C notes)
			var midi_note: int = MIDI_START_A0 + i
			if midi_note % 12 == 0:  # C note
				draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.3), lane_line_width + 1, true)
			else:
				draw_line(Vector2(x, 0), Vector2(x, h), lane_line_color, lane_line_width, true)
		if draw_edge_lines:
			var right_x: float = start_x + float(lane_count) * step_w
			draw_line(Vector2(right_x, 0), Vector2(right_x, h), lane_line_color, lane_line_width, true)
	
	# Draw piano keyboard overlay at the bottom
	if show_piano_overlay:
		_draw_piano_overlay(start_x, step_w, h)

func _draw_piano_overlay(start_x: float, key_width: float, screen_height: float) -> void:
	var piano_y: float = judge_line.position.y - 10  # Just above judge line
	var piano_bottom: float = screen_height
	var piano_h: float = piano_bottom - piano_y
	
	# Draw background
	draw_rect(Rect2(start_x, piano_y, lane_count * key_width, piano_h), Color(0.1, 0.1, 0.12), true)
	
	# First pass: Draw all white keys
	for i in range(lane_count):
		var midi_note: int = MIDI_START_A0 + i
		var is_black: bool = _is_black_key(midi_note)
		
		if not is_black:
			var key_x: float = start_x + i * key_width
			var key_color: Color = white_key_color
			
			# Highlight if pressed
			if pressed_lanes.has(i):
				key_color = key_pressed_color
			
			# Draw white key
			draw_rect(Rect2(key_x, piano_y, key_width - 1, piano_h), key_color, true)
			draw_rect(Rect2(key_x, piano_y, key_width - 1, piano_h), Color(0.3, 0.3, 0.3), false, 1.0)
			
			# Draw note name on C keys
			if show_note_labels and midi_note % 12 == 0:
				var octave: int = (midi_note / 12) - 1
				var label_text: String = "C%d" % octave
				_draw_key_label(key_x + key_width * 0.5, piano_bottom - 15, label_text, Color(0.2, 0.2, 0.2))
	
	# Second pass: Draw all black keys (on top)
	for i in range(lane_count):
		var midi_note: int = MIDI_START_A0 + i
		var is_black: bool = _is_black_key(midi_note)
		
		if is_black:
			var key_x: float = start_x + i * key_width
			var black_key_h: float = piano_h * 0.6
			var key_color: Color = black_key_color
			
			# Highlight if pressed
			if pressed_lanes.has(i):
				key_color = key_pressed_color.darkened(0.3)
			
			# Draw black key
			draw_rect(Rect2(key_x, piano_y, key_width - 1, black_key_h), key_color, true)
			draw_rect(Rect2(key_x, piano_y, key_width - 1, black_key_h), Color(0.0, 0.0, 0.0), false, 1.0)

func _draw_key_label(x: float, y: float, text: String, color: Color) -> void:
	# Use default font - will be small but readable
	var font := ThemeDB.fallback_font
	var font_size: int = 10
	draw_string(font, Vector2(x - 8, y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

func _is_black_key(midi_note: int) -> bool:
	var note_in_octave: int = midi_note % 12
	return note_in_octave in [1, 3, 6, 8, 10]
