extends Node

@export var hit_y: float = 800.0
@export var hit_tolerance: float = 40.0

var active_notes: Array = []
var active_hold_notes: Dictionary = {}  # lane -> hold note being held
var score: int = 0
var notes_hit: int = 0
var notes_missed: int = 0
var total_notes: int = 0
var current_combo: int = 0
var max_combo: int = 0
var hud = null
var _hit_effect_scene = null

func _ready() -> void:
	# siblings under the Main root (GameManager is a child of Main)
	var parent = get_parent()
	var piano = parent.get_node_or_null("Piano")
	var spawner = parent.get_node_or_null("NoteSpawner")
	if piano:
		piano.connect("key_pressed", Callable(self, "_on_key_pressed"))
		piano.connect("key_released", Callable(self, "_on_key_released"))
	if spawner:
		spawner.connect("note_spawned", Callable(self, "_on_note_spawned"))
		# Example chart (time in seconds). Replace or load from Charts directory.
		spawner.note_scene = preload("res://CoreGameplay/Note.tscn")
		# Try to load a chart from Charts/song1.json if present; otherwise use a small built-in example
		var chart_path = "res://Charts/song1.json"
		if FileAccess.file_exists(chart_path):
			load_chart(chart_path, spawner)
		else:
			spawner.chart = [
				{"time":1.0, "lane":0},
				{"time":1.5, "lane":1},
				{"time":2.0, "lane":2},
				{"time":2.5, "lane":3},
				{"time":3.0, "lane":0},
			]

	# HUD is a sibling of this node under the Main root
	hud = get_parent().get_node_or_null("HUD")
	if hud:
		# HUD may not have run _ready yet; defer to ensure its internals are initialized
		hud.call_deferred("set_score", score)

	# preload hit effect scene for reuse
	self._hit_effect_scene = preload("res://CoreGameplay/HitEffect.tscn")

	# reset spawner time
	if spawner:
		spawner.reset()

	# Adjust HitLine to match hit_y and viewport width so it's visible in any window size
	var hitline = parent.get_node_or_null("HitLine")
	if hitline:
		var vw = get_viewport().get_visible_rect().size.x
		# set two points left->right at the configured hit_y
		hitline.points = [ Vector2(0, hit_y), Vector2(vw, hit_y) ]
		# if hit_y is offscreen, log a hint
		var vh = get_viewport().get_visible_rect().size.y
		if hit_y < 0 or hit_y > vh:
			print("[GameManager] Warning: hit_y (%s) is outside viewport height (%s). Adjust GameManager.hit_y in the inspector." % [str(hit_y), str(vh)])

func _on_note_spawned(note) -> void:
	if note.has_method("on_hit_start"):  # It's a hold note
		note.connect("hit_start", Callable(self, "_on_hold_note_start"))
		note.connect("hit_end", Callable(self, "_on_hold_note_end"))
		note.connect("missed", Callable(self, "_on_hold_note_missed"))
	else:  # Regular note
		note.connect("hit", Callable(self, "_on_note_hit"))
	active_notes.append(note)

func _on_note_hit(note) -> void:
	score += 1
	notes_hit += 1
	current_combo += 1
	if current_combo > max_combo:
		max_combo = current_combo
	active_notes.erase(note)
	print("Hit! Score:", score)
	if hud:
		hud.set_score(score)
		hud.show_feedback("Hit!")

	# spawn a hit effect at the note's lane and hit Y
	var spawner = get_parent().get_node_or_null("NoteSpawner")
	if spawner:
		var fx = _hit_effect_scene.instantiate()
		fx.position = Vector2(spawner.lanes_x[note.lane], hit_y)
		get_parent().add_child(fx)

func _on_key_pressed(lane: int) -> void:
	var best_note = null
	var best_dist = hit_tolerance + 1
	for note in active_notes:
		if note.lane == lane:
			# Check if it's a hold note
			if note.has_method("is_hittable_start") and note.is_hittable_start(hit_y, hit_tolerance):
				var dist = abs(note.position.y - hit_y)
				if dist < best_dist:
					best_dist = dist
					best_note = note
			# Regular note
			elif note.has_method("is_hittable") and note.is_hittable(hit_y, hit_tolerance):
				var dist = abs(note.position.y - hit_y)
				if dist < best_dist:
					best_dist = dist
					best_note = note
	
	if best_note:
		if best_note.has_method("on_hit_start"):
			# Hold note start
			best_note.on_hit_start()
			active_hold_notes[lane] = best_note
		else:
			# Regular note
			best_note.on_hit()
	else:
		notes_missed += 1
		current_combo = 0
		print("Miss on lane", lane)
		if hud:
			hud.show_feedback("Miss")

func _on_key_released(lane: int) -> void:
	if active_hold_notes.has(lane):
		var hold_note = active_hold_notes[lane]
		# Check if tail reached hit line
		if hold_note.is_hittable_end(hit_y, hit_tolerance):
			hold_note.on_hit_end()
		else:
			# Released too early
			hold_note.on_release_early()
		active_hold_notes.erase(lane)

