# scripts/game_controller.gd
# Main game controller that orchestrates the modular components
extends Node2D

enum GameMode { PRACTICE, SONG }

@export var game_mode: GameMode = GameMode.PRACTICE

# Component references (set via scene or found automatically)
@export var lane_manager: LaneManager
@export var piano_keyboard: PianoKeyboard
@export var note_spawner: NoteSpawner
@export var score_zone: ScoreZone

# UI references
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var accuracy_label: Label = $UI/AccuracyLabel
@onready var stats_panel: Panel = $UI/StatsPanel
@onready var back_button: Button = $UI/StatsPanel/BackButton

# State
var song_finished: bool = false

func _ready() -> void:
	# Auto-find components if not set
	if lane_manager == null:
		lane_manager = _find_child_of_type(LaneManager) as LaneManager
	if piano_keyboard == null:
		piano_keyboard = _find_child_of_type(PianoKeyboard) as PianoKeyboard
	if note_spawner == null:
		note_spawner = _find_child_of_type(NoteSpawner) as NoteSpawner
	if score_zone == null:
		score_zone = _find_child_of_type(ScoreZone) as ScoreZone
	
	# Connect components
	_connect_components()
	
	# Setup UI
	_setup_ui()
	
	# Initialize game mode
	_initialize_game_mode()

func _find_child_of_type(type: Variant) -> Node:
	for child in get_children():
		if is_instance_of(child, type):
			return child
		# Check grandchildren
		for grandchild in child.get_children():
			if is_instance_of(grandchild, type):
				return grandchild
	return null

func _connect_components() -> void:
	# Connect piano keyboard to score zone
	if piano_keyboard and score_zone:
		piano_keyboard.key_pressed.connect(_on_key_pressed)
		piano_keyboard.set_judge_line_y(score_zone.global_position.y)
	
	# Connect note spawner to score zone
	if note_spawner and score_zone:
		score_zone.set_notes_container(note_spawner.get_notes_container())
	
	# Connect score zone events to UI
	if score_zone:
		score_zone.hit_registered.connect(_on_hit_registered)
		score_zone.miss_registered.connect(_on_miss_registered)
		score_zone.combo_updated.connect(_on_combo_updated)
		score_zone.stats_updated.connect(_on_stats_updated)

func _setup_ui() -> void:
	if feedback_label:
		feedback_label.visible = false
	
	if stats_panel:
		stats_panel.visible = false
	
	if back_button:
		back_button.pressed.connect(_on_back_to_menu)
	
	_update_score_ui(0)
	_update_combo_ui(0, 1.0)
	_update_accuracy_ui(0.0)

func _initialize_game_mode() -> void:
	if game_mode == GameMode.PRACTICE:
		if note_spawner:
			note_spawner.set_practice_mode(true)
	else:
		if note_spawner:
			note_spawner.set_practice_mode(false)
		_start_song_mode()

func _start_song_mode() -> void:
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager and song_manager.current_chart:
		# Calculate note speed
		var judge_y := score_zone.global_position.y if score_zone else 500.0
		var spawn_y := note_spawner.spawn_y if note_spawner else -40.0
		var travel_distance: float = judge_y - spawn_y
		var note_speed: float = travel_distance / song_manager.note_travel_time
		
		if note_spawner:
			note_spawner.set_note_speed(note_speed)
			note_spawner.reset_chart_state()
		
		song_manager.start_song()

func _process(delta: float) -> void:
	if song_finished:
		return
	
	if game_mode == GameMode.SONG:
		_process_song_mode(delta)
	
	# Check for missed notes
	if score_zone:
		score_zone.check_missed_notes()

func _process_song_mode(delta: float) -> void:
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager == null or song_manager.current_chart == null:
		return
	
	# Advance song time
	song_manager.advance_time(delta)
	
	# Spawn notes from chart
	if note_spawner:
		note_spawner.spawn_from_chart(
			song_manager.current_chart.notes,
			song_manager.get_current_time(),
			song_manager.note_travel_time
		)
	
	# Check if song is complete
	if song_manager.is_song_complete():
		_on_song_complete()

func _on_key_pressed(lane: int, _midi_note: int) -> void:
	if score_zone:
		score_zone.evaluate_hit(lane)

