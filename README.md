# Wind Tempo - Rhythm Piano Game

A rhythm-based piano game inspired by OSU! and Guitar Hero, built with Godot 4/5.

## Features

### Core Gameplay
- **Falling-note highway** with visual lanes and hit detection zones
- **4-lane keyboard input** (A/S/D/F) with MIDI support placeholder
- **Judgment system** with timing windows (Perfect/Great/Good/Miss)
- **Real-time scoring** with combo multipliers and difficulty scaling
- **Visual & audio feedback** including particles, popups, and screen effects

### Chart System
- **JSON-based charts** with note timing and lane mapping
- **Chart library** with multiple difficulty levels (Easy/Normal/Hard)
- **Expandable song support** with custom chart creation

### Settings & Calibration
- **Persistent settings** (volumes, visual effects, latency offset)
- **Audio sync calibration** for measuring and compensating latency
- **Configurable judgment windows** and scoring mechanics

### UI & Menus
- **Main menu** with song selection and navigation
- **Results screen** showing scores, accuracy, ranks, and personal records
- **Settings menu** for audio/visual configuration
- **Pause menu** with resume/retry/quit options
- **Song select UI** with preview and difficulty info

### Statistics & Progression
- **Session tracking** with persistent storage
- **Accuracy bonuses** and combo bonus calculations
- **Rank system** (SSS/SS/S/A/B/C/D/F) with color coding
- **Best score/accuracy** tracking per song

## Project Structure

```
wind-tempo/
├── scenes/
│   ├── Main.tscn          # Main game scene
│   ├── Note.tscn          # Falling note prefab
│   └── Highway.tscn       # Note highway
├── scripts/
│   ├── Core/
│   │   ├── Main.gd        # Main game controller
│   │   ├── Note.gd        # Note behavior
│   │   ├── InputHandler.gd
│   │   └── HitDetector.gd
│   ├── Gameplay/
│   │   ├── ChartLoader.gd
│   │   ├── ChartSpawner.gd
│   │   ├── JudgmentSystem.gd
│   │   └── ScoringCalculator.gd
│   ├── Audio/
│   │   ├── AudioManager.gd
│   │   └── AudioSyncCalibrator.gd
│   ├── Systems/
│   │   ├── GameController.gd
│   │   ├── GameSettings.gd
│   │   ├── StatisticsTracker.gd
│   │   ├── AnimationController.gd
│   │   └── ParticleEffectManager.gd
│   └── Utilities/
│       ├── ChartLibrary.gd
│       ├── TimingDebugger.gd
│       └── HighwayRenderer.gd
├── ui/
│   ├── HUD.gd
│   ├── MainMenu.gd
│   ├── ResultsScreen.gd
│   ├── SettingsMenu.gd
│   ├── PauseMenu.gd
│   └── SongSelectUI.gd
├── charts/
│   ├── sample_song.json
│   ├── easy_mode.json
│   └── hard_mode.json
└── project.godot
```

## Getting Started

### Requirements
- Godot 4.x or 5.x
- Windows/Linux/macOS

### Installation
1. Clone the repository
2. Open the project folder in Godot
3. Load `scenes/Main.tscn` as the main scene
4. Assign `Note.tscn` as a PackedScene on the ChartSpawner node

### Running
- Press SPACE to start game with selected chart
- Press A/S/D/F to hit notes
- Press ESC to pause/resume
- Press R to reset

## Configuration

### Game Settings
Settings are stored in `user://wind_tempo_settings.cfg`:
- Master/music/SFX volumes (dB range: -80 to 0)
- Audio latency offset (ms)
- Visual effects toggle
- Combo particles toggle

### Judgment Windows
Configurable in `JudgmentSystem.gd`:
- Perfect: ±50ms
- Great: ±100ms
- Good: ±150ms
- Miss: >±300ms

### Difficulty Scaling
Score multipliers in `ScoringCalculator.gd`:
- Easy: 0.8x
- Normal: 1.0x
- Hard: 1.5x
- Extreme: 2.0x

## Chart Format

Charts are JSON files with metadata and note data:

```json
{
  "metadata": {
    "title": "Song Name",
    "artist": "Artist Name",
    "difficulty": "Hard",
    "duration": 120.0,
    "bpm": 120,
    "offset": 0.0
  },
  "notes": [
    {"time": 1.0, "lane": 0},
    {"time": 1.5, "lane": 1},
    {"time": 2.0, "lane": 2},
    {"time": 2.5, "lane": 3}
  ]
}
```

## Development Notes

### Adding New Charts
1. Create a JSON file in `charts/`
2. Follow the chart format structure
3. Use ChartLibrary to register new songs

### Customizing Scoring
1. Modify judgment windows in JudgmentSystem.gd
2. Adjust difficulty multipliers in ScoringCalculator.gd
3. Add bonus logic as needed

### Input Debugging
Use TimingDebugger.gd to:
- Record hit offsets
- Analyze timing accuracy
- Generate statistics for calibration

## Performance

- Supports up to 500 active particles
- Optimized note spawning with lead-time scheduling
- Efficient chart loading and caching

## Future Enhancements

- [ ] MIDI keyboard support
- [ ] Audio file loading and playback
- [ ] Custom chart editor
- [ ] Leaderboards (local/cloud)
- [ ] Replays and performance analytics
- [ ] Additional visual themes
- [ ] Multiplayer mode
- [ ] Export to other platforms

## License

[Your License Here]

## Credits

Developed with Godot Engine
