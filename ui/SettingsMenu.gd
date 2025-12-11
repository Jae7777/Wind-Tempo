extends Control

"""
SettingsMenu provides UI for adjusting game settings and audio calibration.
"""

@onready var master_volume_slider = $VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/SFXVolumeSlider
@onready var latency_offset_slider = $VBoxContainer/LatencyOffsetSlider
@onready var effects_toggle = $VBoxContainer/EffectsToggle
@onready var particles_toggle = $VBoxContainer/ParticlesToggle
@onready var calibrate_button = $VBoxContainer/CalibrateButton
@onready var reset_button = $VBoxContainer/ResetButton
@onready var back_button = $VBoxContainer/BackButton
@onready var status_label = $VBoxContainer/StatusLabel

var game_settings: Node
var audio_sync_calibrator: Node

func _ready() -> void:
	game_settings = get_tree().root.get_node_or_null("Main/GameSettings")
	audio_sync_calibrator = get_tree().root.get_node_or_null("Main/AudioSyncCalibrator")
	
	_setup_sliders()
	_connect_signals()
	_load_settings()
	hide()

func _setup_sliders() -> void:
	"""Configure slider ranges and defaults."""
	master_volume_slider.min_value = -80
	master_volume_slider.max_value = 0
	master_volume_slider.step = 1
	
	music_volume_slider.min_value = -80
	music_volume_slider.max_value = 0
	music_volume_slider.step = 1
	
	sfx_volume_slider.min_value = -80
	sfx_volume_slider.max_value = 0
	sfx_volume_slider.step = 1
	
	latency_offset_slider.min_value = -100
	latency_offset_slider.max_value = 100
	latency_offset_slider.step = 5

func _connect_signals() -> void:
	"""Connect all UI signals."""
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	latency_offset_slider.value_changed.connect(_on_latency_offset_changed)
	effects_toggle.toggled.connect(_on_effects_toggled)
	particles_toggle.toggled.connect(_on_particles_toggled)
	calibrate_button.pressed.connect(_on_calibrate_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _load_settings() -> void:
	"""Load current settings into UI."""
	if not game_settings:
		return
	
	master_volume_slider.value = game_settings.get_setting("master_volume")
	music_volume_slider.value = game_settings.get_setting("music_volume")
	sfx_volume_slider.value = game_settings.get_setting("sfx_volume")
	latency_offset_slider.value = game_settings.get_setting("audio_latency_offset")
	effects_toggle.button_pressed = game_settings.get_setting("visual_effects_enabled")
	particles_toggle.button_pressed = game_settings.get_setting("combo_particles")

func _on_master_volume_changed(value: float) -> void:
	"""Handle master volume change."""
	if game_settings:
		game_settings.set_master_volume(value)
		status_label.text = "Master Volume: %.1f dB" % value

func _on_music_volume_changed(value: float) -> void:
	"""Handle music volume change."""
	if game_settings:
		game_settings.set_music_volume(value)
		status_label.text = "Music Volume: %.1f dB" % value

func _on_sfx_volume_changed(value: float) -> void:
	"""Handle SFX volume change."""
	if game_settings:
		game_settings.set_sfx_volume(value)
		status_label.text = "SFX Volume: %.1f dB" % value

func _on_latency_offset_changed(value: float) -> void:
	"""Handle latency offset change."""
	if game_settings:
		game_settings.set_latency_offset(value)
		status_label.text = "Latency Offset: %.0f ms" % value

func _on_effects_toggled(toggled_on: bool) -> void:
	"""Handle visual effects toggle."""
	if game_settings:
		game_settings.set_setting("visual_effects_enabled", toggled_on)
		status_label.text = "Visual Effects: %s" % ("ON" if toggled_on else "OFF")

func _on_particles_toggled(toggled_on: bool) -> void:
	"""Handle particle effects toggle."""
	if game_settings:
		game_settings.set_setting("combo_particles", toggled_on)
		status_label.text = "Combo Particles: %s" % ("ON" if toggled_on else "OFF")

func _on_calibrate_pressed() -> void:
	"""Start audio latency calibration."""
	if audio_sync_calibrator:
		audio_sync_calibrator.start_calibration()
		status_label.text = "Calibration started. Hit notes on beat..."

func _on_reset_pressed() -> void:
	"""Reset all settings to defaults."""
	if game_settings:
		game_settings.reset_to_defaults()
		_load_settings()
		status_label.text = "Settings reset to defaults"

func _on_back_pressed() -> void:
	"""Close settings menu."""
	hide()
