extends Sprite2D

#Falling key speed
@export var fall_speed: float = 9

#var init_y_pos: float = -350

#func _init():
#		set_process(false)

func _process(delta):
		global_position += Vector2(0, fall_speed)
		
		if global_position.y > 316.0 and not $Timer.is_stopped():
				print($Timer.time_left)
				$Timer.stop()

#func SetUp(target_x: float):
#		global_position = Vector2(target_x, init_y_pos)
#		set_process(true)
		
