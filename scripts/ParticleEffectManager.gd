extends Node2D

"""
ParticleEffectManager handles particle emission for visual feedback.
Creates combo popups, hit explosions, and scoring effects.
"""

class ParticleEffect:
	var position: Vector2
	var particle_type: String
	var lifetime: float
	var color: Color
	
	func _init(pos: Vector2, ptype: String, life: float, col: Color) -> void:
		position = pos
		particle_type = ptype
		lifetime = life
		color = col

var active_effects: Array = []
var max_particles: int = 500

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	"""Update and remove expired particles."""
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		effect.lifetime -= delta
		if effect.lifetime <= 0:
			active_effects.remove_at(i)

func spawn_combo_burst(position: Vector2, combo: int) -> void:
	"""Spawn particles for combo milestone."""
	if not get_tree().root.get_node_or_null("Main/GameSettings").get_setting("combo_particles"):
		return
	
	var particle_count = mini(combo / 10, 20)  # More particles for higher combos
	for i in range(particle_count):
		var angle = TAU * i / particle_count
		var speed = 200.0 + (combo * 2)
		var velocity = Vector2(cos(angle), sin(angle)) * speed
		
		var color = Color.GOLD if combo % 2 == 0 else Color.ORANGE
		_create_particle(position, velocity, color, 0.5)

func spawn_perfect_hit(position: Vector2) -> void:
	"""Spawn particles for perfect hit."""
	var particle = ParticleEffect.new(position, "perfect", 0.5, Color.GOLD)
	active_effects.append(particle)
	queue_redraw()

func spawn_score_popup(position: Vector2, points: int) -> void:
	"""Spawn floating text showing score."""
	var label = Label.new()
	label.text = "+%d" % points
	label.global_position = position
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:y", position.y - 100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.queue_free()

func spawn_miss_effect(position: Vector2) -> void:
	"""Spawn visual effect for missed note."""
	var particle = ParticleEffect.new(position, "miss", 0.3, Color.RED)
	active_effects.append(particle)
	queue_redraw()

func _create_particle(position: Vector2, velocity: Vector2, color: Color, lifetime: float) -> void:
	"""Create a single particle."""
	if active_effects.size() >= max_particles:
		return
	
	var particle = ParticleEffect.new(position, "generic", lifetime, color)
	active_effects.append(particle)

func _draw() -> void:
	"""Draw particles."""
	for effect in active_effects:
		var alpha = clamp(effect.lifetime, 0.0, 1.0)
		var particle_color = effect.color
		particle_color.a = alpha
		
		draw_circle(effect.position, 3.0, particle_color)
