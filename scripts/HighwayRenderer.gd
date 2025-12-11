extends Node2D

"""
HighwayRenderer draws the visual note highway with lanes and hit zones.
"""

@export var lane_count: int = 4
@export var lane_width: float = 80.0
@export var lane_spacing: float = 20.0
@export var hit_zone_height: float = 30.0
@export var hit_zone_y: float = 900.0

var lane_positions: Array = []

func _ready() -> void:
	_calculate_lane_positions()
	queue_redraw()

func _calculate_lane_positions() -> void:
	"""Calculate X positions for all lanes."""
	lane_positions.clear()
	
	var total_width = (lane_count * lane_width) + ((lane_count - 1) * lane_spacing)
	var start_x = (get_viewport_rect().size.x - total_width) / 2.0
	
	for i in range(lane_count):
		var x = start_x + (i * (lane_width + lane_spacing)) + (lane_width / 2.0)
		lane_positions.append(x)

func _draw() -> void:
	"""Draw the highway lanes and hit zone."""
	_draw_lanes()
	_draw_hit_zone()

func _draw_lanes() -> void:
	"""Draw individual note lanes."""
	var total_width = (lane_count * lane_width) + ((lane_count - 1) * lane_spacing)
	var start_x = (get_viewport_rect().size.x - total_width) / 2.0
	
	for i in range(lane_count):
		var lane_x = start_x + (i * (lane_width + lane_spacing))
		var color = Color.DARK_CYAN if i % 2 == 0 else Color.DARK_BLUE
		
		# Draw lane background
		draw_rect(
			Rect2(lane_x, 0, lane_width, get_viewport_rect().size.y),
			color
		)
		
		# Draw lane border
		draw_line(
			Vector2(lane_x, 0),
			Vector2(lane_x, get_viewport_rect().size.y),
			Color.WHITE,
			2.0
		)

func _draw_hit_zone() -> void:
	"""Draw the hit detection zone."""
	var total_width = (lane_count * lane_width) + ((lane_count - 1) * lane_spacing)
	var start_x = (get_viewport_rect().size.x - total_width) / 2.0
	
	# Draw hit zone background
	draw_rect(
		Rect2(start_x, hit_zone_y - (hit_zone_height / 2.0), total_width, hit_zone_height),
		Color(1.0, 1.0, 1.0, 0.2)
	)
	
	# Draw hit zone line
	draw_line(
		Vector2(start_x, hit_zone_y),
		Vector2(start_x + total_width, hit_zone_y),
		Color.YELLOW,
		3.0
	)

func get_lane_position(lane_index: int) -> float:
	"""Get X position of a specific lane."""
	if lane_index >= 0 and lane_index < lane_positions.size():
		return lane_positions[lane_index]
	return 0.0

func get_lane_positions() -> Array:
	"""Get all lane positions."""
	return lane_positions.duplicate()
