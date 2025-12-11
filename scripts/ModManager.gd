extends Node

"""
ModManager handles loading and managing game modifications.
Supports custom charts, themes, and gameplay modifiers.
"""

const MODS_PATH = "user://mods/"

class Mod:
	var id: String
	var name: String
	var version: String
	var author: String
	var description: String
	var type: String  # "chart", "theme", "modifier"
	var enabled: bool = false
	var path: String
	
	func _init(p_id: String, p_type: String) -> void:
		id = p_id
		type = p_type
		name = ""
		version = "1.0"
		author = ""
		description = ""
		enabled = false
		path = ""

var installed_mods: Dictionary = {}
var enabled_mods: Array = []
var mod_load_order: Array = []

signal mod_loaded(mod_id: String)
signal mod_unloaded(mod_id: String)
signal mod_enabled(mod_id: String)
signal mod_disabled(mod_id: String)
signal mods_refreshed

func _ready() -> void:
	"""Initialize mod manager."""
	_ensure_mods_directory()
	_discover_mods()

func _ensure_mods_directory() -> void:
	"""Create mods directory if it doesn't exist."""
	if not DirAccess.dir_exists_absolute(MODS_PATH):
		DirAccess.make_abs_absolute(MODS_PATH)

func _discover_mods() -> void:
	"""Discover all available mods."""
	var dir = DirAccess.open(MODS_PATH)
	if not dir:
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if not folder_name.starts_with("."):
			_load_mod_manifest(MODS_PATH + folder_name)
		
		folder_name = dir.get_next()

func _load_mod_manifest(mod_path: String) -> void:
	"""Load mod manifest from directory."""
	var manifest_path = mod_path + "/manifest.json"
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	
	if not file:
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_string) != OK:
		return
	
	var manifest = json.data
	if not manifest or "id" not in manifest or "type" not in manifest:
		return
	
	var mod = Mod.new(manifest["id"], manifest["type"])
	mod.name = manifest.get("name", "Unknown")
	mod.version = manifest.get("version", "1.0")
	mod.author = manifest.get("author", "Unknown")
	mod.description = manifest.get("description", "")
	mod.path = mod_path
	
	installed_mods[mod.id] = mod
	emit_signal("mod_loaded", mod.id)

func enable_mod(mod_id: String) -> bool:
	"""Enable a mod."""
	if mod_id not in installed_mods:
		return false
	
	var mod = installed_mods[mod_id]
	if mod.enabled:
		return true
	
	mod.enabled = true
	if mod_id not in enabled_mods:
		enabled_mods.append(mod_id)
	
	_apply_mod(mod)
	emit_signal("mod_enabled", mod_id)
	return true

func disable_mod(mod_id: String) -> bool:
	"""Disable a mod."""
	if mod_id not in installed_mods:
		return false
	
	var mod = installed_mods[mod_id]
	if not mod.enabled:
		return true
	
	mod.enabled = false
	enabled_mods.erase(mod_id)
	
	_remove_mod(mod)
	emit_signal("mod_disabled", mod_id)
	return true

func _apply_mod(mod: Mod) -> void:
	"""Apply a mod's modifications."""
	match mod.type:
		"chart":
			_load_chart_mod(mod)
		"theme":
			_load_theme_mod(mod)
		"modifier":
			_load_modifier_mod(mod)

func _remove_mod(mod: Mod) -> void:
	"""Remove a mod's modifications."""
	# Implementation would depend on mod type
	pass

func _load_chart_mod(mod: Mod) -> void:
	"""Load a chart mod."""
	var charts_path = mod.path + "/charts/"
	if DirAccess.dir_exists_absolute(charts_path):
		# Charts would be loaded into the chart library
		pass

func _load_theme_mod(mod: Mod) -> void:
	"""Load a theme mod."""
	var theme_path = mod.path + "/theme.json"
	var file = FileAccess.open(theme_path, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			# Theme would be registered in ThemeManager
			pass

func _load_modifier_mod(mod: Mod) -> void:
	"""Load a gameplay modifier mod."""
	var modifier_path = mod.path + "/modifier.json"
	var file = FileAccess.open(modifier_path, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			# Modifier would be applied to gameplay
			pass

func get_mod(mod_id: String) -> Mod:
	"""Get a mod by ID."""
	return installed_mods.get(mod_id)

func get_all_mods() -> Dictionary:
	"""Get all installed mods."""
	return installed_mods.duplicate()

func get_enabled_mods() -> Array:
	"""Get list of enabled mod IDs."""
	return enabled_mods.duplicate()

func get_mods_by_type(mod_type: String) -> Array:
	"""Get all mods of a specific type."""
	var mods = []
	for mod_id in installed_mods:
		if installed_mods[mod_id].type == mod_type:
			mods.append(installed_mods[mod_id])
	return mods

func install_mod(zip_path: String) -> bool:
	"""Install a mod from a ZIP file."""
	# This would require unzipping functionality
	# For now, it's a placeholder
	return false

func uninstall_mod(mod_id: String) -> bool:
	"""Uninstall a mod."""
	if mod_id not in installed_mods:
		return false
	
	# Disable first if enabled
	if installed_mods[mod_id].enabled:
		disable_mod(mod_id)
	
	var mod = installed_mods[mod_id]
	# Delete mod directory
	# var dir = DirAccess.open(mod.path.get_base_dir())
	# dir.remove(mod.path)
	
	installed_mods.erase(mod_id)
	emit_signal("mod_unloaded", mod_id)
	return true

func refresh_mods() -> void:
	"""Refresh mod list by rediscovering mods."""
	installed_mods.clear()
	enabled_mods.clear()
	_discover_mods()
	emit_signal("mods_refreshed")

func get_mod_info(mod_id: String) -> Dictionary:
	"""Get detailed information about a mod."""
	if mod_id not in installed_mods:
		return {}
	
	var mod = installed_mods[mod_id]
	return {
		"id": mod.id,
		"name": mod.name,
		"version": mod.version,
		"author": mod.author,
		"description": mod.description,
		"type": mod.type,
		"enabled": mod.enabled,
		"path": mod.path
	}

func validate_mod(mod_path: String) -> Dictionary:
	"""Validate a mod directory structure."""
	var issues = []
	
	var manifest_path = mod_path + "/manifest.json"
	if not FileAccess.file_exists(manifest_path):
		issues.append("Missing manifest.json")
	
	# Check required manifest fields
	if issues.is_empty():
		var file = FileAccess.open(manifest_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var manifest = json.data
			if not ("id" in manifest):
				issues.append("Missing 'id' in manifest")
			if not ("type" in manifest):
				issues.append("Missing 'type' in manifest")
	
	return {
		"valid": issues.is_empty(),
		"issues": issues
	}

func create_mod_package(mod_id: String, output_path: String) -> bool:
	"""Create a distributable mod package."""
	if mod_id not in installed_mods:
		return false
	
	var mod = installed_mods[mod_id]
	# This would zip the mod directory
	# For now, it's a placeholder
	return false

func get_mod_statistics() -> Dictionary:
	"""Get statistics about installed mods."""
	var type_counts = {}
	
	for mod_id in installed_mods:
		var mod = installed_mods[mod_id]
		if mod.type not in type_counts:
			type_counts[mod.type] = 0
		type_counts[mod.type] += 1
	
	return {
		"total_mods": installed_mods.size(),
		"enabled_mods": enabled_mods.size(),
		"type_distribution": type_counts
	}
