# scripts/components/score_zone.gd
class_name ScoreZone
extends Node2D

signal hit_registered(hit_type: String, lane: int, points: int, multiplier: float)
signal miss_registered(lane: int)
signal combo_updated(combo: int, multiplier: float)
signal stats_updated(stats: Dictionary)

@export var perfect_window: float = 20.0
@export var good_window: float = 45.0
@export var miss_window: float = 80.0
@export var perfect_points: int = 100
@export var good_points: int = 50
@export var combo_multiplier_threshold: int = 10
@export var combo_multiplier_increment: int = 10
@export var max_combo_multiplier: float = 4.0

@export var judge_line_color: Color = Color(0.608, 0.369, 0.985, 1)
@export var judge_line_height: float = 4.0

const MIDI_START_A0: int = 21
const NOTE_NAMES: Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

# References
var notes_container: Node2D = null

# State (scoring)
var score: int = 0
var current_combo: int = 0
var max_combo: int = 0
var perfect_count: int = 0
var good_count: int = 0
var miss_count: int = 0

# ============================================================
# GAME STATE (separate from scoring)
# ============================================================
enum GameState { IDLE, PLAYING, ENDED }
var game_state: int = GameState.IDLE

# Independent gates:
var accept_hits: bool = false
var accept_misses: bool = false

func _ready() -> void:
	queue_redraw()

func set_notes_container(container: Node2D) -> void:
	notes_container = container

func get_judge_y() -> float:
	return global_position.y

# Call these from your game flow
func start_game() -> void:
	game_state = GameState.PLAYING
	accept_hits = true
	accept_misses = true

func end_game() -> void:
	game_state = GameState.ENDED
	# stop affecting score/combo after the song ends
	accept_hits = false
	accept_misses = false

func pause_game() -> void:
	# optional convenience
	accept_hits = false
	accept_misses = false

func resume_game() -> void:
	if game_state == GameState.PLAYING:
		accept_hits = true
		accept_misses = true

# ============================================================
# HIT / MISS EVALUATION
# ============================================================
func evaluate_hit(lane: int) -> Dictionary:
	# Ignore inputs if we aren't accepting hits (ex: after end)
	if not accept_hits:
		return {}

	if notes_container == null:
		return _create_miss_result(lane) # up to you: can also return {} to ignore

	var best: Node2D = null
	var best_dist: float = INF

	for c in notes_container.get_children():
		if c is Node2D:
			var note_lane = c.get("lane")
			if note_lane != null and int(note_lane) == lane:
				var d: float = absf(c.global_position.y - global_position.y)
				if d < best_dist:
					best_dist = d
					best = c

	if best != null:
		if best_dist <= perfect_window:
			var r = _register_hit("perfect", lane, perfect_points)
			best.queue_free()
			return r
		elif best_dist <= good_window:
			var r = _register_hit("good", lane, good_points)
			best.queue_free()
			return r
		else:
			return _create_miss_result(lane)

	return _create_miss_result(lane)

func check_missed_notes() -> void:
	# Stop auto-misses when not accepting misses (ex: ended/paused)
	if not accept_misses:
		return
	if notes_container == null:
		return

	var miss_threshold: float = global_position.y + miss_window

	for child in notes_container.get_children():
		if child is Node2D and child.global_position.y > miss_threshold:
			var lane: int = child.get("lane") if child.get("lane") != null else 0
			_register_miss(lane)
			child.queue_free()

# ============================================================
# SCORING
# ============================================================
func _register_hit(hit_type: String, lane: int, base_points: int) -> Dictionary:
	current_combo += 1
	max_combo = max(max_combo, current_combo)

	if hit_type == "perfect":
		perfect_count += 1
	else:
		good_count += 1

	var multiplier: float = _get_combo_multiplier()
	var final_points: int = int(round(base_points * multiplier))
	score += final_points

	var result := {
		"hit_type": hit_type,
		"lane": lane,
		"points": final_points,
		"multiplier": multiplier,
		"label": _get_lane_label(lane)
	}

	hit_registered.emit(hit_type, lane, final_points, multiplier)
	combo_updated.emit(current_combo, multiplier)
	_emit_stats()
	return result

func _register_miss(lane: int) -> void:
	current_combo = 0
	miss_count += 1

	miss_registered.emit(lane)
	combo_updated.emit(0, 1.0)
	_emit_stats()

func _create_miss_result(lane: int) -> Dictionary:
	# If you want “miss on press” disabled after end, accept_hits already blocks it.
	current_combo = 0
	miss_count += 1

	var result := {
		"hit_type": "miss",
		"lane": lane,
		"points": 0,
		"multiplier": 1.0,
		"label": _get_lane_label(lane)
	}

	miss_registered.emit(lane)
	combo_updated.emit(0, 1.0)
	_emit_stats()
	return result

# FIXED combo multiplier math
func _get_combo_multiplier() -> float:
	if current_combo < combo_multiplier_threshold:
		return 1.0

	var extra: int = current_combo - combo_multiplier_threshold
	# use float division (NOT integer division)
	var steps: float = float(extra) / float(combo_multiplier_increment)
	return minf(1.0 + steps, max_combo_multiplier)

func _emit_stats() -> void:
	stats_updated.emit(get_stats())

func get_stats() -> Dictionary:
	var total := perfect_count + good_count + miss_count
	var accuracy := 0.0
	if total > 0:
		accuracy = (float(perfect_count) + float(good_count) * 0.5) / float(total) * 100.0

	return {
		"score": score,
		"combo": current_combo,
		"max_combo": max_combo,
		"perfect": perfect_count,
		"good": good_count,
		"miss": miss_count,
		"total": total,
		"accuracy": accuracy,
		"rank": _calculate_rank(accuracy)
	}

func reset_stats() -> void:
	score = 0
	current_combo = 0
	max_combo = 0
	perfect_count = 0
	good_count = 0
	miss_count = 0
	_emit_stats()

func _calculate_rank(accuracy: float) -> String:
	if accuracy >= 95.0: return "S"
	elif accuracy >= 90.0: return "A"
	elif accuracy >= 80.0: return "B"
	elif accuracy >= 70.0: return "C"
	elif accuracy >= 60.0: return "D"
	else: return "F"

func _get_lane_label(lane: int) -> String:
	var midi: int = MIDI_START_A0 + lane
	var idx: int = midi % 12
	var octave: int = (midi / 12) - 1
	return "%s%d" % [NOTE_NAMES[idx], octave]

func _draw() -> void:
	var width: float = get_viewport_rect().size.x
	draw_rect(Rect2(-width/2, -judge_line_height/2, width, judge_line_height), judge_line_color)
