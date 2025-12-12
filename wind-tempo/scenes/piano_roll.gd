# scenes/PianoRoll.gd
# Custom control for the piano roll note editor
extends Control

var workshop: Node = null

func _ready() -> void:
	# Find workshop parent
	workshop = get_parent()
	while workshop and not workshop.has_method("draw_piano_roll"):
		workshop = workshop.get_parent()

func _draw() -> void:
	if workshop and workshop.has_method("draw_piano_roll"):
		workshop.draw_piano_roll(self)
