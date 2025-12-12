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

# ============================================================
# EDITOR SETTINGS
# ============================================================
var grid_snap: bool = true
var grid_division: int = 4               # subdivisions per beat
var zoom_x: float = 100.0                # pixels per second
var zoom_y: float = 12.0                 # pixels per key

const GRID_OPTIONS: Array[int] = [1, 2, 3, 4, 6, 8, 12, 16]
var _grid_option_index: int = 3          # default -> 4

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
	_apply_action(action, true)
	_redo_stack.append(action)

func _redo() -> void:
	if _redo_stack.is_empty():
		return
	var action: Dictionary = _redo_stack.pop_back() as Dictionary
	_apply_action(action, false)
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
			var notes2: Array = action.get("notes", []) as Array
			if undo:
				_add_notes_from_data(notes2)
			else:
				_remove_notes_by_uid_or_data(notes2)

		"transform_notes":
			var before: Array = action.get("before", []) as Array
			var after: Array = action.get("after", []) as Array
			_set_notes_from_data(before if undo else after)

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
	var uid: int = -1
	if note.has_meta("uid"):
		uid = int(note.get_meta("uid"))
	return {
		"uid": uid,
		"time": float(note.time),
		"midi": int(note.note),
		"duration": float(note.duration)
	}

func _ensure_note_uid(note: TrackFormat.TrackNote, desired_uid: int = -1) -> int:
	var uid: int = desired_uid
	if uid < 0:
		uid = _next_note_uid
		_next_note_uid += 1
	note.set_meta("uid", uid)
	return uid

func _find_note_by_uid(uid: int) -> TrackFormat.TrackNote:
	if uid < 0 or not current_track:
		return null
	for raw in current_track.notes:
		var n: TrackFormat.TrackNote = raw
		if n.has_meta("uid") and int(n.get_meta("uid")) == uid:
			return n
	return null

func _find_note_by_data(data: Dictionary) -> TrackFormat.TrackNote:
	if not current_track:
		return null

	var t: float = float(data.get("time", 0.0))
	var m: int = int(data.get("midi", 0))
	var d: float = float(data.get("duration", 0.0))

	for i in range(current_track.notes.size() - 1, -1, -1):
		var n: TrackFormat.TrackNote = current_track.notes[i]
		if int(n.note) == m and absf(float(n.time) - t) < 0.0005 and absf(float(n.duration) - d) < 0.0005:
			return n
	return null

func _add_notes_from_data(notes_data: Array) -> void:
	for item in notes_data:
		var data: Dictionary = item as Dictionary
		var time: float = float(data.get("time", 0.0))
		var midi: int = int(data.get("midi", MIDI_MIN))
		var dur: float = float(data.get("duration", 0.25))
		var uid: int = int(data.get("uid", -1))

		current_track.add_note(time, midi, dur)

		var created: TrackFormat.TrackNote = _find_note_by_data({"time": time, "midi": midi, "duration": dur})
		if created:
			_ensure_note_uid(created, uid)

func _remove_notes_by_uid_or_data(notes_data: Array) -> void:
	for item in notes_data:
		var data: Dictionary = item as Dictionary
		var uid: int = int(data.get("uid", -1))
		var n: TrackFormat.TrackNote = _find_note_by_uid(uid) if uid >= 0 else null
		if n == null:
			n = _find_note_by_data(data)
		if n != null:
			current_track.remove_note(n)
			selected_notes.erase(n)

func _set_notes_from_data(notes_data: Array) -> void:
	for item in notes_data:
		var data: Dictionary = item as Dictionary
		var uid: int = int(data.get("uid", -1))
		var n: TrackFormat.TrackNote = _find_note_by_uid(uid) if uid >= 0 else null
		if n == null:
			n = _find_note_by_data(data)
		if n != null:
			_ensure_note_uid(n, uid)
			n.time = float(data.get("time", 0.0))
			n.note = int(data.get("midi", MIDI_MIN))
			n.duration = float(data.get("duration", 0.25))

func _assign_uids_to_all_notes() -> void:
	if not current_track:
		return
	var max_uid: int = 0
	for raw in current_track.notes:
		var n: TrackFormat.TrackNote = raw
		if n.has_meta("uid"):
			max_uid = max(max_uid, int(n.get_meta("uid")))
		else:
			var new_uid: int = _ensure_note_uid(n)
			max_uid = max(max_uid, new_uid)
	_next_note_uid = max_uid + 1

