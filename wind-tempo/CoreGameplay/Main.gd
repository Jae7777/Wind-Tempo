extends Node2D

@export var hit_line_y: float = 600.0

@onready var feedback: Label = $"UI/Feedback"
var tween: Tween

func _ready() -> void:
	feedback.visible = false
	feedback.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # space/enter by default
		for note in get_tree().get_nodes_in_group("note"):
			if note.can_be_hit:
				note.queue_free()
				_show_feedback("HIT!", Color(0.2, 1.0, 0.2, 1.0))
				return
		_show_feedback("MISS!", Color(1.0, 0.25, 0.25, 1.0))

func _show_feedback(text: String, col: Color) -> void:
	# Cancel old tween if still running
	if tween and tween.is_running():
		tween.kill()

	feedback.text = text
	feedback.modulate = col
	feedback.modulate.a = 0.0
	feedback.visible = true

	tween = create_tween()
	tween.tween_property(feedback, "modulate:a", 1.0, 0.08)   # fade in
	tween.tween_interval(0.35)                                # hold
	tween.tween_property(feedback, "modulate:a", 0.0, 0.25)   # fade out
	tween.finished.connect(func(): feedback.visible = false)
