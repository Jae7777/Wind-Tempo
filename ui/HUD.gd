extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var combo_label = get_parent().get_node_or_null("HUD/ComboLabel")
@onready var judgment_label = get_parent().get_node_or_null("HUD/JudgmentLabel")
@onready var accuracy_label = get_parent().get_node_or_null("HUD/AccuracyLabel")

var current_judgment: String = ""
var judgment_fade_timer: float = 0.0

func _ready() -> void:
	# Initialize labels if they exist
	if score_label == null:
		push_error("HUD: ScoreLabel not found in scene!")

func _process(delta: float) -> void:
	# Fade out judgment display
	if judgment_fade_timer > 0.0:
		judgment_fade_timer -= delta
		if judgment_label:
			judgment_label.modulate.a = judgment_fade_timer / 0.5

func set_score(value: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % value

func set_combo(value: int) -> void:
	if combo_label:
		var color = Color.WHITE
		if value > 10:
			color = Color.YELLOW
		if value > 25:
			color = Color.ORANGE_RED
		
		combo_label.text = "Combo: %d" % value
		combo_label.modulate.a = min(1.0, value / 20.0)

func show_judgment(judgment: String, score_value: int) -> void:
	"""Display judgment feedback on screen."""
	current_judgment = judgment
	judgment_fade_timer = 0.5
	
	if judgment_label:
		judgment_label.text = judgment
		
		# Color based on judgment
		match judgment:
			"Perfect":
				judgment_label.modulate = Color.GOLD
			"Great":
				judgment_label.modulate = Color.GREEN
			"Good":
				judgment_label.modulate = Color.YELLOW
			"Miss":
				judgment_label.modulate = Color.RED
		
		judgment_label.modulate.a = 1.0

func set_accuracy(accuracy: float) -> void:
	"""Update accuracy display."""
	if accuracy_label:
		accuracy_label.text = "Accuracy: %.1f%%" % accuracy
