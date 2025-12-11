extends Node

"""
LocalizationManager handles multi-language support.
Loads and manages translation strings with fallback support.
"""

const LOCALIZATION_PATH = "user://localization/"

var current_language: String = "en"
var translations: Dictionary = {}
var default_language: String = "en"

signal language_changed(new_language: String)

func _ready() -> void:
	"""Initialize localization system."""
	_setup_default_translations()
	_load_custom_translations()

func _setup_default_translations() -> void:
	"""Setup default English translations."""
	translations["en"] = {
		# Menu
		"menu_title": "Wind Tempo",
		"menu_play": "Play",
		"menu_settings": "Settings",
		"menu_quit": "Quit",
		
		# Game
		"game_paused": "Paused",
		"game_resume": "Resume",
		"game_restart": "Restart",
		"game_quit_to_menu": "Quit to Menu",
		
		# Scoring
		"judgment_perfect": "PERFECT",
		"judgment_great": "GREAT",
		"judgment_good": "GOOD",
		"judgment_miss": "MISS",
		"score": "Score",
		"combo": "Combo",
		"accuracy": "Accuracy",
		"rank": "Rank",
		
		# Results
		"results_new_record": "New Record!",
		"results_congratulations": "Congratulations!",
		"results_try_again": "Try Again",
		"results_back_to_menu": "Back to Menu",
		
		# Settings
		"settings_title": "Settings",
		"settings_volume": "Volume",
		"settings_latency_offset": "Latency Offset",
		"settings_visual_effects": "Visual Effects",
		"settings_audio": "Audio",
		"settings_gameplay": "Gameplay",
		"settings_reset": "Reset to Defaults",
		"settings_close": "Close",
		
		# Difficulty
		"difficulty_easy": "Easy",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Hard",
		"difficulty_extreme": "Extreme",
		
		# UI
		"ui_select": "Select",
		"ui_back": "Back",
		"ui_confirm": "Confirm",
		"ui_cancel": "Cancel",
		"ui_loading": "Loading...",
		"ui_error": "Error",
		
		# Notifications
		"notif_game_started": "Game Started",
		"notif_song_loaded": "Song Loaded",
		"notif_settings_saved": "Settings Saved",
		"notif_new_high_score": "New High Score!",
		
		# Practice Mode
		"practice_title": "Practice Mode",
		"practice_speed": "Speed",
		"practice_loop": "Loop Section",
		"practice_show_hitbox": "Show Hitbox",
		"practice_auto_play": "Auto Play",
		
		# Tutorial
		"tutorial_title": "Tutorial",
		"tutorial_controls": "Controls",
		"tutorial_scoring": "Scoring",
		"tutorial_tips": "Tips",
		
		# Achievements
		"achievement_title": "Achievements",
		"achievement_unlocked": "Achievement Unlocked!",
		"achievement_view_all": "View All",
		
		# Leaderboard
		"leaderboard_title": "Leaderboard",
		"leaderboard_rank": "Rank",
		"leaderboard_player": "Player",
		"leaderboard_score": "Score",
		"leaderboard_accuracy": "Accuracy"
	}
	
	# Spanish translations
	translations["es"] = {
		"menu_title": "Wind Tempo",
		"menu_play": "Jugar",
		"menu_settings": "Configuración",
		"menu_quit": "Salir",
		
		"game_paused": "En pausa",
		"game_resume": "Reanudar",
		"game_restart": "Reiniciar",
		"game_quit_to_menu": "Volver al menú",
		
		"judgment_perfect": "PERFECTO",
		"judgment_great": "EXCELENTE",
		"judgment_good": "BIEN",
		"judgment_miss": "FALLO",
		"score": "Puntuación",
		"combo": "Combo",
		"accuracy": "Precisión",
		"rank": "Rango",
		
		"results_new_record": "¡Nuevo récord!",
		"results_congratulations": "¡Felicitaciones!",
		"results_try_again": "Intentar de nuevo",
		"results_back_to_menu": "Volver al menú",
		
		"settings_title": "Configuración",
		"settings_volume": "Volumen",
		"settings_latency_offset": "Compensación de latencia",
		"settings_reset": "Restaurar valores predeterminados",
		"settings_close": "Cerrar",
		
		"difficulty_easy": "Fácil",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Difícil",
		"difficulty_extreme": "Extremo"
	}
	
	# Japanese translations
	translations["ja"] = {
		"menu_title": "Wind Tempo",
		"menu_play": "プレイ",
		"menu_settings": "設定",
		"menu_quit": "終了",
		
		"game_paused": "一時停止中",
		"game_resume": "再開",
		"game_restart": "リスタート",
		
		"judgment_perfect": "パーフェクト",
		"judgment_great": "グレート",
		"judgment_good": "グッド",
		"judgment_miss": "ミス",
		"score": "スコア",
		"combo": "コンボ",
		"accuracy": "精度",
		"rank": "ランク",
		
		"difficulty_easy": "イージー",
		"difficulty_normal": "ノーマル",
		"difficulty_hard": "ハード",
		"difficulty_extreme": "エクストリーム"
	}

