extends Node

"""
ThemeManager manages visual themes and color schemes.
Supports multiple themes with persistent selection.
"""

const THEMES_PATH = "user://themes.cfg"

class Theme:
	var name: String
	var colors: Dictionary
	var is_active: bool = false
	
	func _init(p_name: String, p_colors: Dictionary) -> void:
		name = p_name
		colors = p_colors.duplicate()

@onready var config = ConfigFile.new()

var themes: Dictionary = {}
var active_theme_name: String = "Default"

signal theme_changed(theme_name: String)
signal theme_created(theme_name: String)
signal theme_deleted(theme_name: String)

func _ready() -> void:
	"""Initialize theme system."""
	_setup_default_themes()
	_load_active_theme()

func _setup_default_themes() -> void:
	"""Create default color themes."""
	var default_colors = {
		"lane_0": Color.CYAN,
		"lane_1": Color.MAGENTA,
		"lane_2": Color.YELLOW,
		"lane_3": Color.LIGHT_GREEN,
		"perfect": Color.GOLD,
		"great": Color.CYAN,
		"good": Color.LIGHT_BLUE,
		"miss": Color.RED,
		"background": Color(0.1, 0.1, 0.1, 1.0),
		"ui_primary": Color(0.2, 0.2, 0.3, 1.0),
		"ui_secondary": Color(0.3, 0.3, 0.4, 1.0),
		"text_primary": Color.WHITE,
		"text_secondary": Color(0.8, 0.8, 0.8, 1.0),
		"accent": Color.LIGHT_BLUE,
		"highlight": Color.YELLOW
	}
	
	themes["Default"] = Theme.new("Default", default_colors)
	
	# Dark theme
	var dark_colors = default_colors.duplicate()
	dark_colors["background"] = Color(0.05, 0.05, 0.05, 1.0)
	dark_colors["ui_primary"] = Color(0.1, 0.1, 0.12, 1.0)
	dark_colors["ui_secondary"] = Color(0.15, 0.15, 0.18, 1.0)
	themes["Dark"] = Theme.new("Dark", dark_colors)
	
	# Vibrant theme
	var vibrant_colors = default_colors.duplicate()
	vibrant_colors["lane_0"] = Color.BLUE
	vibrant_colors["lane_1"] = Color.MAGENTA
	vibrant_colors["lane_2"] = Color(1.0, 0.5, 0.0, 1.0)  # Orange
	vibrant_colors["lane_3"] = Color.LIME_GREEN
	vibrant_colors["accent"] = Color.MAGENTA
	themes["Vibrant"] = Theme.new("Vibrant", vibrant_colors)
	
	# Cool theme
	var cool_colors = default_colors.duplicate()
	cool_colors["lane_0"] = Color(0.0, 0.8, 1.0, 1.0)  # Bright cyan
	cool_colors["lane_1"] = Color(0.2, 1.0, 1.0, 1.0)  # Light cyan
	cool_colors["lane_2"] = Color(0.0, 1.0, 0.6, 1.0)  # Turquoise
	cool_colors["lane_3"] = Color(0.0, 0.7, 1.0, 1.0)  # Sky blue
	cool_colors["accent"] = Color(0.0, 1.0, 0.7, 1.0)
	themes["Cool"] = Theme.new("Cool", cool_colors)
	
	# Warm theme
	var warm_colors = default_colors.duplicate()
	warm_colors["lane_0"] = Color(1.0, 0.6, 0.0, 1.0)  # Orange
	warm_colors["lane_1"] = Color(1.0, 0.4, 0.0, 1.0)  # Deep orange
	warm_colors["lane_2"] = Color(1.0, 0.8, 0.0, 1.0)  # Gold
	warm_colors["lane_3"] = Color(1.0, 0.3, 0.0, 1.0)  # Red-orange
	warm_colors["accent"] = Color(1.0, 0.5, 0.0, 1.0)
	themes["Warm"] = Theme.new("Warm", warm_colors)

func set_active_theme(theme_name: String) -> void:
	"""Switch to a different theme."""
	if theme_name not in themes:
		push_error("Theme not found: %s" % theme_name)
		return
	
	active_theme_name = theme_name
	_save_active_theme()
	emit_signal("theme_changed", theme_name)

func get_active_theme() -> Theme:
	"""Get the currently active theme."""
	return themes.get(active_theme_name, themes["Default"])

func get_color(color_key: String) -> Color:
	"""Get a color from the active theme."""
	var theme = get_active_theme()
	return theme.colors.get(color_key, Color.WHITE)

func get_theme(theme_name: String) -> Theme:
	"""Get a specific theme."""
	return themes.get(theme_name)

func get_all_theme_names() -> Array:
	"""Get list of all available theme names."""
	return themes.keys()

func get_all_themes() -> Dictionary:
	"""Get all themes."""
	return themes.duplicate()

func create_custom_theme(name: String, base_theme_name: String) -> bool:
	"""Create a new custom theme based on an existing one."""
	if name in themes:
		push_warning("Theme already exists: %s" % name)
		return false
	
	if base_theme_name not in themes:
		push_error("Base theme not found: %s" % base_theme_name)
		return false
	
	var base_theme = themes[base_theme_name]
	var custom_colors = base_theme.colors.duplicate()
	themes[name] = Theme.new(name, custom_colors)
	
	emit_signal("theme_created", name)
	return true

func set_theme_color(theme_name: String, color_key: String, color: Color) -> void:
	"""Modify a color in a theme."""
	if theme_name not in themes:
		push_error("Theme not found: %s" % theme_name)
		return
	
	themes[theme_name].colors[color_key] = color

func delete_theme(theme_name: String) -> void:
	"""Delete a custom theme."""
	if theme_name == "Default" or theme_name not in themes:
		push_error("Cannot delete theme: %s" % theme_name)
		return
	
	themes.erase(theme_name)
	
	if active_theme_name == theme_name:
		set_active_theme("Default")
	
	emit_signal("theme_deleted", theme_name)

func _save_active_theme() -> void:
	"""Save active theme to config."""
	config.clear()
	config.set_value("theme", "active", active_theme_name)
	config.save(THEMES_PATH)

func _load_active_theme() -> void:
	"""Load active theme from config."""
	var error = config.load(THEMES_PATH)
	
	if error == OK and config.has_section_key("theme", "active"):
		var saved_theme = config.get_value("theme", "active")
		if saved_theme in themes:
			active_theme_name = saved_theme
			return
	
	active_theme_name = "Default"

func get_lane_color(lane: int) -> Color:
	"""Get the color for a specific lane."""
	var color_key = "lane_%d" % lane
	return get_color(color_key)

func get_judgment_color(judgment: String) -> Color:
	"""Get the color for a judgment type."""
	var color_key = judgment.to_lower()
	return get_color(color_key)

func get_theme_preview(theme_name: String) -> Dictionary:
	"""Get a preview of theme colors."""
	if theme_name not in themes:
		return {}
	
	var theme = themes[theme_name]
	return {
		"name": theme.name,
		"lane_colors": [
			theme.colors.get("lane_0", Color.WHITE),
			theme.colors.get("lane_1", Color.WHITE),
			theme.colors.get("lane_2", Color.WHITE),
			theme.colors.get("lane_3", Color.WHITE)
		],
		"judgment_colors": {
			"perfect": theme.colors.get("perfect", Color.WHITE),
			"great": theme.colors.get("great", Color.WHITE),
			"good": theme.colors.get("good", Color.WHITE),
			"miss": theme.colors.get("miss", Color.WHITE)
		},
		"accent": theme.colors.get("accent", Color.WHITE)
	}
