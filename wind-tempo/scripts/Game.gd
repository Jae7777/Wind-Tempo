# scripts/Game.gd
extends Node2D

# ==== Lane / visual separators ====
@export var show_lane_lines: bool = true
@export var lane_line_width: float = 2.0
@export var lane_line_color: Color = Color(1, 1, 1, 0.35)
@export var draw_edge_lines: bool = true
@export var lane_count: int = 88
@export var lane_margin: float = 120.0

# ==== Scenes & Spawn ====
@export var note_scene: PackedScene
@export var spawn_interval_min: float = 0.5
@export var spawn_interval_max: float = 1.25
@export var spawn_y: float = -40.0

# ==== Timing windows (pixels from JudgeLine) ====
@export var perfect_window: float = 10.0
@export var good_window: float = 24.0

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

# ==== State ====
var lane_x: Array[float] = []
var rng := RandomNumberGenerator.new()
var next_spawn: float = 0.0
var score: int = 0
var lane_width: float = 0.0

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
	var name: String = NOTE_NAMES[idx]
	var octave: int = int(midi / 12) - 1
	return "%s%d" % [name, octave]

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
	for name in nav.keys():
		if !InputMap.has_action(name):
			InputMap.add_action(name)
			var ev2 := InputEventKey.new()
			ev2.physical_keycode = nav[name]
			ev2.keycode = nav[name]
			InputMap.action_add_event(name, ev2)

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
	kb_base_lane = clamp(middle_c_lane - window / 2, 0, max(0, lane_count - window))
	_ensure_keyboard_actions()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_compute_lane_x_positions()
		queue_redraw()

func _process(delta: float) -> void:
	# Random spawns for testing (replace with chart/MIDI later)
	next_spawn -= delta
	if next_spawn <= 0.0:
		next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)
		var lane: int = rng.randi_range(0, max(1, lane_count) - 1)
		_spawn_note_in_lane(lane)

	# KB window navigation
	if Input.is_action_just_pressed("kb_left"):
		kb_base_lane = max(0, kb_base_lane - 1)
	if Input.is_action_just_pressed("kb_right"):
		kb_base_lane = min(lane_count - KB_KEYS.size(), kb_base_lane + 1)
	if Input.is_action_just_pressed("kb_oct_down"):
		kb_base_lane = max(0, kb_base_lane - 12)
	if Input.is_action_just_pressed("kb_oct_up"):
		kb_base_lane = min(lane_count - KB_KEYS.size(), kb_base_lane + 12)

	# Play notes with ASDF… ; '
	for i in KB_KEYS.size():
		var act := "kb_play_%d" % i
		if Input.is_action_just_pressed(act):
			var lane_idx := kb_base_lane + i
			if lane_idx >= 0 and lane_idx < lane_count:
				_evaluate_hit_for_lane(lane_idx)

func _compute_lane_x_positions() -> void:
	lane_x.clear()
	var width: float = get_viewport_rect().size.x
	var usable: float = max(0.0, width - 2.0 * lane_margin)
	if lane_count <= 0 or usable <= 0.0:
		lane_x.append(width * 0.5)
		lane_width = usable
		return

	lane_width = usable / float(lane_count)
	for i in range(lane_count):
		var center_x: float = lane_margin + (i + 0.5) * lane_width
		lane_x.append(center_x)

	queue_redraw()

func _spawn_note_in_lane(lane: int) -> void:
	if note_scene == null:
		push_warning("note_scene is not assigned.")
		return
	if lane < 0 or lane >= lane_x.size():
		return

	var note := note_scene.instantiate() as Node2D
	note.position = Vector2(lane_x[lane], spawn_y)
	note.set("lane", lane)
	notes_container.add_child(note)

	# Fit note width to the lane width (Polygon2D assumed -12..12 => 24px base)
	var poly := note.get_node_or_null("Polygon2D")
	if poly is Polygon2D:
		var base_w: float = 24.0
		(poly as Polygon2D).scale.x = (max(1.0, lane_width)) / base_w
		# Optional: color per lane
		var hue: float = float(lane) / float(lane_count)
		(poly as Polygon2D).color = Color.from_hsv(hue, 0.75, 0.95)

func _evaluate_hit_for_lane(lane: int) -> void:
	var best: Node2D = null
	var best_dist: float = INF

	for c in notes_container.get_children():
		if c is Node2D and int(c.get("lane")) == lane:
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
			elif multiplier > 1.0
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
	return min(multiplier, max_combo_multiplier)

func show_stats_panel() -> void:
	"""Call this function when the song ends to display final statistics"""
	if not stats_panel:
		push_warning("StatsPanel node not found")
		return
	
	var total_notes: int = perfect_count + good_count + miss_count
	var accuracy: float = 0.0
	if total_notes > 0:
		accuracy = (float(perfect_count) + float(good_count) * 0.5) / float(total_notes) * 100.0
	
	# Update stats panel labels 
	var stats_text := "=== FINAL STATS ===\n\n"
	stats_text += "Score: %d\n\n" % score
	stats_text += "Perfect: %d\n" % perfect_count
	stats_text += "Good: %d\n" % good_count
	stats_text += "Miss: %d\n" % miss_count
	stats_text += "Total Notes: %d\n\n" % total_notes
	stats_text += "Accuracy: %.2f%%\n\n" % accuracy
	stats_text += "Max Combo: %d" % max_combo
	
	# try to find label child in StatsPanel
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

func _draw() -> void:
	if !show_lane_lines:
		return

	var rect := get_viewport_rect()
	var w: float = rect.size.x
	var h: float = rect.size.y
	var usable: float = max(0.0, w - 2.0 * lane_margin)
	if lane_count <= 0 or usable <= 0.0:
		return

	var step_w: float = usable / float(lane_count)

	var start_x: float = lane_margin
	if draw_edge_lines:
		draw_line(Vector2(start_x, 0), Vector2(start_x, h), lane_line_color, lane_line_width, true)
	for i in range(1, lane_count):
		var x: float = start_x + float(i) * step_w
		draw_line(Vector2(x, 0), Vector2(x, h), lane_line_color, lane_line_width, true)
	if draw_edge_lines:
		var right_x: float = start_x + float(lane_count) * step_w
		draw_line(Vector2(right_x, 0), Vector2(right_x, h), lane_line_color, lane_line_width, true)
