# Main.gd
extends Node2D

@export var hit_line_y: float = 600.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # space/enter by default
		for note in get_tree().get_nodes_in_group("note"):
			if note.can_be_hit:
				print("HIT!")   # later add score/combo system
				note.queue_free()
				return
		print("MISS!")  # pressed but no note in window
