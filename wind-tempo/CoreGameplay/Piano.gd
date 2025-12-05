extends Node

signal key_pressed(lane: int)
signal key_released(lane: int)

@export var lane_actions: Array = ["lane_0", "lane_1", "lane_2", "lane_3"]

func _process(_delta: float) -> void:
	# Check InputMap actions each frame; configure actions in Project Settings -> Input Map
	for i in range(lane_actions.size()):
		if Input.is_action_just_pressed(lane_actions[i]):
			emit_signal("key_pressed", i)
		if Input.is_action_just_released(lane_actions[i]):
			emit_signal("key_released", i)
