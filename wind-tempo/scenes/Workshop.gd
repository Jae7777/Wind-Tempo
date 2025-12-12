# scenes/Workshop.gd
# Track editor for creating custom Wind Tempo tracks
extends Control

# UI References
@onready var track_title_edit: LineEdit = $VBoxContainer/TopBar/TitleEdit
@onready var bpm_spinbox: SpinBox = $VBoxContainer/TopBar/BPMSpinBox
@onready var timeline_scroll: ScrollContainer = $VBoxContainer/HSplitContainer/PianoRollContainer/TimelineScroll
@onready var piano_roll: Control = $VBoxContainer/HSplitContainer/PianoRollContainer/TimelineScroll/PianoRoll
@onready var track_list: ItemList = $VBoxContainer/HSplitContainer/SidePanel/TrackList
@onready var note_count_label: Label = $VBoxContainer/BottomBar/NoteCountLabel
@onready var duration_label: Label = $VBoxContainer/BottomBar/DurationLabel
@onready var status_label: Label = $VBoxContainer/BottomBar/StatusLabel
@onready var play_button: Button = $VBoxContainer/TopBar/PlayButton
@onready var stop_button: Button = $VBoxContainer/TopBar/StopButton
@onready var save_button: Button = $VBoxContainer/TopBar/SaveButton
@onready var back_button: Button = $VBoxContainer/TopBar/BackButton
@onready var new_track_button: Button = $VBoxContainer/HSplitContainer/SidePanel/NewTrackButton

# Track data
var current_track: TrackFormat.Track = null
var is_modified: bool = false
var is_playing: bool = false
var playback_time: float = 0.0

# Editor settings
var grid_snap: bool = true
var grid_division: int = 4  # Notes per beat
var zoom_x: float = 100.0   # Pixels per second
var zoom_y: float = 12.0    # Pixels per key

# Selection
var selected_notes: Array[TrackFormat.TrackNote] = []

# Piano dimensions
const MIDI_MIN: int = 21   # A0
const MIDI_MAX: int = 108  # C8
const KEY_COUNT: int = 88

# Prevent programmatic UI updates from pushing undo actions
var _suppress_ui_signals: bool = false

# ============================================================
# UNDO / REDO
# ============================================================
const UNDO_LIMIT: int = 200

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _next_note_uid: int = 1

func _reset_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_next_note_uid = 1

func _push_action(action: Dictionary) -> void:
	_undo_stack.append(action)
	if _undo_stack.size() > UNDO_LIMIT:
		_undo_stack.pop_front()
	_redo_stack.clear()

func _undo() -> void:
	if _undo_stack.is_empty():
		return
	var action: Dictionary = _undo_stack.pop_back() as Dictionary
	_apply_action(action, true) # undo = true
	_redo_stack.append(action)

func _redo() -> void:
	if _redo_stack.is_empty():
		return
	var action: Dictionary = _redo_stack.pop_back() as Dictionary
	_apply_action(action, false) # undo = false
	_undo_stack.append(action)

func _apply_action(action: Dictionary, undo: bool) -> void:
	if not current_track:
		return

	var t: String = str(action.get("type", ""))

	match t:
		"add_notes":
			var notes: Array = action.get("notes", []) as Array
			if undo:
				_remove_notes_by_uid_or_data(notes)
			else:
				_add_notes_from_data(notes)

		"remove_notes":
			var notes: Array = action.get("notes", []) as Array
			if undo:
				_add_notes_from_data(notes)
			else:
				_remove_notes_by_uid_or_data(notes)

		"set_title":
			var old_v: String = str(action.get("old", ""))
			var new_v: String = str(action.get("new", ""))
			current_track.metadata.title = old_v if undo else new_v

		"set_bpm":
			var old_b: float = float(action.get("old", 120.0))
			var new_b: float = float(action.get("new", 120.0))
			current_track.settings.bpm = old_b if undo else new_b

		_:
			return

	is_modified = true
	_update_ui()
	if piano_roll:
		piano_roll.queue_redraw()

func _note_to_data(note: TrackFormat.TrackNote) -> Dictionary:
	var uid := -1
	if note.has_meta("uid"):
		uid = int(note.get_meta("uid"))
	return {
		"uid": uid,
		"time": float(note.time),
		"midi": int(note.note),
		"duration": float(note.duration)
	}

