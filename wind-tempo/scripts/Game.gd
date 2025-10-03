# scripts/Game.gd
extends Node2D

# ==== Scenes & Spawn ====
@export var note_scene: PackedScene          # drag 'scenes/Note.tscn' here
@export var spawn_interval: float = 1.0      # seconds between notes

# ==== Timing windows (in pixels, distance from JudgeLine) ====
@export var perfect_window: float = 10.0     # <= this = PERFECT
@export var good_window: float = 24.0        # <= this = GOOD, else MISS

# ==== Scoring per window ====
@export var perfect_points: int = 100
@export var good_points: int = 50
@export var miss_points: int = 0             # set negative if you want a penalty

# ==== Nodes ====
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var judge_line: Marker2D = $JudgeLine
@onready var notes_container: Node = $Notes
@onready var feedback_label: Label = $CanvasLayer/FeedbackLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var judge_bar: ColorRect = $JudgeBar

# ==== State ====
var _spawn_timer: float = 0.0
var score: int = 0

func _ready() -> void:
	_spawn_timer = spawn_interval
	feedback_label.visible = false
	# Align the visual judge bar to the judge line (bar is ~4px tall; center it)
	judge_bar.position.y = judge_line.position.y - (judge_bar.size.y * 0.5)
	_update_score_ui()

func _process(delta: float) -> void:
	# Auto-spawn notes
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_spawn_note()

	# Judge on Space
	if Input.is_action_just_pressed("hit"):
		_evaluate_hit()

func _spawn_note() -> void:
	if note_scene == null:
		push_warning("note_scene is not assigned! Drag scenes/Note.tscn into Main's 'note_scene'.")
		return
	var note := note_scene.instantiate() as Node2D
	note.position = spawn_point.global_position
	notes_container.add_child(note)

func _evaluate_hit() -> void:
	# Find the closest note to the judge line (by vertical distance)
	var best: Node2D = null
	var best_dist := INF

	for c in notes_container.get_children():
		if c is Node2D:
			var d: float = abs((c as Node2D).global_position.y - judge_line.global_position.y)
			if d < best_dist:
				best_dist = d
				best = c

	var result := "MISS"
	var points := miss_points
	var color := Color(1.0, 0.3, 0.3)  # red-ish

	if best != null:
		if best_dist <= perfect_window:
			result = "PERFECT"
			points = perfect_points
			color = Color(0.3, 1.0, 0.3)   # green-ish
			best.queue_free()
		elif best_dist <= good_window:
			result = "GOOD"
			points = good_points
			color = Color(1.0, 0.9, 0.3)   # yellow-ish
			best.queue_free()
		else:
			# Far from the line -> MISS (do not remove the note)
			pass
	else:
		# No notes to judge -> MISS
		pass

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
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % score
