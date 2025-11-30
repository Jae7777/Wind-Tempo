extends Sprite2D

@export var fall_speed: float = 3

#Just a testing statement to ensure that it's running
func _ready() -> void:
	if has_node("Timer"):
		$Timer.start()            
		print(name, "Timer started wait_time=", $Timer.wait_time)

func _process(delta):
	position += Vector2(0, fall_speed)

#REMEMBER TO CHANGE:
#316 Y-level for White Keys
#266 Y-levle for Black Keys
	if position.y > 280.0 and not $Timer.is_stopped():
		print($Timer.wait_time - $Timer.time_left)
		$Timer.stop()
