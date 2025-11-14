@tool
extends Control

@export var icon_color: Color = Color.WHITE

# This function is called automatically by Godot
func _draw():
	# Calculate the size of the bars based on the node's total size
	# This will create two bars and one gap of equal width.
	var bar_width = size.x / 3.0
	var bar_height = size.y
	var spacing = bar_width

	# Draw the first bar (left)
	draw_rect(Rect2(0, 0, bar_width, bar_height), icon_color)

	# Draw the second bar (right)
	draw_rect(Rect2(bar_width + spacing, 0, bar_width, bar_height), icon_color)