# ============================================================
# MUSICAL GRID + SNAPPING
# ============================================================
func _get_time_signature() -> Dictionary:
	var beats_per_measure: int = 4
	var denom: int = 4

	if current_track != null and current_track.settings != null and ("time_signature" in current_track.settings):
		var ts: Variant = current_track.settings.time_signature

		if ts is Array:
			var a: Array = ts as Array
			if a.size() >= 2:
				beats_per_measure = int(a[0])
				denom = int(a[1])
		elif ts is PackedInt32Array:
			var p: PackedInt32Array = ts as PackedInt32Array
			if p.size() >= 2:
				beats_per_measure = int(p[0])
				denom = int(p[1])

	beats_per_measure = max(1, beats_per_measure)
	denom = max(1, denom)
	return {"beats": beats_per_measure, "denom": denom}

func _get_beat_duration() -> float:
	# BPM is quarter-notes per minute; convert "beat" based on time signature denominator
	if current_track == null:
		return 0.5
	var bpm: float = maxf(1.0, float(current_track.settings.bpm))
	var ts: Dictionary = _get_time_signature()
	var denom: int = int(ts["denom"])
	var quarter_duration: float = 60.0 / bpm
	return quarter_duration * (4.0 / float(denom))

func _get_grid_duration() -> float:
	var beat_d: float = _get_beat_duration()
	var div: int = max(1, grid_division)
	return beat_d / float(div)

func _snap_time(t: float) -> float:
	if not grid_snap or Input.is_key_pressed(KEY_SHIFT):
		return t
	var g: float = _get_grid_duration()
	if g <= 0.0:
		return t
	return roundf(t / g) * g

func _snap_duration(d: float) -> float:
	if Input.is_key_pressed(KEY_SHIFT):
		return maxf(0.05, d)
	if not grid_snap:
		return maxf(0.05, d)
	var g: float = _get_grid_duration()
	if g <= 0.0:
		return maxf(0.05, d)
	return maxf(g, roundf(d / g) * g)

func _step_grid_division(dir: int) -> void:
	_grid_option_index = clamp(_grid_option_index + dir, 0, GRID_OPTIONS.size() - 1)
	grid_division = GRID_OPTIONS[_grid_option_index]
	if piano_roll:
		piano_roll.queue_redraw()

func _sync_grid_index_from_division() -> void:
	var idx: int = GRID_OPTIONS.find(grid_division)
	if idx == -1:
		_grid_option_index = 3
		grid_division = GRID_OPTIONS[_grid_option_index]
	else:
		_grid_option_index = idx

# ============================================================
# DRAG MOVE / RESIZE
# ============================================================
enum DragMode { NONE, MOVE, RESIZE }
const DRAG_START_DISTANCE: float = 3.0
const RESIZE_HANDLE_PX: float = 6.0

var _mouse_down_left: bool = false
var _dragging: bool = false
var _drag_mode: int = DragMode.NONE
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_anchor_note: TrackFormat.TrackNote = null
var _drag_original_notes: Array[Dictionary] = []  # before-data for affected notes

func _is_on_resize_handle(pos: Vector2, note: TrackFormat.TrackNote) -> bool:
	var note_x: float = float(note.time) * zoom_x
	var note_y: float = float(MIDI_MAX - int(note.note)) * zoom_y
	var note_w: float = maxf(float(note.duration) * zoom_x, 10.0)
	var note_h: float = zoom_y
	var right_x: float = note_x + note_w
	var on_y: bool = (pos.y >= note_y) and (pos.y <= note_y + note_h)
	var on_x: bool = absf(pos.x - right_x) <= RESIZE_HANDLE_PX
	return on_x and on_y

func _start_drag(anchor: TrackFormat.TrackNote, mode: int) -> void:
	_drag_anchor_note = anchor
	_drag_mode = mode
	_dragging = false
	_drag_original_notes.clear()

	if _drag_mode == DragMode.RESIZE:
		_ensure_note_uid(anchor)
		_drag_original_notes.append(_note_to_data(anchor))
	else:
		if selected_notes.is_empty():
			selected_notes = [anchor]
		for n in selected_notes:
			_ensure_note_uid(n)
			_drag_original_notes.append(_note_to_data(n))

