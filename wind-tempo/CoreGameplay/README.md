# CoreGameplay — Piano Game (prototype)

This folder contains a minimal, Godot-4-compatible prototype for a piano / rhythm game. It includes scripts and a tiny Note scene. The scene files themselves are intentionally minimal so you can wire them in the Godot editor visually.

Files added
- `Note.tscn` — a lightweight note scene showing a dot and using `Note.gd`.
- `Note.gd` — logic for a falling note (movement + hit API and signal).
- `NoteSpawner.gd` — spawns notes from a simple chart (array of {time, lane}).
- `Piano.gd` — converts Input Map actions into lane-press signals.
- `GameManager.gd` — wires Piano + NoteSpawner, tracks active notes and scoring.

Quick editor walkthrough (Godot 4.5)

1. Open the project in Godot (it should detect `project.godot` in the project root).

2. Create a new scene (Scene -> New Scene) and choose `Node2D` as the root. Save it as `res://CoreGameplay/Main.tscn`.

3. Under the root `Node2D` add the following child nodes (use the node create dialog):
   - `Node` named `GameManager` — attach the `GameManager.gd` script (select `res://CoreGameplay/GameManager.gd`).
   - `Node` named `NoteSpawner` — attach the `NoteSpawner.gd` script.
   - `Node` named `Piano` — attach the `Piano.gd` script.

   The hierarchy should look like:

   Node2D (root)
   ├─ GameManager (Node, script: GameManager.gd)
   ├─ NoteSpawner (Node, script: NoteSpawner.gd)
   └─ Piano (Node, script: Piano.gd)

4. Configure `NoteSpawner` properties in the Inspector:
   - `Note Scene` — set to `res://CoreGameplay/Note.tscn` (or leave GameManager to set it automatically).
   - `Spawn Y` — the starting Y position for newly spawned notes (negative above the screen, e.g. -50).
   - `Lanes X` — an array of X positions for each lane (for example [150, 300, 450, 600]). Adjust to match your window width.

5. Configure `GameManager` properties:
   - `Hit Y` — the Y position where the player should press the key to hit the note (e.g. around window height - 200).
   - `Hit Tolerance` — allowed distance from `Hit Y` to count as a hit (pixels). Experiment with 30–60.

6. Configure the Input Map (Project -> Project Settings -> Input Map)
   - Add actions: `lane_0`, `lane_1`, `lane_2`, `lane_3`.
   - For each action add a key event: for example map `lane_0` -> `A`, `lane_1` -> `S`, `lane_2` -> `D`, `lane_3` -> `F`.

7. Save the `Main.tscn` scene and set it as the main scene (Project -> Project Settings -> Application -> Run -> Main Scene) or use the Play button while the scene is open.

How the system works (summary)
- `NoteSpawner` keeps a `chart` array (each entry: `{"time": <seconds>, "lane": <int>}`) and spawns `Note.tscn` instances at the given times.
- Each spawned `Note` moves downward (`Note.gd`). When spawned the `Note` emits a signal that `GameManager` listens to.
- `Piano` emits a `key_pressed(lane)` signal when the corresponding Input Map action is pressed.
- `GameManager` listens for those signals and finds the nearest active note in that lane (within `hit_tolerance`) and calls `note.on_hit()` to register a hit.

Next steps / suggestions
- Replace the `Note.tscn` visual with a sprite or animated sprite for a nicer look.
- Load charts from `res://Charts/*.json` instead of the hardcoded array in `GameManager.gd`. The `Charts` folder in the project already has `song1.json` and `song2.json` — you can parse those and convert them to the expected `{time,lane}` list.
- Add hit feedback (particles / sound) by connecting `Note.hit` to a small Effect node.
- Add scoring, accuracy windows (Perfect/Good/Miss), and combo counters in `GameManager`.

If you'd like, I can:
- create the `Main.tscn` automatically and wire the nodes and exported properties, or
- implement chart loading from `Charts/song1.json`, or
- add a small UI HUD showing score and combo.

Tell me which next step you'd like and I will implement it.
