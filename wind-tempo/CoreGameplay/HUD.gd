extends CanvasLayer

var score_label: Label
var feedback_label: Label

func _ready() -> void:
	score_label = $ScoreLabel
	feedback_label = $FeedbackLabel
	feedback_label.visible = false

func set_score(value: int) -> void:
	score_label.text = "Score: %d" % value

func show_feedback(text: String) -> void:
	feedback_label.text = text
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(feedback_label, "modulate:a", 0.0, 0.8)
	tw.connect("finished", Callable(feedback_label, "hide"))
