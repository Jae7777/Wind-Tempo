# Wind Tempo - Prototype scaffold

This repository contains an early scaffold for the Wind Tempo rhythm-piano prototype.

What I added:
- `scenes/` with `Main.tscn`, `Note.tscn`, and `Highway.tscn` placeholders.
- `scripts/` containing `Main.gd`, `Note.gd`, `Spawner.gd`, `InputHandler.gd`, and `Score.gd`.
- `ui/` with `HUD.tscn` and `HUD.gd`.

How to open the project:
1. Install Godot 4/5 (project uses a Godot 5 `project.godot` header).
2. Open the folder `c:\Users\ronal\Wind-Tempo\wind-tempo` in Godot.
3. Open `scenes/Main.tscn` and attach the `Note.tscn` as a `PackedScene` on the `Spawner` node.

Next recommended steps:
- Wire `Spawner` to load a `Note.tscn` `PackedScene` resource and implement timed spawning.
- Connect `InputHandler` signals to `Main` and implement judgment logic in `Score.gd`.
- Add a simple chart format (JSON) and a spawner routine that schedules notes from chart timings.
- Investigate MIDI plugin options for Godot (or external helper) if MIDI input is desired.

If you want, I can now:
- Wire up the spawner to read a small JSON chart and spawn notes on a timeline.
- Add basic judgement/timing windows and visual feedback.
- Integrate a lightweight MIDI input plugin research step.

Tell me which next step you prefer.
