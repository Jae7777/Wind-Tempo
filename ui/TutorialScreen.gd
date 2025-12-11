extends Control

"""
TutorialScreen provides interactive tutorial and help information.
Teaches controls, gameplay mechanics, and scoring system.
"""

@onready var title_label = $VBoxContainer/TitleLabel
@onready var content_label = $VBoxContainer/ContentLabel
@onready var previous_button = $VBoxContainer/PreviousButton
@onready var next_button = $VBoxContainer/NextButton
@onready var skip_button = $VBoxContainer/SkipButton
@onready var progress_label = $VBoxContainer/ProgressLabel

var current_page: int = 0
var tutorial_pages: Array = []

signal tutorial_started
signal tutorial_completed
signal page_changed(page_number: int, total_pages: int)

func _ready() -> void:
	_setup_tutorial_pages()
	_connect_signals()
	hide()

func _setup_tutorial_pages() -> void:
	"""Define all tutorial pages."""
	tutorial_pages = [
		{
			"title": "Welcome to Wind Tempo!",
			"content": "Wind Tempo is a rhythm game where you hit falling notes to the beat of the music.\n\nPress SPACE to start a song and use your keyboard to hit the notes as they fall down the screen."
		},
		{
			"title": "Controls",
			"content": "Use these keys to hit notes:\n\nA - Left lane\nS - Left-middle lane\nD - Right-middle lane\nF - Right lane\n\nESC - Pause/Resume the game\nR - Restart the current song"
		},
		{
			"title": "Judgment System",
			"content": "Your timing determines your score:\n\nPERFECT (±50ms): 100 points - Golden timing\nGREAT (±100ms): 70 points - Excellent hit\nGOOD (±150ms): 40 points - Solid hit\nMISS (>±300ms): 0 points - Missed note"
		},
		{
			"title": "Combo System",
			"content": "Build a combo by hitting consecutive notes:\n\n• Maintain combos for higher scores\n• Combos increase your score multiplier\n• Miss a note? Combo resets to 0\n• Track your best combo on the results screen"
		},
		{
			"title": "Scoring",
			"content": "Your final score is calculated from:\n\n• Base score per hit (depends on judgment)\n• Difficulty multiplier (Easy: 0.8x - Extreme: 2.0x)\n• Combo bonus (higher combos = higher multiplier)\n• Accuracy bonus (90%+ accuracy = extra points)"
		},
		{
			"title": "Rank System",
			"content": "Achieve ranks based on your performance:\n\nSSS - 99%+ accuracy (Godlike!)\nSS - 95%+ accuracy (Excellent)\nS - 90%+ accuracy (Great)\nA - 80%+ accuracy (Good)\nB - 70%+ accuracy (Fair)\nC - 60%+ accuracy (Pass)\nD - 50%+ accuracy (Barely)\nF - Below 50% (Try again)"
		},
		{
			"title": "Game Modes",
			"content": "Choose a song and difficulty:\n\nEASY: Wide timing windows, slower notes\nNORMAL: Standard difficulty\nHARD: Tight timing, faster notes\nEXTREME: Expert only\n\nHigher difficulties earn more points!"
		},
		{
			"title": "Tips & Tricks",
			"content": "Master these techniques:\n\n• Calibrate audio latency in Settings\n• Practice with Easy mode to build rhythm\n• Watch the yellow hit zone line\n• Try different speeds based on your skill\n• Review your statistics to track improvement"
		},
		{
			"title": "Ready to Play!",
			"content": "You're all set! Head to the main menu to:\n\n• Select a song\n• Choose a difficulty\n• Challenge yourself\n• Climb the leaderboards\n\nGood luck and have fun!"
		}
	]

func _connect_signals() -> void:
	"""Connect button signals."""
	previous_button.pressed.connect(_on_previous_pressed)
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func show_tutorial() -> void:
	"""Start the tutorial."""
	current_page = 0
	show()
	_display_current_page()
	emit_signal("tutorial_started")

func _display_current_page() -> void:
	"""Display the current tutorial page."""
	if current_page < 0 or current_page >= tutorial_pages.size():
		return
	
	var page = tutorial_pages[current_page]
	title_label.text = page["title"]
	content_label.text = page["content"]
	
	progress_label.text = "Page %d / %d" % [current_page + 1, tutorial_pages.size()]
	
	# Update button states
	previous_button.disabled = current_page == 0
	next_button.disabled = current_page == tutorial_pages.size() - 1
	
	emit_signal("page_changed", current_page + 1, tutorial_pages.size())

func _on_previous_pressed() -> void:
	"""Go to previous page."""
	if current_page > 0:
		current_page -= 1
		_display_current_page()

func _on_next_pressed() -> void:
	"""Go to next page."""
	if current_page < tutorial_pages.size() - 1:
		current_page += 1
		_display_current_page()

func _on_skip_pressed() -> void:
	"""Skip tutorial and return to menu."""
	hide()
	emit_signal("tutorial_completed")

func _input(event: InputEvent) -> void:
	"""Handle keyboard navigation."""
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_on_previous_pressed()
			KEY_RIGHT:
				_on_next_pressed()
			KEY_ESCAPE:
				_on_skip_pressed()
