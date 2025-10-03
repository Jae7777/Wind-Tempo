# scripts/Game.gd
extends Node2D

@export var note_scene: PackedScene          # drag 'scenes/Note.tscn' here in the Inspector
@export var spawn_interval: float = 1.0      # seconds between notes
@export var hit_window: float = 24.0         # pixels tolerance around the judgment line

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var judge_line: Marker2D = $JudgeLine
@onready var notes_container: Node = $Notes
@onready var feedback_label: Label = $CanvasLayer/FeedbackLabel
@onready var judge_bar: ColorRect = $JudgeBar

var _spawn_timer: float = 0.0

func _ready() -> void:
	_spawn_timer = spawn_interval
	# Align the bar visually to the judge line (center the 4px bar on the line)
	judge_bar.position.y = judge_line.position.y - (judge_bar.size.y * 0.5)
	feedback_label.visible = false

func _process(delta: float) -> void:
	# 1) Auto-spawn notes
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_spawn_note()

	# 2) Input: judge on Space
	if Input.is_action_just_pressed("hit"):
		_evaluate_hit()

func _spawn_note() -> void:
	if note_scene == null:
		push_warning("note_scene is not assigned! Drag scenes/Note.tscn into Main's 'note_scene' export.")
		return
	var note := note_scene.instantiate() as Node2D
	note.position = spawn_point.global_position
	notes_container.add_child(note)

func _evaluate_hit() -> void:
	var best: Node2D = null
	var best_dist := INF

	for c in notes_container.get_children():
		if c is Node2D:
			var d: float = abs((c as Node2D).global_position.y - judge_line.global_position.y)
			if d < best_dist:
				best_dist = d
				best = c

	if best != null and best_dist <= hit_window:
		# HIT!
		_show_feedback("HIT!", Color(0.3, 1.0, 0.3))
		best.queue_free()
	else:
		# MISS
		_show_feedback("MISS", Color(1.0, 0.3, 0.3))

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.visible = true

	var t := create_tween()
	# Fade out quickly
	t.tween_property(feedback_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.finished.connect(func():
		feedback_label.visible = false
		feedback_label.modulate.a = 1.0
	)