func _update_drag(pos: Vector2) -> void:
	if current_track == null or _drag_anchor_note == null:
		return

	if not _dragging:
		if pos.distance_to(_drag_start_pos) < DRAG_START_DISTANCE:
			return
		_dragging = true
		is_modified = true
		_update_ui()

	if _drag_mode == DragMode.MOVE:
		var delta_time: float = (pos.x - _drag_start_pos.x) / zoom_x
		if grid_snap and not Input.is_key_pressed(KEY_SHIFT):
			var g: float = _get_grid_duration()
			if g > 0.0:
				delta_time = roundf(delta_time / g) * g

		var delta_rows: int = int(round((pos.y - _drag_start_pos.y) / zoom_y))

		for item in _drag_original_notes:
			var data: Dictionary = item as Dictionary
			var uid: int = int(data.get("uid", -1))
			var n: TrackFormat.TrackNote = _find_note_by_uid(uid)
			if n == null:
				continue

			var new_time: float = maxf(0.0, float(data.get("time", 0.0)) + delta_time)
			new_time = _snap_time(new_time)

			var new_midi: int = int(data.get("midi", MIDI_MIN)) - delta_rows
			new_midi = clamp(new_midi, MIDI_MIN, MIDI_MAX)

			n.time = new_time
			n.note = new_midi

	elif _drag_mode == DragMode.RESIZE:
		if _drag_original_notes.is_empty():
			return
		var data0: Dictionary = _drag_original_notes[0] as Dictionary
		var uid0: int = int(data0.get("uid", -1))
		var n0: TrackFormat.TrackNote = _find_note_by_uid(uid0)
		if n0 == null:
			return

		var base_dur: float = float(data0.get("duration", 0.25))
		var delta_dur: float = (pos.x - _drag_start_pos.x) / zoom_x
		var new_dur: float = _snap_duration(base_dur + delta_dur)
		n0.duration = new_dur

	if piano_roll:
		piano_roll.queue_redraw()

func _notes_data_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		var da: Dictionary = a[i] as Dictionary
		var db: Dictionary = b[i] as Dictionary
		if int(da.get("uid", -1)) != int(db.get("uid", -1)):
			return false
		if absf(float(da.get("time", 0.0)) - float(db.get("time", 0.0))) > 0.0005:
			return false
		if int(da.get("midi", 0)) != int(db.get("midi", 0)):
			return false
		if absf(float(da.get("duration", 0.0)) - float(db.get("duration", 0.0))) > 0.0005:
			return false
	return true

func _finish_drag() -> void:
	if current_track == null or _drag_anchor_note == null:
		return
	if not _dragging:
		return

	var after: Array[Dictionary] = []
	for item in _drag_original_notes:
		var before_d: Dictionary = item as Dictionary
		var uid: int = int(before_d.get("uid", -1))
		var n: TrackFormat.TrackNote = _find_note_by_uid(uid)
		if n != null:
			after.append(_note_to_data(n))

	if not _notes_data_equal(_drag_original_notes, after):
		_push_action({
			"type": "transform_notes",
			"before": _drag_original_notes.duplicate(true),
			"after": after
		})

	_update_ui()
	if piano_roll:
		piano_roll.queue_redraw()

func _reset_drag_state() -> void:
	_mouse_down_left = false
	_dragging = false
	_drag_mode = DragMode.NONE
	_drag_anchor_note = null
	_drag_original_notes.clear()

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
		var tracks: Array[Dictionary] = _scan_for_tracks()
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
	_reset_drag_state()
	_sync_grid_index_from_division()
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

	var modified_text: String = " *" if is_modified else ""
	status_label.text = "Ready" + modified_text

	_suppress_ui_signals = false

