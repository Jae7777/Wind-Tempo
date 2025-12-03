# scripts/components/lane_manager.gd
# Manages lane positions and drawing for the note highway
class_name LaneManager
extends Node2D

signal lanes_updated(lane_positions: Array[float], lane_width: float)

@export var lane_count: int = 88
@export var lane_margin: float = 20.0
@export var show_lane_lines: bool = true
@export var lane_line_width: float = 1.0
@export var lane_line_color: Color = Color(1, 1, 1, 0.15)
@export var draw_edge_lines: bool = true

const MIDI_START_A0: int = 21

var lane_x: Array[float] = []
var lane_width: float = 0.0

func _ready() -> void:
	_compute_lane_positions()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_compute_lane_positions()

func _compute_lane_positions() -> void:
	lane_x.clear()
	var width: float = get_viewport_rect().size.x
	var usable: float = maxf(0.0, width - 2.0 * lane_margin)
	
	if lane_count <= 0 or usable <= 0.0:
		lane_x.append(width * 0.5)
		lane_width = usable
		lanes_updated.emit(lane_x, lane_width)
		queue_redraw()
		return

	lane_width = usable / float(lane_count)
	for i in range(lane_count):
		var center_x: float = lane_margin + (i + 0.5) * lane_width
		lane_x.append(center_x)

	lanes_updated.emit(lane_x, lane_width)
	queue_redraw()

func get_lane_x(lane: int) -> float:
	if lane >= 0 and lane < lane_x.size():
		return lane_x[lane]
	return 0.0

func get_lane_width() -> float:
	return lane_width

func get_lane_positions() -> Array[float]:
	return lane_x

func _draw() -> void:
	if not show_lane_lines:
		return

	var rect := get_viewport_rect()
	var w: float = rect.size.x
	var h: float = rect.size.y
	var usable: float = maxf(0.0, w - 2.0 * lane_margin)
	
	if lane_count <= 0 or usable <= 0.0:
		return

	var step_w: float = usable / float(lane_count)
	var start_x: float = lane_margin
	
	if draw_edge_lines:
		draw_line(Vector2(start_x, 0), Vector2(start_x, h), lane_line_color, lane_line_width, true)
	
	for i in range(1, lane_count):
		var x: float = start_x + float(i) * step_w
		var midi_note: int = MIDI_START_A0 + i
		# Brighter lines at octave boundaries (C notes)
		if midi_note % 12 == 0:
			draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.3), lane_line_width + 1, true)
		else:
			draw_line(Vector2(x, 0), Vector2(x, h), lane_line_color, lane_line_width, true)
	
	if draw_edge_lines:
		var right_x: float = start_x + float(lane_count) * step_w
		draw_line(Vector2(right_x, 0), Vector2(right_x, h), lane_line_color, lane_line_width, true)

