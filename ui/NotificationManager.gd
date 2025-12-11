extends CanvasLayer

"""
NotificationManager displays in-game notifications with various styles and durations.
Supports queuing and stacking notifications.
"""

class Notification:
	var id: String
	var message: String
	var type: String  # "info", "success", "warning", "error"
	var duration: float
	var start_time: float
	var on_dismiss: Callable
	
	func _init(p_message: String, p_type: String, p_duration: float) -> void:
		id = "%d" % Time.get_ticks_msec()
		message = p_message
		type = p_type
		duration = p_duration
		start_time = Time.get_ticks_msec()
		on_dismiss = Callable()

var notifications: Array = []
var container: VBoxContainer
var max_notifications: int = 3

signal notification_shown(message: String, type: String)
signal notification_dismissed(notification_id: String)

func _ready() -> void:
	"""Initialize notification system."""
	container = VBoxContainer.new()
	container.anchor_left = Control.ANCHOR_END
	container.anchor_top = Control.ANCHOR_BEGIN
	container.anchor_right = Control.ANCHOR_END
	container.anchor_bottom = Control.ANCHOR_BEGIN
	container.offset_left = -400
	container.offset_right = -20
	container.offset_top = 20
	container.offset_bottom = 20
	container.add_theme_constant_override("separation", 10)
	
	add_child(container)

func _process(_delta: float) -> void:
	"""Update and remove expired notifications."""
	var current_time = Time.get_ticks_msec()
	var to_remove = []
	
	for notification in notifications:
		var elapsed = (current_time - notification.start_time) / 1000.0
		if elapsed >= notification.duration:
			to_remove.append(notification)
	
	for notification in to_remove:
		_dismiss_notification(notification.id)

func show_notification(message: String, type: String = "info", duration: float = 3.0) -> String:
	"""Show a notification."""
	if notifications.size() >= max_notifications:
		_remove_oldest()
	
	var notification = Notification.new(message, type, duration)
	notifications.append(notification)
	
	_create_notification_ui(notification)
	emit_signal("notification_shown", message, type)
	
	return notification.id

func show_success(message: String, duration: float = 3.0) -> String:
	"""Show a success notification."""
	return show_notification(message, "success", duration)

func show_error(message: String, duration: float = 4.0) -> String:
	"""Show an error notification."""
	return show_notification(message, "error", duration)

func show_warning(message: String, duration: float = 3.5) -> String:
	"""Show a warning notification."""
	return show_notification(message, "warning", duration)

func show_info(message: String, duration: float = 3.0) -> String:
	"""Show an info notification."""
	return show_notification(message, "info", duration)

func dismiss_notification(notification_id: String) -> void:
	"""Manually dismiss a notification."""
	_dismiss_notification(notification_id)

func _create_notification_ui(notification: Notification) -> void:
	"""Create the visual UI for a notification."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 60)
	panel.modulate.a = 0.0
	
	# Create background color based on type
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = _get_color_for_type(notification.type)
	stylebox.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", stylebox)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icon/type indicator
	var icon_label = Label.new()
	icon_label.text = _get_icon_for_type(notification.type)
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)
	
	# Message
	var message_label = Label.new()
	message_label.text = notification.message
	message_label.custom_minimum_size = Vector2(280, 0)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(message_label)
	
	container.add_child(panel)
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	# Store reference for later removal
	notification.on_dismiss = func(): _animate_out(panel)

func _dismiss_notification(notification_id: String) -> void:
	"""Remove and animate out a notification."""
	var index = -1
	for i in range(notifications.size()):
		if notifications[i].id == notification_id:
			index = i
			break
	
	if index == -1:
		return
	
	var notification = notifications[index]
	if notification.on_dismiss.is_valid():
		notification.on_dismiss.call()
	
	notifications.remove_at(index)
	emit_signal("notification_dismissed", notification_id)

func _animate_out(panel: Control) -> void:
	"""Animate notification out and remove."""
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	panel.queue_free()

func _remove_oldest() -> void:
	"""Remove the oldest notification."""
	if not notifications.is_empty():
		_dismiss_notification(notifications[0].id)

func _get_color_for_type(type: String) -> Color:
	"""Get background color for notification type."""
	match type:
		"success":
			return Color(0.0, 0.8, 0.2, 0.9)
		"error":
			return Color(0.8, 0.0, 0.0, 0.9)
		"warning":
			return Color(0.8, 0.6, 0.0, 0.9)
		_:  # info
			return Color(0.0, 0.5, 0.8, 0.9)

func _get_icon_for_type(type: String) -> String:
	"""Get icon for notification type."""
	match type:
		"success":
			return "✓"
		"error":
			return "✕"
		"warning":
			return "⚠"
		_:  # info
			return "ℹ"

func clear_all() -> void:
	"""Clear all notifications."""
	for notification in notifications.duplicate():
		_dismiss_notification(notification.id)

func set_max_notifications(count: int) -> void:
	"""Set maximum concurrent notifications."""
	max_notifications = max(1, count)