func _on_title_changed(new_text: String) -> void:
	if _suppress_ui_signals:
		return
	if current_track:
		var old_text: String = current_track.metadata.title
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
		var old_bpm: float = float(current_track.settings.bpm)
		var new_bpm: float = float(value)
		if is_equal_approx(old_bpm, new_bpm):
			return
		current_track.settings.bpm = new_bpm
		_push_action({"type": "set_bpm", "old": old_bpm, "new": new_bpm})
		is_modified = true
		_update_ui()
		if piano_roll:
			piano_roll.queue_redraw()

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
	if current_track == null:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		var pos: Vector2 = mb.position

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_down_left = true
				_drag_start_pos = pos
				_dragging = false

				var clicked_note: TrackFormat.TrackNote = _get_note_at_position(pos)

				# Click on note: select + prep drag
				if clicked_note != null:
					if mb.ctrl_pressed:
						if clicked_note in selected_notes:
							selected_notes.erase(clicked_note)
							_reset_drag_state()
							if piano_roll:
								piano_roll.queue_redraw()
							return
						else:
							selected_notes.append(clicked_note)
					else:
						if not (clicked_note in selected_notes):
							selected_notes = [clicked_note]

					var mode: int = DragMode.MOVE
					if _is_on_resize_handle(pos, clicked_note):
						mode = DragMode.RESIZE
					_start_drag(clicked_note, mode)

					if piano_roll:
						piano_roll.queue_redraw()
					return

				# Click empty: add note (undoable)
				var time: float = _snap_time(pos.x / zoom_x)
				var midi_note: int = MIDI_MAX - int(pos.y / zoom_y)

				if midi_note >= MIDI_MIN and midi_note <= MIDI_MAX:
					var dur: float = _snap_duration(_get_grid_duration())

					current_track.add_note(time, midi_note, dur)

					var created: TrackFormat.TrackNote = _find_note_by_data({"time": time, "midi": midi_note, "duration": dur})
					if created:
						var uid: int = _ensure_note_uid(created)
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
					selected_notes.clear()
					_update_ui()
					if piano_roll:
						piano_roll.queue_redraw()

			else:
				# release left
				if _mouse_down_left:
					_finish_drag()
				_reset_drag_state()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var clicked_note2: TrackFormat.TrackNote = _get_note_at_position(pos)
			if clicked_note2:
				_ensure_note_uid(clicked_note2)
				var data: Dictionary = _note_to_data(clicked_note2)
				current_track.remove_note(clicked_note2)
				selected_notes.erase(clicked_note2)
				_push_action({"type": "remove_notes", "notes": [data]})
				is_modified = true
				_update_ui()
				if piano_roll:
					piano_roll.queue_redraw()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _mouse_down_left and _drag_anchor_note != null:
			_update_drag(mm.position)

func _get_note_at_position(pos: Vector2) -> TrackFormat.TrackNote:
	if current_track == null:
		return null

	for i in range(current_track.notes.size() - 1, -1, -1):
		var note: TrackFormat.TrackNote = current_track.notes[i]
		var note_x: float = float(note.time) * zoom_x
		var note_y: float = float(MIDI_MAX - int(note.note)) * zoom_y
		var note_w: float = maxf(float(note.duration) * zoom_x, 10.0)
		var note_h: float = zoom_y

		if pos.x >= note_x and pos.x <= note_x + note_w and pos.y >= note_y and pos.y <= note_y + note_h:
			return note

	return null

# ============================================================
# TRACK LIST / SAVE / LOAD
# ============================================================
func _refresh_track_list() -> void:
	track_list.clear()
	track_list.add_item("+ New Track")

	var tracks: Array[Dictionary] = _scan_for_tracks()
	for track_info in tracks:
		track_list.add_item(track_info["name"])

func _scan_for_tracks() -> Array[Dictionary]:
	var tracks: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open("user://tracks/")
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
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
	if current_track == null:
		return

	var path: String = "user://tracks/%s.wtrack" % current_track.metadata.title.to_snake_case()
	var error: int = TrackFormat.save_track(current_track, path)

	if error == OK:
		is_modified = false
		status_label.text = "Saved!"
		_refresh_track_list()
	else:
		status_label.text = "Save failed!"

func _load_track(path: String) -> void:
	var track: TrackFormat.Track = TrackFormat.load_track(path)
	if track:
		current_track = track
		selected_notes.clear()
		is_modified = false
		_reset_history()
		_assign_uids_to_all_notes()
		_reset_drag_state()
		_sync_grid_index_from_division()
		_update_ui()
		if piano_roll:
			piano_roll.queue_redraw()

# ============================================================
# KEYBOARD SHORTCUTS
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.ctrl_pressed:
			match key_event.keycode:
				KEY_S: _save_track()
				KEY_N: _new_track()
				KEY_Z:
					if key_event.shift_pressed:
						_redo()
					else:
						_undo()
				KEY_Y: _redo()
				KEY_DELETE, KEY_BACKSPACE:
					_delete_selected_notes()

		match key_event.keycode:
			KEY_G:
				grid_snap = not grid_snap
				if piano_roll:
					piano_roll.queue_redraw()
			KEY_BRACKETLEFT:
				_step_grid_division(-1)
			KEY_BRACKETRIGHT:
				_step_grid_division(1)

		if key_event.keycode == KEY_ESCAPE:
			_on_back_pressed()

		if key_event.keycode == KEY_SPACE:
			if is_playing:
				_stop_playback()
			else:
				_start_playback()

