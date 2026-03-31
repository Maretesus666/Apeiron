extends Area2D

@export var spawn_distance: float = 8000.0  # Distancia desde el spawn del jugador

@onready var sprite := $Sprite2D
@onready var particles := $CPUParticles2D
@onready var label := $Label

var player: Node2D = null
var pulsing: bool = true
var pulse_time: float = 0.0

signal objective_reached

func _ready() -> void:
	add_to_group("objective")
	_setup_visuals()
	_position_objective()
	body_entered.connect(_on_body_entered)
	
	player = get_tree().get_first_node_in_group("player")
	
	# Actualizar label con info de misión
	if UpgradeManager.is_mission_active:
		var reward: int = int(UpgradeManager.bet_points * UpgradeManager.bet_multiplier)
		label.text = "OBJETIVO\n%d pts" % reward

func _setup_visuals() -> void:
	# Sprite circular brillante
	sprite.modulate = Color(0.3, 0.8, 1.0, 0.9)
	sprite.scale = Vector2(2.0, 2.0)
	
	# Partículas
	particles.emitting = true
	particles.amount = 35
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 80.0
	particles.direction = Vector2.ZERO
	particles.spread = 180
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 80
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.color = Color(0.4, 0.9, 1.0, 0.8)
	
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.5, 1.0, 1.0, 1.0),
		Color(0.3, 0.7, 1.0, 0.6),
		Color(0.1, 0.3, 0.5, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	particles.color_ramp = gradient
	
	# Label flotante
	label.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-100, -150)

func _position_objective() -> void:
	# Posicionar lejos del spawn del jugador
	var angle: float = randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_distance
	global_position = offset

func _process(delta: float) -> void:
	# Efecto de pulso
	if pulsing:
		pulse_time += delta * 2.0
		var scale_factor: float = 1.0 + sin(pulse_time) * 0.15
		sprite.scale = Vector2.ONE * 2.0 * scale_factor
		sprite.modulate.a = 0.7 + sin(pulse_time * 1.5) * 0.2
	
	# Rotar partículas
	particles.rotation += delta * 0.3
	
	# Actualizar distancia en label
	if player and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		if dist > 500:
			label.text = "OBJETIVO\n%.0fm" % (dist / 100.0)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_complete_objective()

func _complete_objective() -> void:
	pulsing = false
	objective_reached.emit()
	
	# Efecto de explosión de victoria
	_create_victory_particles()
	
	# Notificar al UpgradeManager
	UpgradeManager.complete_mission()
	
	# Mostrar mensaje de victoria
	_show_victory_message()
	
	# Volver al hub después de un delay
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")

func _create_victory_particles() -> void:
	var victory_particles := CPUParticles2D.new()
	victory_particles.global_position = global_position
	victory_particles.emitting = true
	victory_particles.one_shot = true
	victory_particles.amount = 80
	victory_particles.lifetime = 1.2
	victory_particles.explosiveness = 1.0
	victory_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	victory_particles.emission_sphere_radius = 20.0
	victory_particles.direction = Vector2.ZERO
	victory_particles.spread = 180
	victory_particles.gravity = Vector2.ZERO
	victory_particles.initial_velocity_min = 200
	victory_particles.initial_velocity_max = 450
	victory_particles.scale_amount_min = 4.0
	victory_particles.scale_amount_max = 9.0
	victory_particles.color = Color(0.3, 1.0, 0.5, 1.0)
	
	get_tree().root.add_child(victory_particles)
	
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(victory_particles):
		victory_particles.queue_free()

func _show_victory_message() -> void:
	var msg := Label.new()
	msg.text = "¡MISIÓN COMPLETADA!\n+%d PUNTOS" % int(UpgradeManager.bet_points * UpgradeManager.bet_multiplier)
	msg.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	msg.add_theme_font_size_override("font_size", 56)
	msg.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	msg.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	msg.add_theme_constant_override("outline_size", 5)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var vp: Vector2 = get_viewport().get_visible_rect().size
	msg.position = Vector2(vp.x / 2 - 300, vp.y / 2 - 50)
	msg.size = Vector2(600, 100)
	
	# Agregar a un CanvasLayer para que siempre esté visible
	var layer := CanvasLayer.new()
	layer.add_child(msg)
	get_tree().root.add_child(layer)
	
	# Animación de entrada
	msg.modulate.a = 0.0
	var tw := msg.create_tween()
	tw.tween_property(msg, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.5)
	tw.tween_property(msg, "modulate:a", 0.0, 0.4)
	tw.tween_callback(layer.queue_free)