func _ensure_note_uid(note: TrackFormat.TrackNote, desired_uid: int = -1) -> int:
	var uid := desired_uid
	if uid < 0:
		uid = _next_note_uid
		_next_note_uid += 1
	note.set_meta("uid", uid)
	return uid

func _find_note_by_uid(uid: int) -> TrackFormat.TrackNote:
	if uid < 0 or not current_track:
		return null
	for n in current_track.notes:
		if n.has_meta("uid") and int(n.get_meta("uid")) == uid:
			return n
	return null

func _find_note_by_data(data: Dictionary) -> TrackFormat.TrackNote:
	if not current_track:
		return null

	var t := float(data.get("time", 0.0))
	var m := int(data.get("midi", 0))
	var d := float(data.get("duration", 0.0))

	for i in range(current_track.notes.size() - 1, -1, -1):
		var n: TrackFormat.TrackNote = current_track.notes[i]
		if int(n.note) == m and absf(float(n.time) - t) < 0.0005 and absf(float(n.duration) - d) < 0.0005:
			return n
	return null

func _add_notes_from_data(notes_data: Array) -> void:
	for item in notes_data:
		var data: Dictionary = item as Dictionary
		var time := float(data.get("time", 0.0))
		var midi := int(data.get("midi", MIDI_MIN))
		var dur  := float(data.get("duration", 0.25))
		var uid  := int(data.get("uid", -1))

		current_track.add_note(time, midi, dur)

		var created := _find_note_by_data({"time": time, "midi": midi, "duration": dur})
		if created:
			_ensure_note_uid(created, uid)

func _remove_notes_by_uid_or_data(notes_data: Array) -> void:
	for item in notes_data:
		var data: Dictionary = item as Dictionary
		var uid := int(data.get("uid", -1))
		var n := _find_note_by_uid(uid) if uid >= 0 else null
		if n == null:
			n = _find_note_by_data(data)
		if n != null:
			current_track.remove_note(n)
			selected_notes.erase(n)

func _assign_uids_to_all_notes() -> void:
	if not current_track:
		return
	var max_uid := 0
	for n in current_track.notes:
		if n.has_meta("uid"):
			max_uid = max(max_uid, int(n.get_meta("uid")))
		else:
			var uid := _ensure_note_uid(n)
			max_uid = max(max_uid, uid)
	_next_note_uid = max_uid + 1

# ============================================================
# LIFECYCLE / UI
# ============================================================

