extends Control

"""
DifficultySelector allows players to choose game difficulty before playing.
Affects scoring, judgment windows, and visual feedback.
"""

@onready var easy_button = $VBoxContainer/EasyButton
@onready var normal_button = $VBoxContainer/NormalButton
@onready var hard_button = $VBoxContainer/HardButton
@onready var extreme_button = $VBoxContainer/ExtremeButton
@onready var info_label = $VBoxContainer/InfoLabel
@onready var back_button = $VBoxContainer/BackButton

var selected_difficulty: String = "Normal"
var difficulty_info = {
	"Easy": {
		"description": "Perfect for beginners. Wide judgment windows and slower note speeds.",
		"multiplier": 0.8,
		"note_speed": 400.0
	},
	"Normal": {
		"description": "Standard difficulty. Balanced challenge and accessibility.",
		"multiplier": 1.0,
		"note_speed": 600.0
	},
	"Hard": {
		"description": "Challenging gameplay. Tight timing windows and faster notes.",
		"multiplier": 1.5,
		"note_speed": 800.0
	},
	"Extreme": {
		"description": "For experts only. Extreme speed and precise timing required.",
		"multiplier": 2.0,
		"note_speed": 1000.0
	}
}

signal difficulty_selected(difficulty: String)

func _ready() -> void:
	_connect_signals()
	_setup_ui()
	hide()

func _connect_signals() -> void:
	"""Connect button signals."""
	easy_button.pressed.connect(func(): _select_difficulty("Easy"))
	normal_button.pressed.connect(func(): _select_difficulty("Normal"))
	hard_button.pressed.connect(func(): _select_difficulty("Hard"))
	extreme_button.pressed.connect(func(): _select_difficulty("Extreme"))
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui() -> void:
	"""Initialize UI with difficulty info."""
	info_label.text = "Select a difficulty level"

func _select_difficulty(difficulty: String) -> void:
	"""Select a difficulty level."""
	selected_difficulty = difficulty
	var info = difficulty_info[difficulty]
	info_label.text = info["description"]
	
	# Highlight selected button
	_update_button_states(difficulty)
	
	emit_signal("difficulty_selected", difficulty)

func _update_button_states(selected: String) -> void:
	"""Update button visual states."""
	var buttons = {
		"Easy": easy_button,
		"Normal": normal_button,
		"Hard": hard_button,
		"Extreme": extreme_button
	}
	
	for diff in buttons:
		var btn = buttons[diff]
		if diff == selected:
			btn.add_theme_color_override("font_color", Color.GOLD)
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)

func _on_back_pressed() -> void:
	"""Return to menu."""
	hide()

func get_selected_difficulty() -> String:
	"""Get currently selected difficulty."""
	return selected_difficulty

func get_difficulty_multiplier(difficulty: String) -> float:
	"""Get score multiplier for difficulty."""
	return difficulty_info.get(difficulty, difficulty_info["Normal"])["multiplier"]

func get_note_speed(difficulty: String) -> float:
	"""Get note falling speed for difficulty."""
	return difficulty_info.get(difficulty, difficulty_info["Normal"])["note_speed"]