func set_language(language_code: String) -> bool:
	"""Set the active language."""
	if language_code not in translations:
		push_warning("Language not supported: %s" % language_code)
		return false
	
	current_language = language_code
	emit_signal("language_changed", language_code)
	return true

func get_language() -> String:
	"""Get the current language code."""
	return current_language

func get_supported_languages() -> Array:
	"""Get list of supported language codes."""
	return translations.keys()

func translate(key: String, default: String = "") -> String:
	"""Get translated string for key."""
	if current_language in translations:
		var lang_dict = translations[current_language]
		if key in lang_dict:
			return lang_dict[key]
	
	# Fallback to English
	if default_language in translations and key in translations[default_language]:
		return translations[default_language][key]
	
	# Ultimate fallback
	return default if default else key

func translate_with_params(key: String, params: Dictionary) -> String:
	"""Get translated string with parameter substitution."""
	var text = translate(key)
	
	for param_key in params:
		text = text.replace("{%s}" % param_key, str(params[param_key]))
	
	return text

func add_language(language_code: String, translations_dict: Dictionary) -> void:
	"""Add a new language."""
	translations[language_code] = translations_dict

func update_translation(language_code: String, key: String, value: String) -> void:
	"""Update a single translation string."""
	if language_code not in translations:
		translations[language_code] = {}
	
	translations[language_code][key] = value

func _load_custom_translations() -> void:
	"""Load custom translation files from user data."""
	if not DirAccess.dir_exists_absolute(LOCALIZATION_PATH):
		DirAccess.make_abs_absolute(LOCALIZATION_PATH)
		return
	
	var dir = DirAccess.open(LOCALIZATION_PATH)
	if not dir:
		return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	
	while filename != "":
		if filename.ends_with(".json"):
			var lang_code = filename.trim_suffix(".json")
			var filepath = LOCALIZATION_PATH + filename
			var file = FileAccess.open(filepath, FileAccess.READ)
			
			if file:
				var json_string = file.get_as_text()
				var json = JSON.new()
				
				if json.parse(json_string) == OK:
					translations[lang_code] = json.data
		
		filename = dir.get_next()

func export_language(language_code: String, file_path: String) -> bool:
	"""Export a language to JSON file."""
	if language_code not in translations:
		return false
	
	var json_string = JSON.stringify(translations[language_code])
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		return true
	
	return false

func get_language_info(language_code: String) -> Dictionary:
	"""Get information about a language."""
	return {
		"code": language_code,
		"string_count": translations[language_code].size() if language_code in translations else 0,
		"is_available": language_code in translations
	}

func reset_to_default_language() -> void:
	"""Reset to default language."""
	set_language(default_language)