func _on_hit_registered(hit_type: String, lane: int, points: int, multiplier: float) -> void:
	var label := _get_lane_label(lane)
	var text := "%s (%s)" % [hit_type.to_upper(), label]
	if multiplier > 1.0:
		text += " x%.1f" % multiplier
	
	var color := Color(0.3, 1.0, 0.3) if hit_type == "perfect" else Color(1.0, 0.9, 0.3)
	_show_feedback(text, color)

func _on_miss_registered(lane: int) -> void:
	var label := _get_lane_label(lane)
	_show_feedback("MISS (%s)" % label, Color(1.0, 0.3, 0.3))

func _on_combo_updated(combo: int, multiplier: float) -> void:
	_update_combo_ui(combo, multiplier)

func _on_stats_updated(stats: Dictionary) -> void:
	_update_score_ui(stats.score)
	_update_accuracy_ui(stats.accuracy)

func _show_feedback(text: String, color: Color) -> void:
	if not feedback_label:
		return
	
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.visible = true
	
	var t := create_tween()
	t.tween_property(feedback_label, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.finished.connect(func():
		feedback_label.visible = false
		feedback_label.modulate.a = 1.0
	)

func _update_score_ui(score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % score

func _update_combo_ui(combo: int, multiplier: float) -> void:
	if not combo_label:
		return
	
	if combo > 0:
		combo_label.text = "Combo: %d" % combo
		if multiplier >= 4.0:
			combo_label.modulate = Color(1.0, 0.2, 1.0)
		elif multiplier > 1.0:
			combo_label.modulate = Color(1.0, 0.8, 0.2)
		else:
			combo_label.modulate = Color(1.0, 1.0, 1.0)
	else:
		combo_label.text = ""

func _update_accuracy_ui(accuracy: float) -> void:
	if accuracy_label:
		if accuracy > 0:
			accuracy_label.text = "Accuracy: %.1f%%" % accuracy
		else:
			accuracy_label.text = "Accuracy: --.--%"

func _on_song_complete() -> void:
	song_finished = true
	_show_stats_panel()
	_save_score_to_leaderboard()

	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager and score_zone:
		song_manager.song_ended.emit(score_zone.get_stats())

func _save_score_to_leaderboard() -> void:
	"""Save the current game score to the leaderboard"""
	if not score_zone:
		return
	
	var stats = score_zone.get_stats()
	var song_manager = get_node_or_null("/root/SongManager")
	if not song_manager or not song_manager.current_chart:
		return
	
	var song_name = song_manager.current_chart.title
	var lb_manager = get_node_or_null("/root/LeaderboardManager")
	if lb_manager:
		var score = lb_manager.Score.new()
		score.player_name = "Player"
		score.score = stats.score
		score.accuracy = stats.accuracy
		score.combo = stats.max_combo
		score.rank = stats.rank
		score.timestamp = Time.get_ticks_msec() / 1000.0
		lb_manager.add_score(song_name, score)

func _show_stats_panel() -> void:
	if not stats_panel or not score_zone:
		return
	
	var stats := score_zone.get_stats()
	
	var stats_text := "=== FINAL STATS ===\n\n"
	stats_text += "Rank: %s\n\n" % stats.rank
	stats_text += "Score: %d\n\n" % stats.score
	stats_text += "Perfect: %d\n" % stats.perfect
	stats_text += "Good: %d\n" % stats.good
	stats_text += "Miss: %d\n" % stats.miss
	stats_text += "Total Notes: %d\n\n" % stats.total
	stats_text += "Accuracy: %.2f%%\n\n" % stats.accuracy
	stats_text += "Max Combo: %d" % stats.max_combo
	
	var stats_label: Label = null
	for child in stats_panel.get_children():
		if child is Label:
			stats_label = child
			break
	
	if stats_label:
		stats_label.text = stats_text
	
	stats_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_to_menu()

func _on_back_to_menu() -> void:
	var song_manager = get_node_or_null("/root/SongManager")
	if song_manager:
		song_manager.stop_song()
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")

func _get_lane_label(lane: int) -> String:
	const MIDI_START_A0: int = 21
	const NOTE_NAMES: Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
	var midi: int = MIDI_START_A0 + lane
	var idx: int = midi % 12
	var octave: int = (midi / 12) - 1
	return "%s%d" % [NOTE_NAMES[idx], octave]

