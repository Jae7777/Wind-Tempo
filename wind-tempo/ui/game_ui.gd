extends Control

@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $MarginContainer/VBoxContainer/ComboLabel

func _ready():
	# Connect to the ScoreManager's signals
	ScoreManager.score_updated.connect(self._on_score_updated)
	ScoreManager.combo_updated.connect(self._on_combo_updated)
	
	# Initialize the labels with the current values
	_on_score_updated(ScoreManager.score)
	_on_combo_updated(ScoreManager.combo)

func _on_score_updated(new_score: int):
	score_label.text = "Score: " + str(new_score)

func _on_combo_updated(new_combo: int):
	combo_label.text = "Combo: " + str(new_combo)
