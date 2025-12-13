# LaneVisualizer.gd
extends ColorRect # Assuming your visual key is a ColorRect

const FLASH_COLOR = Color.WHITE
const NORMAL_COLOR = Color.GRAY
const FLASH_DURATION = 0.1

func flash(is_hit_successful: bool):
	# Set the color based on success/miss
	if is_hit_successful:
		modulate = FLASH_COLOR
	else:
		# Flash red if the key was pressed but missed a note
		modulate = Color.RED 

	# Use a Tween to smoothly fade the color back
	var tween = create_tween()
	tween.tween_property(self, "modulate", NORMAL_COLOR, FLASH_DURATION)
