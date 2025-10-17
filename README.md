# Wind-Tempo
extends Node2D

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var total_notes: int = 0
var correct_notes: int = 0

@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var accuracy_label: Label = $AccuracyLabel

func on_note_hit(is_correct: bool):
total_notes += 1

if is_correct:
correct_notes += 1
combo += 1
var points = 100 * combo_multiplier()
score += points
	
if combo > max_combo:
max_combo = combo
	
show_feedback("Perfect! +%d" % points)
else:
combo = 0
show_feedback("Miss!")

update_ui()
func combo_multiplier() -> float:
if combo < 10:
return 1.0
elif combo < 20:
return 1.5
elif combo < 40:
return 2.0
else:
return 3.0

func update_ui():
if score_label:
score_label.text = "Score: %d" % score
if combo_label:
combo_label.text = "Combo: %d" % combo
if accuracy_label:
accuracy_label.text = "Accuracy: %.1f%%" % get_accuracy()

func get_accuracy() -> float:
if total_notes == 0:
return 0.0
return float(correct_notes) / float(total_notes) * 100.0

func show_feedback(text: String):
print(text)
