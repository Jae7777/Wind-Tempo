extends Node

@export var hit_y: float = 800.0
@export var hit_tolerance: float = 40.0

var active_notes: Array = []
var score: int = 0
var hud = null
var _hit_effect_scene = null

func _ready() -> void:
	# siblings under the Main root (GameManager is a child of Main)
	var parent = get_parent()
	var piano = parent.get_node_or_null("Piano")
	var spawner = parent.get_node_or_null("NoteSpawner")
	if piano:
		piano.connect("key_pressed", Callable(self, "_on_key_pressed"))
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
	note.connect("hit", Callable(self, "_on_note_hit"))
	active_notes.append(note)

func _on_note_hit(note) -> void:
	score += 1
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
			var dist = abs(note.position.y - hit_y)
			if dist <= hit_tolerance and dist < best_dist:
				best_dist = dist
				best_note = note
	if best_note:
		best_note.on_hit()
	else:
		print("Miss on lane", lane)
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
		print("Loaded chart (array) with %d notes from %s" % [spawner.chart.size(), path])
		return
	elif typeof(parsed) == TYPE_DICTIONARY and parsed.has("notes") and typeof(parsed["notes"]) == TYPE_ARRAY:
		spawner.chart = parsed["notes"]
		print("Loaded chart (object.notes) with %d notes from %s" % [spawner.chart.size(), path])
		return
	else:
		push_error("Unexpected chart JSON format: must be a notes array or {\"notes\": [...] } in %s" % path)
		return