func _on_hold_note_start(note) -> void:
	score += 50  # Bonus for starting hold
	if hud:
		hud.set_score(score)
		hud.show_feedback("Hold!")
	
	# spawn a hit effect at the note's lane and hit Y
	var spawner = get_parent().get_node_or_null("NoteSpawner")
	if spawner:
		var fx = _hit_effect_scene.instantiate()
		fx.position = Vector2(spawner.lanes_x[note.lane], hit_y)
		get_parent().add_child(fx)

func _on_hold_note_end(note) -> void:
	score += 100  # Bonus for completing hold
	notes_hit += 1
	current_combo += 1
	if current_combo > max_combo:
		max_combo = current_combo
	active_notes.erase(note)
	print("Hold Complete! Score:", score)
	if hud:
		hud.set_score(score)
		hud.show_feedback("Perfect!")
	
	# spawn a hit effect
	var spawner = get_parent().get_node_or_null("NoteSpawner")
	if spawner:
		var fx = _hit_effect_scene.instantiate()
		fx.position = Vector2(spawner.lanes_x[note.lane], hit_y)
		get_parent().add_child(fx)

func _on_hold_note_missed(note) -> void:
	notes_missed += 1
	current_combo = 0
	active_notes.erase(note)
	# Remove from active holds if present
	for lane in active_hold_notes.keys():
		if active_hold_notes[lane] == note:
			active_hold_notes.erase(lane)
			break
	if hud:
		hud.show_feedback("Miss")

func load_chart(path: String, spawner) -> void:
	var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if not f:
		push_error("Failed to open chart: %s" % path)
		return
	var txt = f.get_as_text()
	f.close()
	# Some chart files in this repo were saved with Markdown code fences (```json ... ```)
	# Strip leading/trailing fenced code block markers if present so JSON.parse_string succeeds.
	var clean_txt = txt
	clean_txt = clean_txt.strip_edges(true, true)
	if clean_txt.begins_with("```"):
		var lines = clean_txt.split("\n")
		# remove the first line (```json) and the last line (```) if they exist
		if lines.size() > 0 and lines[0].begins_with("```"):
			lines.remove_at(0)
		if lines.size() > 0 and lines[lines.size() - 1].begins_with("```"):
			lines.remove_at(lines.size() - 1)
		clean_txt = lines.join("\n")

	# Debug: show cleaned text length and a short preview to help diagnose parse issues
	print("[GameManager] load_chart: cleaned text length=%d" % clean_txt.length())
	var preview = clean_txt.substr(0, min(clean_txt.length(), 400))
	print("[GameManager] load_chart: preview:\n" + preview)
	var parse_result = JSON.parse_string(clean_txt)
	# JSON.parse_string should return a Dictionary with keys: "result", "error"
	if typeof(parse_result) != TYPE_DICTIONARY:
		push_error("Unexpected JSON.parse_string return type for %s" % path)
		return
	var err = parse_result.get("error", null)
	# some Godot builds may return null for the error field in edge cases; coerce to int sentinel
	if err == null:
		err = -1
	if err != OK:
		var err_str = parse_result.get("error_string", "(no message)")
		push_error("Failed to parse JSON chart (%s) error: %s - %s" % [path, str(err), str(err_str)])
		return
	var parsed = parse_result.get("result", null)
	if parsed == null:
		push_error("Parsed chart is null: %s" % path)
		return

	# Accept two formats: a top-level array of notes, or an object with a "notes" array
	if typeof(parsed) == TYPE_ARRAY:
		spawner.chart = parsed
		total_notes = spawner.chart.size()
		print("Loaded chart (array) with %d notes from %s" % [spawner.chart.size(), path])
		return
	elif typeof(parsed) == TYPE_DICTIONARY and parsed.has("notes") and typeof(parsed["notes"]) == TYPE_ARRAY:
		spawner.chart = parsed["notes"]
		total_notes = spawner.chart.size()
		print("Loaded chart (object.notes) with %d notes from %s" % [spawner.chart.size(), path])
		return
	else:
		push_error("Unexpected chart JSON format: must be a notes array or {\"notes\": [...] } in %s" % path)
		return

func _process(_delta: float) -> void:
	# Check if all notes have been spawned and no active notes remain
	var spawner = get_parent().get_node_or_null("NoteSpawner")
	if spawner and total_notes > 0:
		if spawner.next_index >= total_notes and active_notes.size() == 0:
			# Song complete, show score screen
			_show_score_screen()

func _show_score_screen() -> void:
	# Load score screen and pass results
	var score_scene = load("res://ScoreScreen.tscn")
	if score_scene:
		var score_screen = score_scene.instantiate()
		score_screen.set_results(score, notes_hit, total_notes, max_combo)
		get_tree().get_root().add_child(score_screen)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = score_screen
