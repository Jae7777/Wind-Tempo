extends Node2D

func _ready() -> void:
    # Animate the label: scale up and fade out, then free
    var lbl = $Label2D
    lbl.modulate.a = 1.0
    lbl.scale = Vector2(0.6, 0.6)
    var tw = create_tween()
    tw.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.35)
    tw.tween_property(lbl, "modulate:a", 0.0, 0.35)
    tw.connect("finished", Callable(self, "queue_free"))
