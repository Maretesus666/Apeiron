extends CharacterBody2D

@export var speed: float = 300.0
@export var max_health: int = 5
@export var shoot_shake_amount: float = 2.0
@export var shoot_shake_duration: float = 0.1
@export var damage_shake_amount: float = 10.0
@export var damage_shake_duration: float = 0.3

var bullet = preload("res://scenes/bala.tscn")
var current_health: int
var is_shaking = false

@onready var puntoDisparo = $PuntoDisparo
@onready var sprite = $Sprite2D
@onready var thruster_particles = $ThrusterParticles

signal health_changed(new_health, max_health)
signal player_died

func _ready():
	current_health = max_health
	setup_thruster_particles()
	health_changed.emit(current_health, max_health)

func _physics_process(delta):
	_handle_movement(delta)
	_handle_rotation()
	_update_thruster_particles()

	if Input.is_action_just_pressed("shoot"):
		_shoot()

func _handle_movement(delta):
	var dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

	if dir.length() > 0:
		dir = dir.normalized()
	
	velocity = dir * speed
	move_and_slide()

func _handle_rotation():
	look_at(get_global_mouse_position())

func _shoot():
	var newBullet = bullet.instantiate()
	newBullet.rotation = rotation
	newBullet.global_position = puntoDisparo.global_position
	get_parent().add_child(newBullet)
	
	# Efecto de temblor al disparar
	apply_shake(shoot_shake_amount, shoot_shake_duration)

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	# Efectos visuales de daño
	spawn_damage_particles()
	flash_damage()
	apply_shake(damage_shake_amount, damage_shake_duration)
	
	if current_health <= 0:
		die()

func die():
	spawn_death_particles()
	player_died.emit()
	queue_free()

func apply_shake(amount: float, duration: float):
	if is_shaking:
		return
	
	is_shaking = true
	var original_pos = sprite.position
	var timer = 0.0
	
	while timer < duration:
		sprite.position = original_pos + Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)
		timer += get_process_delta_time()
		await get_tree().process_frame
	
	sprite.position = original_pos
	is_shaking = false

func flash_damage():
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

func spawn_damage_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 15
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 120
	particles.initial_velocity_max = 250
	particles.scale_amount_min = 3
	particles.scale_amount_max = 5
	particles.color = Color(1, 0.2, 0.2)
	get_tree().root.add_child(particles)
	
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

func spawn_death_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 40
	particles.lifetime = 1.2
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 200
	particles.initial_velocity_max = 400
	particles.scale_amount_min = 4
	particles.scale_amount_max = 8
	particles.color = Color(1, 0.4, 0)
	get_tree().root.add_child(particles)

func setup_thruster_particles():
	if not thruster_particles:
		thruster_particles = CPUParticles2D.new()
		add_child(thruster_particles)
	
	thruster_particles.emitting = false
	thruster_particles.amount = 20
	thruster_particles.lifetime = 0.3
	thruster_particles.local_coords = false
	thruster_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	thruster_particles.direction = Vector2(-1, 0)
	thruster_particles.spread = 15
	thruster_particles.gravity = Vector2.ZERO
	thruster_particles.initial_velocity_min = 100
	thruster_particles.initial_velocity_max = 150
	thruster_particles.scale_amount_min = 1.5
	thruster_particles.scale_amount_max = 3
	thruster_particles.color = Color(1, 0.6, 0.2)
	
	# Posicionar las partículas detrás de la nave
	thruster_particles.position = Vector2(-30, 0)

func _update_thruster_particles():
	if velocity.length() > 10:
		if not thruster_particles.emitting:
			thruster_particles.emitting = true
		
		# Ajustar dirección de las partículas según el movimiento
		var particle_direction = -velocity.normalized()
		thruster_particles.direction = particle_direction
	else:
		thruster_particles.emitting = false