func _delete_selected_notes() -> void:
	if current_track == null or selected_notes.is_empty():
		return

	var removed: Array = []
	for n in selected_notes:
		_ensure_note_uid(n)
		removed.append(_note_to_data(n))

	for item in removed:
		var data: Dictionary = item as Dictionary
		var n2: TrackFormat.TrackNote = _find_note_by_uid(int(data.get("uid", -1)))
		if n2 != null:
			current_track.remove_note(n2)

	selected_notes.clear()
	_push_action({"type": "remove_notes", "notes": removed})

	is_modified = true
	_update_ui()
	if piano_roll:
		piano_roll.queue_redraw()

func _on_back_pressed() -> void:
	if is_modified:
		# TODO: Show confirmation dialog
		pass
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ============================================================
# PIANO ROLL DRAWING (MUSICAL GRID)
# ============================================================
func draw_piano_roll(canvas: CanvasItem) -> void:
	if current_track == null:
		return

	var size: Vector2 = piano_roll.size
	var bg_color: Color = Color(0.12, 0.12, 0.15)
	var grid_sub_color: Color = Color(0.18, 0.18, 0.22)
	var grid_beat_color: Color = Color(0.26, 0.26, 0.32)
	var grid_measure_color: Color = Color(0.35, 0.35, 0.42)
	var white_key_bg: Color = Color(0.15, 0.15, 0.18)
	var black_key_bg: Color = Color(0.1, 0.1, 0.12)
	var row_line_color: Color = Color(0.2, 0.2, 0.25)

	canvas.draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

	# Key rows
	for i in range(KEY_COUNT):
		var midi_note: int = MIDI_MAX - i
		var y: float = float(i) * zoom_y
		var is_black: bool = _is_black_key(midi_note)
		var key_color: Color = black_key_bg if is_black else white_key_bg
		canvas.draw_rect(Rect2(0.0, y, size.x, zoom_y), key_color, true)
		canvas.draw_line(Vector2(0.0, y), Vector2(size.x, y), row_line_color, 1.0)

	# Time grid: subdivision / beat / measure
	var ts: Dictionary = _get_time_signature()
	var beats_per_measure: int = int(ts["beats"])
	var sub_duration: float = _get_grid_duration()
	var visible_duration: float = size.x / zoom_x

	var sub_px: float = sub_duration * zoom_x
	var draw_subdivisions: bool = sub_px >= 10.0

	var subs_per_beat: int = max(1, grid_division)
	var subs_per_measure: int = max(1, beats_per_measure * subs_per_beat)

	var denom_guard: float = maxf(sub_duration, 0.0001)
	var total_subs: int = int(ceil(visible_duration / denom_guard)) + 1

	for s in range(total_subs):
		var t: float = float(s) * sub_duration
		var x: float = t * zoom_x

		var is_measure: bool = (s % subs_per_measure) == 0
		var is_beat: bool = (s % subs_per_beat) == 0

		if is_measure:
			canvas.draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_measure_color, 2.5)
		elif is_beat:
			canvas.draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_beat_color, 1.5)
		elif draw_subdivisions:
			canvas.draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_sub_color, 1.0)

	# Notes + resize handle hint
	for raw in current_track.notes:
		var note: TrackFormat.TrackNote = raw
		var note_x: float = float(note.time) * zoom_x
		var note_y: float = float(MIDI_MAX - int(note.note)) * zoom_y
		var note_w: float = maxf(float(note.duration) * zoom_x, 8.0)
		var note_h: float = zoom_y - 2.0

		var is_selected: bool = note in selected_notes
		var hue: float = float(int(note.note) - MIDI_MIN) / float(KEY_COUNT) * 0.8
		var note_color: Color = Color.from_hsv(hue, 0.7, 0.9)
		if is_selected:
			note_color = Color(1.0, 1.0, 0.5)

		canvas.draw_rect(Rect2(note_x, note_y + 1.0, note_w, note_h), note_color, true)
		canvas.draw_rect(Rect2(note_x, note_y + 1.0, note_w, note_h), note_color.darkened(0.3), false, 1.0)
		canvas.draw_line(
			Vector2(note_x + note_w, note_y + 1.0),
			Vector2(note_x + note_w, note_y + 1.0 + note_h),
			note_color.darkened(0.5),
			1.0
		)

	# Playback cursor
	if is_playing:
		var cursor_x: float = playback_time * zoom_x
		canvas.draw_line(Vector2(cursor_x, 0.0), Vector2(cursor_x, size.y), Color(1, 0.3, 0.3), 2.0)

func _is_black_key(midi_note: int) -> bool:
	var note_in_octave: int = midi_note % 12
	return note_in_octave in [1, 3, 6, 8, 10]