func _ready() -> void:
	_new_track()

	track_title_edit.text_changed.connect(_on_title_changed)
	bpm_spinbox.value_changed.connect(_on_bpm_changed)
	play_button.pressed.connect(_on_play_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	save_button.pressed.connect(_save_track)
	back_button.pressed.connect(_on_back_pressed)
	new_track_button.pressed.connect(_new_track)
	track_list.item_activated.connect(_on_track_selected)

	if piano_roll:
		piano_roll.gui_input.connect(_on_piano_roll_input)

	_refresh_track_list()
	_update_ui()

func _on_track_selected(index: int) -> void:
	if index == 0:
		_new_track()
	else:
		var tracks := _scan_for_tracks()
		if index - 1 < tracks.size():
			_load_track(tracks[index - 1]["path"])

func _process(delta: float) -> void:
	if is_playing:
		playback_time += delta
		if current_track and playback_time > current_track.get_duration() + 1.0:
			_stop_playback()
		piano_roll.queue_redraw()

func _new_track() -> void:
	current_track = TrackFormat.create_empty_track("New Track")
	is_modified = false
	selected_notes.clear()
	_reset_history()
	_assign_uids_to_all_notes()
	_update_ui()
	if piano_roll:
		piano_roll.queue_redraw()

func _update_ui() -> void:
	_suppress_ui_signals = true

	if current_track:
		track_title_edit.text = current_track.metadata.title
		bpm_spinbox.value = current_track.settings.bpm
		note_count_label.text = "Notes: %d" % current_track.get_note_count()
		duration_label.text = "Duration: %.1fs" % current_track.get_duration()

	var modified_text := " *" if is_modified else ""
	status_label.text = "Ready" + modified_text

	_suppress_ui_signals = false

func _on_title_changed(new_text: String) -> void:
	if _suppress_ui_signals:
		return
	if current_track:
		var old_text := current_track.metadata.title
		if new_text == old_text:
			return
		current_track.metadata.title = new_text
		_push_action({"type": "set_title", "old": old_text, "new": new_text})
		is_modified = true
		_update_ui()

func _on_bpm_changed(value: float) -> void:
	if _suppress_ui_signals:
		return
	if current_track:
		var old_bpm := float(current_track.settings.bpm)
		var new_bpm := float(value)
		if is_equal_approx(old_bpm, new_bpm):
			return
		current_track.settings.bpm = new_bpm
		_push_action({"type": "set_bpm", "old": old_bpm, "new": new_bpm})
		is_modified = true
		_update_ui()

func _on_play_pressed() -> void:
	if current_track and current_track.get_note_count() > 0:
		_start_playback()

func _on_stop_pressed() -> void:
	_stop_playback()

func _start_playback() -> void:
	is_playing = true
	playback_time = 0.0
	play_button.disabled = true
	stop_button.disabled = false
	status_label.text = "Playing..."

func _stop_playback() -> void:
	is_playing = false
	playback_time = 0.0
	play_button.disabled = false
	stop_button.disabled = true
	status_label.text = "Ready"
	piano_roll.queue_redraw()

# ============================================================
# INPUT / NOTE EDITING
# ============================================================

func _on_piano_roll_input(event: InputEvent) -> void:
	if not current_track:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var pos := mouse_event.position

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var time := pos.x / zoom_x
			var midi_note := MIDI_MAX - int(pos.y / zoom_y)

			if grid_snap:
				var beat_duration := 60.0 / current_track.settings.bpm
				var grid_duration := beat_duration / grid_division
				time = roundf(time / grid_duration) * grid_duration

			var clicked_note := _get_note_at_position(pos)
			if clicked_note:
				if Input.is_key_pressed(KEY_CTRL):
					if clicked_note in selected_notes:
						selected_notes.erase(clicked_note)
					else:
						selected_notes.append(clicked_note)
				else:
					selected_notes = [clicked_note]
			else:
				if midi_note >= MIDI_MIN and midi_note <= MIDI_MAX:
					var beat_duration := 60.0 / current_track.settings.bpm
					var dur := beat_duration / grid_division

					current_track.add_note(time, midi_note, dur)

					var created := _find_note_by_data({"time": time, "midi": midi_note, "duration": dur})
					if created:
						var uid := _ensure_note_uid(created)
						_push_action({
							"type": "add_notes",
							"notes": [{
								"uid": uid,
								"time": time,
								"midi": midi_note,
								"duration": dur
							}]
						})

					is_modified = true
					_update_ui()

			piano_roll.queue_redraw()

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			var clicked_note := _get_note_at_position(pos)
			if clicked_note:
				_ensure_note_uid(clicked_note)
				var data := _note_to_data(clicked_note)
				current_track.remove_note(clicked_note)
				selected_notes.erase(clicked_note)
				_push_action({"type": "remove_notes", "notes": [data]})
				is_modified = true
				_update_ui()
				piano_roll.queue_redraw()

func _get_note_at_position(pos: Vector2) -> TrackFormat.TrackNote:
	if not current_track:
		return null

	for note in current_track.notes:
		var note_x := note.time * zoom_x
		var note_y := (MIDI_MAX - note.note) * zoom_y
		var note_w := maxf(note.duration * zoom_x, 10.0)
		var note_h := zoom_y

		if pos.x >= note_x and pos.x <= note_x + note_w and pos.y >= note_y and pos.y <= note_y + note_h:
			return note

	return null

# ============================================================
# TRACK LIST / SAVE / LOAD
# ============================================================

func _refresh_track_list() -> void:
	track_list.clear()
	track_list.add_item("+ New Track")

	var tracks := _scan_for_tracks()
	for track_info in tracks:
		track_list.add_item(track_info["name"])

func _scan_for_tracks() -> Array[Dictionary]:
	var tracks: Array[Dictionary] = []
	var dir := DirAccess.open("user://tracks/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".wtrack"):
				tracks.append({
					"name": file_name.get_basename(),
					"path": "user://tracks/".path_join(file_name)
				})
			file_name = dir.get_next()
		dir.list_dir_end()
	return tracks

func _save_track() -> void:
	if not current_track:
		return

	var path := "user://tracks/%s.wtrack" % current_track.metadata.title.to_snake_case()
	var error := TrackFormat.save_track(current_track, path)

	if error == OK:
		is_modified = false
		status_label.text = "Saved!"
		_refresh_track_list()
	else:
		status_label.text = "Save failed!"

func _load_track(path: String) -> void:
	var track := TrackFormat.load_track(path)
	if track:
		current_track = track
		selected_notes.clear()
		is_modified = false
		_reset_history()
		_assign_uids_to_all_notes()
		_update_ui()
		piano_roll.queue_redraw()

# ============================================================
# KEYBOARD SHORTCUTS
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey

		if key_event.ctrl_pressed:
			match key_event.keycode:
				KEY_S:
					_save_track()
				KEY_N:
					_new_track()
				KEY_Z:
					if key_event.shift_pressed:
						_redo()
					else:
						_undo()
				KEY_Y:
					_redo()
				KEY_DELETE, KEY_BACKSPACE:
					_delete_selected_notes()

		if key_event.keycode == KEY_ESCAPE:
			_on_back_pressed()

		if key_event.keycode == KEY_SPACE:
			if is_playing:
				_stop_playback()
			else:
				_start_playback()

func _delete_selected_notes() -> void:
	if not current_track or selected_notes.is_empty():
		return

	var removed: Array = []
	for note in selected_notes:
		_ensure_note_uid(note)
		removed.append(_note_to_data(note))

	for data_item in removed:
		var data: Dictionary = data_item as Dictionary
		var n := _find_note_by_uid(int(data["uid"]))
		if n != null:
			current_track.remove_note(n)

	selected_notes.clear()
	_push_action({"type": "remove_notes", "notes": removed})

	is_modified = true
	_update_ui()
	piano_roll.queue_redraw()

func _on_back_pressed() -> void:
	if is_modified:
		# TODO: Show confirmation dialog
		pass
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ============================================================
# PIANO ROLL DRAWING
# ============================================================

func draw_piano_roll(canvas: CanvasItem) -> void:
	if not current_track:
		return

	var size := piano_roll.size
	var bg_color := Color(0.12, 0.12, 0.15)
	var grid_color := Color(0.2, 0.2, 0.25)
	var beat_color := Color(0.3, 0.3, 0.35)
	var white_key_bg := Color(0.15, 0.15, 0.18)
	var black_key_bg := Color(0.1, 0.1, 0.12)

	canvas.draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

	for i in range(KEY_COUNT):
		var midi_note := MIDI_MAX - i
		var y := i * zoom_y
		var is_black := _is_black_key(midi_note)
		var key_color := black_key_bg if is_black else white_key_bg
		canvas.draw_rect(Rect2(0, y, size.x, zoom_y), key_color, true)
		canvas.draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

	var beat_duration := 60.0 / current_track.settings.bpm
	var visible_duration := size.x / zoom_x
	var beat := 0
	var time := 0.0

	while time < visible_duration:
		var x := time * zoom_x
		var is_measure := (beat % current_track.settings.time_signature[0]) == 0
		var line_color := beat_color if is_measure else grid_color
		var line_width := 2.0 if is_measure else 1.0
		canvas.draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, line_width)
		beat += 1
		time = beat * beat_duration

	for note in current_track.notes:
		var note_x := note.time * zoom_x
		var note_y := (MIDI_MAX - note.note) * zoom_y
		var note_w := maxf(note.duration * zoom_x, 8.0)
		var note_h := zoom_y - 2

		var is_selected := note in selected_notes
		var hue := float(note.note - MIDI_MIN) / float(KEY_COUNT) * 0.8
		var note_color := Color.from_hsv(hue, 0.7, 0.9)
		if is_selected:
			note_color = Color(1.0, 1.0, 0.5)

		canvas.draw_rect(Rect2(note_x, note_y + 1, note_w, note_h), note_color, true)
		canvas.draw_rect(Rect2(note_x, note_y + 1, note_w, note_h), note_color.darkened(0.3), false, 1.0)

	if is_playing:
		var cursor_x := playback_time * zoom_x
		canvas.draw_line(Vector2(cursor_x, 0), Vector2(cursor_x, size.y), Color(1, 0.3, 0.3), 2.0)

func _is_black_key(midi_note: int) -> bool:
	var note_in_octave := midi_note % 12
	return note_in_octave in [1, 3, 6, 8, 10]
