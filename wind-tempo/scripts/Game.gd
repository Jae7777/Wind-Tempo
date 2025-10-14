# scripts/Game.gd
extends Node2D

# ==== Scenes & Spawn ====
@export var note_scene: PackedScene          # drag scenes/Note.tscn here
@export var spawn_interval_min: float = 0.5  # random spawn interval range
@export var spawn_interval_max: float = 1.25
@export var spawn_y: float = -40.0           # where notes appear (above the screen)
@export var lane_margin: float = 120.0       # left/right padding for lanes

# ==== Timing windows (pixels from JudgeLine) ====
@export var perfect_window: float = 10.0
@export var good_window: float = 24.0

# ==== Scoring ====
@export var perfect_points: int = 100
@export var good_points: int = 50
@export var miss_points: int = 0

# ==== Input mapping (9 lanes on ASDFGHJKL) ====
const LANE_ACTIONS := ["hit_a","hit_s","hit_d","hit_f","hit_g","hit_h","hit_j","hit_k","hit_l"]
const KEY_LABELS   := ["A","S","D","F","G","H","J","K","L"]

# ==== Nodes ====
@onready var judge_line: Marker2D = $JudgeLine
@onready var judge_bar: ColorRect = $JudgeBar
@onready var notes_container: Node = $Notes
@onready var feedback_label: Label = $CanvasLayer/FeedbackLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel

# ==== State ====
var lane_x: Array[float] = []
var rng := RandomNumberGenerator.new()
var next_spawn: float = 0.0
var score: int = 0

func _ready() -> void:
	rng.randomize()
	_compute_lane_x_positions()
	next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)

	feedback_label.visible = false
	# center the visual bar on the judge line's Y
	judge_bar.position.y = judge_line.position.y - (judge_bar.size.y * 0.5)
	_update_score_ui()

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_compute_lane_x_positions()

func _process(delta: float) -> void:
	# random spawning
	next_spawn -= delta
	if next_spawn <= 0.0:
		next_spawn = rng.randf_range(spawn_interval_min, spawn_interval_max)
		var lane := rng.randi_range(0, LANE_ACTIONS.size() - 1)
		_spawn_note_in_lane(lane)

	# per-lane input (ASDFGHJKL)
	for i in range(LANE_ACTIONS.size()):
		if Input.is_action_just_pressed(LANE_ACTIONS[i]):
			_evaluate_hit_for_lane(i)

func _compute_lane_x_positions() -> void:
	lane_x.clear()
	var width := get_viewport_rect().size.x
	var lanes := LANE_ACTIONS.size()
	if lanes <= 1:
		lane_x.append(width * 0.5)
		return
	var usable: float = max(0.0, width - 2.0 * lane_margin)
	var step: float = usable / float(lanes - 1)
	for i in range(lanes):
		lane_x.append(lane_margin + step * i)

func _spawn_note_in_lane(lane: int) -> void:
	if note_scene == null:
		push_warning("note_scene is not assigned.")
		return
	if lane < 0 or lane >= lane_x.size():
		return

	var note := note_scene.instantiate() as Node2D
	note.position = Vector2(lane_x[lane], spawn_y)
	note.set("lane", lane)  # store which lane it belongs to
	notes_container.add_child(note)

	# Optional: color by lane (requires Polygon2D named "Shape" under Note)
	var poly := note.get_node_or_null("Shape")
	if poly is Polygon2D:
		var hue := float(lane) / float(LANE_ACTIONS.size())
		(poly as Polygon2D).color = Color.from_hsv(hue, 0.75, 0.95)

func _evaluate_hit_for_lane(lane: int) -> void:
	var best: Node2D = null
	var best_dist := INF

	# find nearest note in this lane only
	for c in notes_container.get_children():
		if c is Node2D and int(c.get("lane")) == lane:
			var d: float = abs((c as Node2D).global_position.y - judge_line.global_position.y)
			if d < best_dist:
				best_dist = d
				best = c

	var result := "MISS (%s)" % KEY_LABELS[lane]
	var points := miss_points
	var color := Color(1.0, 0.3, 0.3)

	if best != null:
		if best_dist <= perfect_window:
			result = "PERFECT (%s)" % KEY_LABELS[lane]
			points = perfect_points
			color = Color(0.3, 1.0, 0.3)
			best.queue_free()
		elif best_dist <= good_window:
			result = "GOOD (%s)" % KEY_LABELS[lane]
			points = good_points
			color = Color(1.0, 0.9, 0.3)
			best.queue_free()

	score += points
	_update_score_ui()
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
